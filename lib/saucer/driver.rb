module Saucer
  class Driver < Selenium::WebDriver::Driver

    include Annotations
    include API

    attr_reader :driver

    def initialize(config = nil)
      @config = config || Config::Selenium.new
      @driver = super Selenium::WebDriver::Remote::Bridge.new(@config.opts)
    end

  end

end
