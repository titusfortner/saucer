module Saucer
  module Config
    class Appium < Common

      CONFIG_PARAMS = %i(appium_version browser_name device_name platform_version app appium_version
                    device_type device_orientation automation_name app_package app_activity).freeze

      def initialize(opt = {})
        super
        @config_params += CONFIG_PARAMS
      end

      def url
        if test_object?
          "http://appium.testobject.com/wd/hub"
        else
          super
        end
      end

      def test_object?
        !ENV['TESTOBJECT_API_KEY'].nil? && !ENV['TESTOBJECT_API_KEY'].empty?
      end

    end
  end
end