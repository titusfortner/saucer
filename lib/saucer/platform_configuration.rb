require 'sauce_platforms'

module Saucer
  class PlatformConfiguration
    attr_accessor :browser, :os, :browser_version

    def initialize(opt = {})
      @browser = opt[:browser]
      @os = opt[:os] || opt['os'].downcase.tr(' ', '_').tr(',', '_')
      @browser_version = opt[:browser_version] || opt['short_version']
    end

    # TODO update for defaults
    def to_hash
      Platform.send(@os).send(@browser).send("v#{@browser_version}")
    end

    def name
      "#{@os}_#{@browser}_#{@browser_version}".to_sym
    end

  end
end