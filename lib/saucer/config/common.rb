module Saucer
  module Config
    class Common

      CONFIG_PARAMS = %i(auto_accept_alerts name build tags custom_data max_duration
                    command_timeout idle_timeout prerun executable args background
                    timeout tunnel_identifier parent_tunnel screen_resolution timezone
                    avoid_proxy public record_video video_upload_on_pass record_screenshots
                    record_logs capture_html priority webdriver_remote_quiet_exceptions).freeze

      attr_reader :config_params, :username, :access_key

      def initialize(opts = {})
        @username = opts.delete(:username) || ENV['SAUCE_USERNAME']
        @access_key = opts.delete(:access_key) || ENV['SAUCE_ACCESS_KEY']

        @opts = opts
        @config_params = CONFIG_PARAMS
      end
    end
  end
end