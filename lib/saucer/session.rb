require 'sauce_whisk'

module Saucer
  class Session

    def self.start(options)
      driver = Selenium::WebDriver.for :remote, url: options.url, desired_capabilities: options.capabilities
      new(driver, options)
    end

    attr_reader :driver, :options, :job_id

    def initialize(driver, options)
      @driver = driver
      @options = options
      @job_id = driver.session_id

      SauceWhisk.data_center = options.data_center
    end


    def comment=(comment)
      @driver.execute_script("sauce: context=#{comment}")
    end

    def stop_network
      @driver.execute_script("sauce: stop network")
    end

    def start_network
      @driver.execute_script("sauce: start network")
    end

    def breakpoint
      @driver.execute_script("sauce: break")
    end

    def result=(res)
      SauceWhisk::Jobs.change_status(@job_id, res)
    end

    def save
      SauceWhisk::Jobs.save(@job_id)
    end

    def stop
      SauceWhisk::Jobs.stop(@job_id)
    end

    def delete
      SauceWhisk::Jobs.delete_job(@job_id)
    end

    def asset(asset)
      SauceWhisk::Jobs.fetch_asset(@job_id, asset)
    end

    def assets
      SauceWhisk::Jobs.job_assets(@job_id)
    end

    def screenshots
      SauceWhisk::Jobs.fetch(@job_id).screenshots
    end

    def video
      SauceWhisk::Jobs.fetch(@job_id).video
    end
  end
end