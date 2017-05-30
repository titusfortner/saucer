module Saucer
  module Config
    class Selenium < Common

      CONFIG_PARAMS = %i(browser_name version platform selenium_version
                    chromedriver_version iedriver_version).freeze

      def initialize(opt = {})
        super
        @config_params += CONFIG_PARAMS
      end

      def url
        "https://#{@username}:#{@access_key}@ondemand.saucelabs.com:443/wd/hub"
      end

      def opts
        {url: url, desired_capabilities: capabilities}
      end

      def capabilities
        caps = @config_params.each_with_object({}) do |param, hash|
                 hash[param] = @opts[param] if @opts.key?(param)
        end
        ::Selenium::WebDriver::Remote::Capabilities.send(@opts[:browser_name], caps)
      end
    end
  end
end
