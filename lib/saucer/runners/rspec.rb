# frozen_string_literal: true

module Saucer
  class Rspec
    class << self
      def test_name
        RSpec.current_example.full_description
      end

      def name
        :rspec
      end

      def result
        RSpec.current_example.exception.nil?
      end

      def exception
        RSpec.current_example.exception
      end
    end
  end
end
