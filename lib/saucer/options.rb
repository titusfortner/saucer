# frozen_string_literal: true

module Saucer
  class Options
    W3C = %i[browser_name browser_version platform_name accept_insecure_certs page_load_strategy proxy set_window_rect
             timeouts strict_file_interactability unhandled_prompt_behavior].freeze

    SAUCE = %i[access_key appium_version avoid_proxy build capture_html chromedriver_version command_timeout
               crmuxdriver_version custom_data disable_popup_handler extended_debugging firefox_adapter_version
               firefox_profile_url idle_timeout iedriver_version max_duration name parent_tunnel passed prerun
               prevent_Requeue priority proxy_host public record_logs record_screenshots record_video
               restricted_public_info screen_resolution selenium_version source tags time_zone tunnel_identifier
               username video_upload_on_pass].freeze

    VALID = W3C + SAUCE

    attr_accessor :url, :scenario
    attr_reader :data_center

    def initialize(**opts)
      VALID.each do |option|
        self.class.__send__(:attr_accessor, option)
        next unless opts.key?(option)

        instance_variable_set("@#{option}", opts.delete(option))
      end

      validate_credentials
      @browser_name ||= 'firefox'
      @platform_name ||= 'Windows 10'
      @browser_version ||= 'latest'
      @selenium_version ||= '3.141.59'

      opts.key?(:url) ? @url = opts[:url] : self.data_center = :US_WEST
      @scenario = opts[:scenario] if opts.key?(:scenario)
    end

    def capabilities
      w3c = W3C.each_with_object({}) do |option, hash|
        value = instance_variable_get("@#{option}")
        next if value.nil?

        hash[option] = value
      end

      sauce = SAUCE.each_with_object({}) do |option, hash|
        value = instance_variable_get("@#{option}")
        next if value.nil?

        hash[option] = value
      end

      w3c.merge('sauce:options' => sauce)
    end
    alias to_h capabilities

    def data_center=(data_center)
      @url = case data_center
             when :US_WEST
               'https://ondemand.saucelabs.com:443/wd/hub'
             when :US_EAST
               'https://us-east-1.saucelabs.com:443/wd/hub'
             when :EU_VDC
               'https://ondemand.eu-central-1.saucelabs.com:443/wd/hub'
             else
               raise ::ArgumentError, "#{data_center} is an invalid data center; specify :US_WEST, :US_EAST or :EU_VDC"
             end
      @data_center = data_center
    end

    private

    def validate_credentials
      @username ||= ENV['SAUCE_USERNAME']
      msg = "No valid username found; either pass the value into `Options#new` or set with ENV['SAUCE_USERNAME']"
      raise AuthenticationError, msg if @username.nil?

      @access_key ||= ENV['SAUCE_ACCESS_KEY']
      return unless @access_key.nil?

      msg = "No valid access key found; either pass the value into `Options#new` or set with ENV['SAUCE_ACCESS_KEY']"
      raise AuthenticationError, msg
    end
  end
end
