module Saucer
  class Driver < Selenium::WebDriver::Driver

    def initialize(config = nil)
      config ||= Config.new
      super Selenium::WebDriver::Remote::Bridge.new(config.opts)
    end

  end
end
