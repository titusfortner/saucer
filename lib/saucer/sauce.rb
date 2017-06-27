require 'sauce_whisk'

module Saucer
  class Sauce

    include Annotations

    def initialize(driver, config)
      @driver = driver
      @config = config
    end

    def api
      @api ||= API.new(@driver, @config)
    end

    def driver
      @driver
    end

  end
end