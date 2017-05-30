module Saucer
  module Parallel
    class RSpec < Common

      def self.run
        ENV['PARALLEL_SPLIT_TEST_PROCESSES'] = number if number
        super
      end

      def self.command
        "parallel_split_test spec#{path} --out #{output}"
      end

    end
  end
end
