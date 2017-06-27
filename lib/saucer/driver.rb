module Saucer
  class Driver

    attr_reader :driver, :config

    def initialize(opt = {})
      caps = opt[:desired_capabilities] || {}
      @config = Config::Selenium.new(caps)

      opt[:url] = @config.url
      opt[:desired_capabilities] = @config.capabilities

      @driver = Selenium::WebDriver.for(:remote, opt)

      sauce.job_name = @config.sauce[:name]
      sauce.build_name = @config.sauce[:build]
    end

    def sauce
      @sauce ||= Sauce.new(driver, @config)
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

      driver.quit
    end

    def method_missing(method_name, *arguments, &block)
      if driver.respond_to? method_name
        driver.send(method_name, *arguments, &block)
      end
    end

    def respond_to?(method_name, include_private = false)
      driver.respond_to?(method_name)
    end

  end
end
