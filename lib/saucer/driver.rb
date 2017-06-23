module Saucer
  class Driver < Selenium::WebDriver::Driver

    include Annotations

    attr_reader :driver, :config

    def initialize(opt = {})
      caps = opt[:desired_capabilities] || {}
      @config ||= Config::Selenium.new(caps)
      listener = opt.delete :listener
      opt[:url] = @config.url
      opt[:desired_capabilities] = @config.capabilities

      bridge = Selenium::WebDriver::Remote::Bridge.new(opt)
      bridge = Support::EventFiringBridge.new(bridge, listener) if listener

      @driver = super bridge

      @driver.job_name = @config.sauce[:name]
      @driver.build_name = @config.sauce[:build]
    end

    def sauce
      @api ||= API.new(self, @config)
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
        @driver.comment = "Error: #{exception.inspect}"
        @driver.comment = "Error Location: #{exception.backtrace.first}"
      end

      @driver.job_result = result unless result.nil?
      results = @driver.sauce.job.log_url[/(.*)\/.*$/, 1]
      Selenium::WebDriver.logger.warn("Sauce Labs results: #{results}")

      super(*[])
    end

  end
end
