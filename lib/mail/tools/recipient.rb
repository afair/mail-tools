module Mail
  module Tools
    class Recipient
      attr_accessor :address, :data

      def initalize(address, data={})
        self.address = address
        self.data    = data
      end

      def self.normalize_recipient(recip)
        case recip
        when Array # [email, data]
          recip[1] ||= Hash.new
          recip[1] = parse_data(recip[1]) if recip[1].is_a?(String)
          Recipient.new(recip[0], recip[1])
        when String
          parse_recipient(recip)
        when Hash
          email = recip.delete("email") || recip.delete("address")
          Recipient.new(email, recip)
        else
        end
      end

      def self.parse(str)
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
        new(email, data)
      end

      def normalize_email_address(email)
        return email.downcase if email =~ /\A[\da-f]{32}\z/i
        # EmailAddress.new(email).normalize
        ::Mail::Address.new(email).address
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
