module Saucer
  class Driver < Selenium::WebDriver::Remote::Driver

    attr_reader :driver, :config

    def initialize(*args)
      browser = args.pop if args.first.is_a? Symbol
      browser = nil if browser == :remote
      opt = args.first || {}
      unless opt[:desired_capabilities].is_a? Selenium::WebDriver::Remote::Capabilities
        opts = opt[:desired_capabilities] || {}
        browser = opt.key?(:browser_name) ? opt[:browser_name].downcase.to_sym : browser || :chrome
        opt[:desired_capabilities] = Selenium::WebDriver::Remote::Capabilities.send(browser, opts)
      end
      @config = Config::Selenium.new(opt)

      opt[:url] = @config.url
      opt[:desired_capabilities] = @config.capabilities

      super(opt)

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
