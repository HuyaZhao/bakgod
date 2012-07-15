# encoding: utf-8
module BakGod
  module Lib
    class Uploader
      def self.run(command, from_path, to_path)
        self.new(command, from_path, to_path).run!
      end

      def initialize(command, from_path, to_path)
        @command   = command
        @from_path = from_path
        @to_path   = to_path
      end

      def run!
        Subexec.run("#{@command} #{@from_path} #{@to_path}")
      end

    end # class Uploader

    class Subexec

      def self.run(command, options = {})
        sub = self.new(command, options)
        sub.run!
        sub
      end

      def initialize(command, options = {})
        @command    = command
        @lang       = options[:lang]    || 'C'
        @timeout    = options[:timeout] || -1
        @exitstatus = 0
      end

      def command;   @command;   end
      def lang;      @lang;      end
      def timeout;   @timeout;   end
      def exitstatus;@exitstatus;end
      def pid;       @pid;       end
      def output;    @output;    end

      def run!
        spawn
      end

    private
      def spawn
        r, w = ::IO.pipe
        @pid = ::Process.spawn(
                    {'LANG' =>self.lang},
                    self.command,
                    STDERR =>w,
                    STDOUT =>w
                )
        w.close

        @timer = ::Time.now + self.timeout
        timed_out = false

        waitpid = ::Proc.new do
          begin
            flags = (self.timeout > 0 ? ::Process::WUNTRACED|::Process::WNOHANG : 0)
            ::Process.waitpid(self.pid, flags)
          rescue ::Errno::ECHILD
            break
          end
        end

        if self.timeout > 0
          loop do
            ret = waitpid.call
            break if ret == self.pid
            sleep 0.01
            if ::Time.now > @timer
              timed_out = true
              break
            end
          end
        else
          waitpid.call
        end

        if timed_out
          ::Process.kill(9, self.pid) rescue ::Errno::ESRCH
          @exitstatus = nil
        else
          @exitstatus = $?.exitstatus
          @output = r.readlines.join('')
        end
        r.close
        self
      end
    end # class Subexec
  end # module Lib
end # module BakGod