module Saucer
  class Driver < Selenium::WebDriver::Remote::Driver

    attr_reader :driver, :config

    def initialize(opt = {})
      caps = opt[:desired_capabilities] || {}
      @config = Config::Selenium.new(caps)

      opt[:url] = @config.url
      opt[:desired_capabilities] = @config.capabilities

      super

      sauce.job_name = @config.sauce[:name]
      sauce.build_name = @config.sauce[:build]
    end

    def sauce
      @sauce ||= Sauce.new(self, @config)
    end

    def quit
      if RSpec.current_example
        exception = RSpec.current_example.exception
        result = exception.nil?
      elsif Saucer::Config::Sauce.scenario
        exception = Saucer::Config::Sauce.scenario.exception
        result = Saucer::Config::Sauce.scenario.passed?
      end

      if exception
        sauce.comment = "Error: #{exception.inspect}"
        sauce.comment = "Error Location: #{exception.backtrace.first}"
      end

      sauce.job_result = result unless result.nil?
      results = sauce.api.job.log_url[/(.*)\/.*$/, 1]
      Selenium::WebDriver.logger.warn("Sauce Labs results: #{results}")

      super
    end
  end
end
