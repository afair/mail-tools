##############################################################################
# Wrapper around Mail gem, access more like EmailMessage
#-----------------------------------------------------------------------------
# description:text sender recipient subject alt_subject sent_at:datetime
# message_id_header to_name to_email from_name from_email from_header
# other_headers body_text:text body_html:html body_sms subject_search
# text_search filename rfc822_size:integer data:hstore type
#-----------------------------------------------------------------------------
# mail[:header_name].to_s #=> value
# mail[:to].addrs.collect {|a| [a.address, a.display_name] }
# mail.multipart? ? mail.parts.collect {|p| p.body.decoded } : mail.body.decoded
# mail[:content_type].content_type #=> "multipart/alternative"
# mail.body.parts.first.parts.first[:content_type].content_type #=> "text/plain"
##############################################################################

module Mail
  module Tools

    class Editor
      attr_accessor :mail

      def self.read(filename)
        self.new(File.read(filename))
      end

      def self.construct(a={})
        email = Mail::Tools::Editor.new

        email.subject   = a[:subject]   if a[:subject]
        email.date      = a[:date]      if a[:date]
        email.from      = a[:from]      if a[:from]
        email.from_name = a[:from_name] if a[:from_name]
        email.to        = a[:from]      if a[:from]
        email.to_name   = a[:to_name]   if a[:to_name]

        email.body_text = a[:body_text] if a[:body_text]
        email.html_text = a[:html_text] if a[:html_text]
        a[:attachments].each {|f| email.attach(f) } if a[:attachments]

        email
      end

      def self.for_mail(mail)
        editor = Editor.new
        editor.mail = mail
        editor
      end

      def initialize(*args)
        @mail = Mail.new(*args)
      end

      def to_s
        mail.to_s
      end

      def multipart_alternative?
        @mail[:content_type].content_type == 'mulipart/alternative' ||
          @mail.parts.first[:content_type].content_type == 'mulipart/alternative'
      end

      def multipart_mixed?
        @mail[:content_type].content_type == 'mulipart/mixed'
      end
      alias has_attachments? multipart_mixed?

      ##############################################################################
      # Header
      ##############################################################################

      # Gets/Sets the header
      def [](n)
        @mail[n] && @mail[n].value
      end

      def []=(n,v)
        #@mail[n] = v
        @mail.headers(n=>v)
      end

      def set_header(n,v)
        @mail.headers(n=>v)
      end

      def delete_header(n)
        @mail[n] = nil if @mail[n]
      end

      def headers
        part_headers(@mail)
      end

      def part_headers(part)
        h = {}
        part.header.fields.each do |f|
          h[f.name] = f.to_s if f.name.is_a?(String)
        end
        h
      end

      def message_id; @mail.message_id; end
      def message_id=(s); @mail.message_id=s; end

      def subject; @mail.subject; end
      def subject=(s); @mail.subject=s; end
      def prefix_subject(prefix); self.subject = prefix + " " + self.subject; end

      def date; @mail.date; end
      def date=(d); @mail.date=d; end

      def from_email(index=0); mail_address(:from, index).first; end
      def from_name(index=0); mail_address(:from, index).second; end
      def from_header; @mail[:from].to_s; end
      def from_addresses; mail_addresses(:to); end #=> [[addr,name],...]

      def from=(email) # email, [email, name]
        (email, name) = email.is_a?(Array) ? email : [email, nil]
        @mail.from = email
        @mail[:from].addrs.first.display_name = name if name
      end

      def to_email(index=0); mail_address(:to, index).first; end
      def to_name(index=0); mail_address(:to, index).second; end
      def to_header; @mail[:to].to_s; end
      def to_addresses; mail_addresses(:to); end

      def to=(email) # email, [email, name]
        (email, name) = email.is_a?(Array) ? email : [email, nil]
        @mail.to = email
        @mail[:to].addrs.first.display_name = name if name
      end

      def parse_email_header(header) #=> [email, display_name]
        header.strip!
        if header =~ /(.+?) *\<(.+?)\>/ || header =~ /(.+?) +(\S+@\S+)/
          return [$2, $1]
        elsif header =~ /\<?(\S+@\S+)\>?/
          return [$1, nil]
        end
        [header, nil]
      end

      def make_email_header(email, name)
        h = "<#{email}>"
        h = name + ' ' + h if name && name > ' '
        h
      end

      ##############################################################################
      # Body
      ##############################################################################

      def body_text; get_body(:text); end
      def body_html; get_body(:html); end
      def body_text=(t); set_body(:text, t); end
      def body_html=(t); set_body(:html, t); end

      def text; get_body(:text); end
      def html; get_body(:html); end
      def text=(t); set_body(:text, t); end
      def html=(t); set_body(:html, t); end

      ##############################################################################
      # Attachments
      ##############################################################################

      def attachments
        @mail.attachments
      end

      def each_attachment(match='', &block)
        # Each attachment is a Mail::Part
        @mail.attachments.each do |a|
          next unless a.content_type.starts_with?(match)
          h = a.content_type_parameters
          h["content_type"] = a.content_type =~ /\A(.+)\;/ ? $1 : a.content_type
          h["body"] = a.body.decoded
          block.call(h, a)
        end
      end

      def attach(attach_rec)
        @mail.add_file(filename:a[:filename], content:a[:data], content_type:a[:content_type])
      end

      # private

      def get_body(ctype=:text)
        part  = ctype == :text ? @mail.text_part : @mail.html_part
        part ? part.body.decoded.force_encoding(part.charset).encode("UTF-8") : part
      end

      def set_body(ctype, string)
        meth  = ctype == :text ? :text_part= : :html_part=
          mtype = ctype == :text ? 'text/plain' : 'text/html'
        @mail.send(meth, nil)
        @mail.send(meth, Mail::Part.new(body: string,
                                        content_type:"#{mtype}; charset=UTF-8"))
      end

      def mail_address(header, index=0)
        return [nil, nil, nil] if !@mail[header] || @mail[header].addrs.size <= index
        [ @mail[header].addrs[index].address,
          @mail[header].addrs[index].display_name,
          @mail[header].addrs[index].to_s ]
      end

      def mail_addresses(header)
        @mail[header].addrs.collect {|a| [a.address, a.display_name] }
      end


      def mail_body(ctype=:text, part=nil)
        part ||= mail
        mtype = ctype == :text ? 'text/plain' : 'text/html'
        if !mail.multipart?
          return nil unless mail[:content_type] && mail[:content_type].content_type == mtype
          #return mail.body.decoded
          return mail.body.decoded.force_encoding(mail.charset).encode("UTF-8")
        elsif mail[:content_type].content_type == 'mulipart/alternative'
          mail.body.parts.each do |p|
            if p[:content_type].content_type == mtype
              #return p.body.decoded
              return p.body.decoded.force_encoding(p.charset).encode("UTF-8")
            end
          end
          return nil
        elsif mail[:content_type].content_type == 'mulipart/mixed'
          return mail_body(ctype, mail.parts.first)
        end
        nil
      end

    end
  end
end
