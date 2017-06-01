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

    def quit(result = nil)
      @driver.job_result(result) unless result.nil?
      super(*[])
    end
  end

end
