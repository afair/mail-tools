module Mail::Tools

  # A Maildrop is a directory where emails can be temporarily dropped
  # for later processing. The messages are stored in MailFile format.
  # It provides a simple queueing mechanism, or can be used to store
  # large message files for traditional message queues jobs.
  #
  # Usage:
  #   drop = Mail::Tools::Maildrop.new(directory)
  #   drop.deliver(message)
  #
  #   drop.receive { |message| process(message) }
  #
  class Maildrop
    include Enumerable

    def self.deliver(dir, message)
      Mail::Tools::Maildrop.new(dir).deliver(message)
    end

    def self.receive
      Mail::Tools::Maildrop.new(dir).receive
    end

    def initialize(dir=nil, dead_letter=nil)
      @dir ||= ENV['MAILDROP_DIR'] || '/tmp/maildrop'
      @dead_letter ||= ENV['MAILDROP_DEAD_LETTERS'] || '/tmp/maildrop.dead'
      FileUtils.mkdir_p(@dir) unless Dir.exists?(@dir)
      FileUtils.mkdir_p(@dead_letter) unless Dir.exists?(@dead_letter)
    end

    def deliver(message)
      filename = new_filename
      #p [:fn, filename, message]
      Mail::Tools::MailFile.write(filename + '.tmp', message)
      p [filename + '.tmp ', filename + '.new']
      p `ls -l #{@dir}`
      File.rename(filename + '.tmp ', filename + '.new')
      filename + '.new'
    end

    # Named by <DIR>/<Epoch>.<Rand>.<Hostname> .. processing adds: .new,
    def new_filename
      fname = nil
      loop do
        fname = [Time.now.to_i, rand(99999), Socket.gethostname].join('.')
        break unless File.exists?(File.join(@dir, 'new', fname))
      end
      @dir + File::SEPARATOR + fname
    end

    # Iterates through the maildrop directory, returning a Mail::Tools::Message
    # object and filename (if you want to stat it) to the block.
    # Exceptions are trapped, and the file saved for another try, then
    # re-raised. Otherwise, the file is deleted after processing
    #
    # Example Usage:
    #   Mail::Tools::Maildrop.new(dir).receive {|m| Mail::Tools::Inject.deliver(m); }
    #
    def receive
      now = Time.now.to_i.to_s
      self.each do |filename, qname|
        next if qname > now # Deferred, time back-off
        msg = Mail::Tools::MailFile.read(filename)
        begin
          yield msg, filename
          File.unlink filename
        rescue Exception => e
          defer(filename, qname)
          raise e
        end
      end
    end

    # Renames the drop file by the next epoch time it can be re-processed
    def defer(filename, qname)
      epoch, rnd, ext = qname.split('.')
      ext = 0 if ext == 'new'
      ext = ext.to_i + 1
      if ext < 10
        epoch = Time.now.to_i + (60 * (2 ** ext))
        newpath = @dir + File::SEPARATOR + [epoch, rnd, ext].join('.')
      else
        newpath = @dead_letter + File::SEPARATOR + qname
      end
      File.rename(filename, newpath)
    end

    def clear!
      self.each { |path| File.unlink(path) }
    end

    # Iterates over each file in the drop directory
    def each
      Dir.new(@dir).sort.each do |filename|
        next if filename =~ /\.tmp\z/ || filename !~ /\A\w/ 
        yield @dir + File::SEPARATOR + filename, filename
      end
    end

    # Renames file to the inode number, like Qmail
    def rename_to_inode(filename)
      st = File::Stat.new(filename)
      newname = @dir + File::SEPARATOR + st.ino.to_s
      File.rename(filename, @dir + File::SEPARATOR + st.ino.to_s)
      newname
    end

  end
end
