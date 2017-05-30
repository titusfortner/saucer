module Saucer
  module Parallel
    class Cucumber < Common

      def self.command
        "parallel_cucumber features#{path} -o \"--format junit --out #{output} --format pretty\" -n #{number}"
      end

      end
    end
  end
