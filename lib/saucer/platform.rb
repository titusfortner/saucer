# frozen_string_literal: true

require 'yaml'

module Saucer
  class Platform
    class << self
      def build
        YAML.load_file('config/platforms.yml')[ENV['PLATFORM']]
      end

      def key(opt)
        browser_name = browser_name(opt['long_name'])
        os_name = os_name(opt['os'])

        os_version = os_version(opt['os'])
        browser_version = opt['short_version'].chomp('.')

        return if invalid_combination(browser_name, browser_version, os_name, os_version)

        "#{os_name}_#{os_version}_#{browser_name}_#{browser_version}".gsub('.', '__')
      end

      def invalid_combination(browser_name, browser_version, os_name, os_version)
        (browser_name.nil? || os_name.nil?) ||
          (browser_name == 'ff' && invalid_firefox(os_name, browser_version)) ||
          (browser_name == 'safari' && invalid_safari(os_version, browser_version)) ||
          (browser_name == 'chrome' && invalid_chrome(browser_version))
      end

      def invalid_firefox(os_name, browser_version)
        os_name == 'mac' && browser_version.include?('dev') ||
          browser_version.match?(/\d+/) &&
            Gem::Version.new(browser_version) < Gem::Version.new('53')
      end

      def invalid_safari(os_version, browser_version)
        (Gem::Version.new(browser_version) < Gem::Version.new('10') ||
            os_version == '11' && browser_version == '10')
      end

      def invalid_chrome(browser_version)
        browser_version == 'dev'
      end

      def values(opt)
        browser = opt['api_name']
        version = opt['short_version'].chomp('.')
        platform = opt['os']

        val = if browser == 'chrome' && version.match?(/\d+/) &&
                 Gem::Version.new(version) < Gem::Version.new('75')
                {browser_name: browser,
                 version: version,
                 platform: platform}
              else
                {browser_name: browser,
                 browser_version: version,
                 platform_name: platform}
              end
        val[:chromedriver_version] = '75.0.3770.8' if browser == 'chrome' && version == 'beta'
        val
      end

      def browser_name(browser)
        case browser
        when 'Internet Explorer'
          'ie'
        when 'Firefox'
          'ff'
        when 'Safari'
          'safari'
        when 'Microsoft Edge'
          'edge'
        when 'Google Chrome'
          'chrome'
        end
      end

      def os_name(os_value)
        value = os_value.split(' ').first
        if value == 'Mac'
          'mac'
        elsif value == 'Windows'
          'win'
        end
      end

      def os_version(os_value)
        version = os_value.split.last[/[^\.]*$/]
        case version
        when '2012'
          '8'
        when 'R2'
          '8.1'
        when '2008'
          '7'
        else
          version
        end
      end
    end
  end
end
