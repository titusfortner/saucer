module Saucer
  class Driver < Selenium::WebDriver::Driver

    include Annotations

    attr_reader :driver, :config

    def initialize(config = nil)
      @config = config || Config::Selenium.new
      @driver = super Selenium::WebDriver::Remote::Bridge.new(@config.opts)
    end

    def sauce
      @api ||= API.new(self, @config)
    end

    def quit(data = nil)
      if data.is_a?(TrueClass) || data.is_a?(FalseClass)
        result = data
      elsif RSpec.current_example
        exception = RSpec.current_example.exception
        result = exception.nil?
      elsif Saucer::Config::Sauce.scenario
        exception = Saucer::Config::Sauce.scenario.exception
        result = Saucer::Config::Sauce.scenario.passed?
      end

      if exception
        @driver.comment "Error: #{exception.inspect}"
        @driver.comment "Error Location: #{exception.backtrace.first}"
      end

      @driver.job_result(result) unless result.nil?

      super(*[])
    end

  end
end
