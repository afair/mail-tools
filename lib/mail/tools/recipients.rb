require 'json'

module Mail
  module Tools
    # Recipients is a container of Email Addresses and Mail-Merge Data.
    #
    # Usage: Accepts a mixed set of recipients formats. Same for add().
    #
    #    recipients = Mail::Tools::Recipients.new(
    #        'pat@example.com', 'info@example.com', # List of Addresses
    #        ['pat@example.com', 'info@example.com'], # Array of Addresses
    #        ['pat@example.com', {name:"Pat"}], # Recipient Tuple (Address/Data)
    #        'pat@example.com {"name":"Pat"}\ninfo@example.com\n', # Text lines
    #        {'pat@example.com'=>{name:"Pat"}}, # Hash keyed by email address
    #        '{"pat@example.com":{"name":"Pat"}}', # Json string of Hash by email address
    #        File.open("recipients.txt"), # File object
    #        enumerator        # Something that responds to each() returning any above
    #      )
    #    recipients.add(File.open("recipients2.txt"))
    #    recipients.count           #=> 57
    #
    # A Recipient is defined as a tuple of: [email_address, {name:x, field:value,...}]
    # The container is defined as: [recipient, recipients]
    # Email Address can be in "user@domain.com" or MD5(email) format.
    #
    # After 1000, the spill threshhold, the recipients are written to a
    # temporary file with the format: "email_address<TAB><JSON_STRING>\n"
    #
    # Recipients can be added to the contain in any of the following forms:
    #   * [email_address, {field:value}]
    #   * "email_address<SPACE><DATA_STRING>\n..." (One or more)
    #   * "email_address<SPACE>Name\n..." (One or more)
    #   * "email_address<TAB>Name<TAB><DATA_STRING><CR>..." (One or more)
    #
    # <DATA_STRING> Can be:
    #   * JSON String of Hash
    #   * Simple Data String: "field=value;field=value;..."
    #
    class Recipients
      include Enumerable
      SPILL_FILE_AFTER = 1000
      attr_reader :recipients, :count

      def self.coerce(list=nil)
        list.is_a?(Recipients) ? list : Recipients.new(list || [])
      end

      def initialize(*recipients)
        self.recipients = recipients
      end

      def size; @count; end

      def each
        if @recipients.is_a?(Array)
          @recipients.each { |r| yield r }
        else
          outfile.rewind
          outfile.each_line do |line|
            yield parse_recipient(line)
          end
        end
      end

      def to_a
        self.map {|i| i}
      end
      alias :to_array :to_a

      def save(filename, header=nil, mode='w')
        File.open(filename, mode) { |f| self.write(f,header) }
      end

      def write(filehandle, header=nil)
        filehandle.puts header if header
        each { |a| filehandle.puts(a[0] + "\t" + a[1].to_json) }
      end

      def to_s
        self.collect { |a| f.puts(a[0] + "\t" + a[1].to_json) }.join("\n")
      end

      def to_hash
        Hash[self.collect {|r| r}]
      end

      def to_json
        self.to_hash.to_json
      end

      def to_set
        self.collect { |a| a[0] }.to_set
      end

      # Returns [[md5, address],...], suitable for Hash[recips.to_md5]
      def to_md5
        self.collect { |a| [a[0] =~ /@/ ? Digest::MD5.hexdigest(a[0]) : a[0], a[0]] }
      end

      def to_md5_set
        self.collect { |a| a[0] =~ /@/ ? Digest::MD5.hexdigest(a[0]) : a[0] }.to_set
      end

      ##############################################################################
      # Recipients
      ##############################################################################

      def recipients=(recipients)
        @recipients = []
        @count      = 0
        self.add(recipients)
        @count
      end

      def add(*recipients)
        recipients.each do |r|
          if r.is_a?(Array) && !r.empty? 
            if r.second.is_a?(Hash)
              add_recipient(r)
            else
              r.each { |rr| self.add_recipient(normalize_recipient(rr)) }
            end
          elsif r.is_a?(Hash) # {address:{data},...}
            r.each { |e, d| self.add_recipient([e, d]) }
          elsif r.is_a?(String)
            if r =~ /\A\{\"\w/ # JSON String: '{"pat@example.com":{"name":"Pat"}}'
              self.add(parse_json(r))
            else # record<CR>record
              r.split("\n").each { |rr| self.add_string_recipient(rr) }
            end
          elsif r.is_a?(File)
            r.each_line { |rr| self.add_string_recipient(rr) }
          elsif r.respond_to?(:each) # Enumerable
            r.each { |rr| self.add(rr) }
          end
        end
      end

      def add_string_recipient(str)
        self.add_recipient(parse_recipient)
      end

      def add_recipient(recipient)
        self.spill! if @count == SPILL_FILE_AFTER
        if @recipients.is_a?(Array)
          @recipients << recipient
        else
          outfile.write file_recipient(recipient)
        end
        @count += 1
      end

      def spill!
        return unless @recipients.is_a?(Array)
        @recipients.each { |r| write_recipient(r) }
        @recipients = outfile
      end

      def outfile
        @outfile ||= Tempfile.new('email_address_list.out')
      end

      def write_recipient(recipient)
        outfile.write file_recipient(recipient)
      end

      def file_recipient(recipient)
        rec = recipient.first
        if recipient.second && recipient.second.is_a?(Hash)
          rec += "\t" + recipient.second.to_json
        end
        rec + "\n"
      end

      ##############################################################################
      # Parsing
      ##############################################################################

      def normalize_recipient(recip)
        case recip
        when Array # [email, data]
          recip[1] ||= Hash.new
          recip[1] = parse_data(recip[1]) if recip[1].is_a?(String)
          recip
        when String
          parse_recipient(recip)
        when Hash
          email = recip.delete("email")
          add_recipient([email, recip])
          recip["email"] = email #restore?
        else
        end
      end

      def parse_recipient(str)
        email, data = ['', Hash.new]
        str.strip!

        if str =~ /\A(\S+)\s+(\{.*\})/ # "address {"name":"Pat"}
          email, data = [$1, parse_json($2)]
        elsif str =~ /\A[^\s\|\,]+([\s\,\|]?)/x # separator for "email name fields"
          if $1 == '' # Email only
            email = str
          elsif $1 == ' ' # Email<SPACE>Name
            (email, name) = str.split(/\s+/, 2)
            data[:name] = name
          else # Email<TAB>Name<TAB><DATA_STRING>
            (email,*fields) = str.split($1).map {|s| s.strip  }
            if fields.size > 1 # with name and/or fields
              data = parse_data(fields[1]).merge(name:fields[0])
            elsif fields.first =~ /^(\{\"?\w|\w+=.*)/ # fields only
              data = parse_data(fields.first)
            else
              data[:name] = fields.first
            end
          end
        elsif str =~ /(\w[\w\.\-\+\=\']*@\w[\w\.\-]+\w)/ # Find inside email
          email = $1
        elsif str =~ /\A\s*([\da-f]{32})\b/ # MD5
          email = $1
        end

        email = normalize_email_address(email)
        [email, data]
      end

      def normalize_email_address(email)
        return email.downcase if email =~ /\A[\da-f]{32}\z/i
        EmailAddress.new(email).normalize
      end

      def parse_data(data)
        fields = {}
        if data =~ /\A(\w+)=/
          data.split(/; */).each do |pair|
          _,v = pair.strip.split(/ *= */, 2)
          fields[v.downcase] = v
        end
        elsif data =~ /\A\{"\w+":/
          fields = parse_json(data)
        end
        fields
      end

      def parse_json(data, empty_value={})
        begin
          r = JSON.parse(data)
          r.symbolize_keys! if r.is_a?(Hash)
          if r.is_a?(Array)
            r.each {|rr| rr.symbolize_keys! if rr.is_a?(Hash) }
          end
        rescue JSON::ParserError => e
          p [:JSON, e, data]
          r = empty_value
          #raise e
        end
        r
      end
    end
  end
end
