# frozen_string_literal: true

module Saucer
  class Unknown
    class << self
      def test_name
        nil
      end

      def name
        :unknown
      end

      def result
        nil
      end

      def exception
        nil
      end
    end
  end
end
