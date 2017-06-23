module Saucer
  module Config
    class Selenium < Common

      attr_reader :sauce

      CONFIG_PARAMS = %i(browser_name version platform selenium_version
                    chromedriver_version iedriver_version).freeze

      def initialize(opt = {})
        super
        @config_params += CONFIG_PARAMS
      end

      def url
        "https://#{@username}:#{@access_key}@ondemand.saucelabs.com:443/wd/hub"
      end

      def capabilities
        caps = @config_params.each_with_object({}) do |param, hash|
          hash[param] = @opts[param] if @opts.key?(param)
          hash[param] ||= ENV[param.to_s] if ENV[param.to_s]
        end
        @sauce = Sauce.new.to_hash

        caps[:"sauce:data"] = @sauce.to_hash
        browser_name = @opts[:browser_name] || :chrome
        ::Selenium::WebDriver::Remote::Capabilities.send(browser_name, caps)
      end
    end

  end
end
