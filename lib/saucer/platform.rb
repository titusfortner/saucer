module Saucer
  class Platform

    def initialize(opts = {})
      @browser_name = opts['api_name'].to_sym
      @browser_version = opts['short_version']
      @platform = opts['os']
    end

  end
end
