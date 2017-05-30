module Saucer
  module Parallel
    class Common
      @success = true

      def self.run
        FileUtils.mkpath(output) unless File.exist?(output)
        begin
          @result = system command
        ensure
          @success &= @result
        end
      end

      def self.number=(number)
        @number = number.to_s
      end

      def self.number
        @number ||= ENV['PARALLEL_PROCESSES']
      end

      def self.path=(path)
        @path = path
      end

      def self.path
        @path ||= ENV['TEST_PATH'] || ""
      end

      def self.output=(output)
        @output = output
      end

      def self.output
        @output ||= ENV['REPORT_OUTPUT'] || 'output.xml'
      end

    end
  end
end