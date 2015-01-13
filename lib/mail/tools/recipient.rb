module Mail
  module Tools
    class Recipient
      attr_accessor :address, :data

      def initialize(address, data={})
        self.address = address
        self.data    = data
      end

      def self.coerce(recip)
        case recip
        when Array # [email, data]
          recip[1] ||= Hash.new
          recip[1] = parse_data(recip[1]) if recip[1].is_a?(String)
          Recipient.new(recip[0], recip[1])
        when String
          self.parse(recip)
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
          email, data = [$1, Recipient.parse_json($2)]
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

        email = self.normalize_email_address(email)
        Mail::Tools::Recipient.new(email, data)
      end

      def self.normalize_email_address(email)
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
          fields = Recipient.parse_json(data)
        end
        fields
      end

      def self.parse_json(data, empty_value={})
        begin
          r = JSON.parse(data)
          r = symbol_key_hash(r) if r.is_a?(Hash)
          if r.is_a?(Array)
            r = r.map {|rr| rr = symbol_key_hash(rr) if rr.is_a?(Hash) }
          end
        rescue JSON::ParserError #=> e
          #p [:JSON, e, data]
          r = empty_value
          #raise e
        end
        r
      end

      def self.symbol_key_hash(hash)
        hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end

      def to_record
        if self.data.size > 0
          [self.address, self.data.to_json].join("\t") + "\n"
        else
          self.address + "\n"
        end
      end

    end
  end
end
