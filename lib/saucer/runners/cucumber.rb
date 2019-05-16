# frozen_string_literal: true

module Saucer
  class Cucumber
    class << self
      def test_name
        scenario.source.map(&:name).join(' ')
      end

      def name
        :cucumber
      end

      def result
        scenario.passed?
      end

      def exception
        scenario.exception
      end
    end
  end
end
