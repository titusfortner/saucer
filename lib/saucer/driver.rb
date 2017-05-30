require 'selenium-webdriver'

module Saucer
  class Driver < Selenium::WebDriver::Driver

    def initialize
      super Selenium::WebDriver::Remote::Bridge.new(Config.new.opts)
    end

  end
end
