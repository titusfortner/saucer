# frozen_string_literal: true

require 'sauce_whisk'

module Saucer
  class Session
    def self.start(options = nil)
      options ||= Options.new
      driver = Selenium::WebDriver.for :remote, url: options.url, desired_capabilities: options.capabilities
      new(driver, options)
    end

    attr_accessor :tags, :data
    attr_reader :driver, :options, :job_id

    def initialize(driver, options)
      @driver = driver
      @options = options
      @job_id = driver.session_id
      @tags = []
      @data = {}

      SauceWhisk.data_center = options.data_center
    end

    # Custom JS Commands

    def comment=(comment)
      @driver.execute_script("sauce: context=#{comment}")
    end

    def stop_network
      @driver.execute_script('sauce: stop network')
    end

    def start_network
      @driver.execute_script('sauce: start network')
    end

    def breakpoint
      @driver.execute_script('sauce: break')
    end

    # Requires #save

    def name=(name)
      job.name = name
    end

    def build=(name)
      job.build = name
    end

    def visibility=(value)
      valid = %i[public public_restricted share team private]
      raise ArgumentError, "#{value} is not a valid visibility value; use one of #{valid}" unless valid.include?(value)

      job.visibility = value.to_s
    end

    def save
      job.tags = tags unless tags.empty?
      job.custom_data = data unless data.empty?
      SauceWhisk::Jobs.save(job)
    end

    # Updates Job

    def result=(res)
      SauceWhisk::Jobs.change_status(@job_id, res)
    end

    def stop
      SauceWhisk::Jobs.stop(@job_id)
    end

    def delete
      start_time = Time.now
      begin
        response = JSON.parse SauceWhisk::Jobs.delete_job(@job_id).body
        raise APIError, "Can not delete job: #{response['error']}" if response.key?('error')
      rescue APIError
        retry if (Time.now - start_time < 5)
        raise
      end
    end

    # Handles Assets

    def screenshots
      start_time = Time.now
      begin
        urls = SauceWhisk::Jobs.job_assets(job_id)['screenshot_urls']
        raise APIError, "No screenshots found" if urls.nil?
      rescue APIError
        retry if (Time.now - start_time < 5)
      end
      job.screenshots
    end

    def save_screenshots(path = nil)
      screenshots&.each do |screenshot|
        save_file(path: path, file_name: screenshot.name, data: screenshot.data.body, type: 'screenshots')
      end
    end

    def log(log_type = nil)
      log_type ||= :sauce
      valid = {sauce: 'log.json',
               selenium: 'selenium-server.log',
               automator: 'automator.log'}
      raise ArgumentError,
            "#{log_type} is not a valid log type; use one of #{valid.keys}" unless valid.keys.include?(log_type)

      start_time = Time.now
      begin
        response = asset(valid[log_type]).body
        raise APIError, "Can not retrieve log: #{response['message']}" if JSON.parse(response).key?('message')
      rescue NoMethodError
        # Sauce Log is Special
        JSON.parse(response).map { |hash|
          hash.map { |key, value|
            "#{key}: #{value}"
          }.join("\n")
        }.join("\n\n")
      rescue JSON::ParserError, NoMethodError
        response
      rescue APIError
        retry if (Time.now - start_time < 5)
        raise
      end
    end

    def save_log(path: nil, log_type: nil)
      log_type ||= :sauce
      save_file(path: path, file_name: "#{log_type}.log", data: log(log_type), type: 'logs')
    end

    def save_logs(path: nil)
      %i[sauce selenium automator].each do |type|
        save_log(path: path, log_type: type)
      end
    end

    def video_stream
      start_time = Time.now
      begin
        response = asset('video.mp4').body
        raise APIError, "Can not retrieve video: #{response['message']}" if JSON.parse(response).key?('message')
      rescue JSON::ParserError
        response
      rescue APIError
        retry if (Time.now - start_time < 5)
        raise
      end
    end

    def save_video(path = nil)
      save_file(path: path, file_name: 'video.mp4', data: video_stream, type: 'videos')
    end

    def save_assets
      save_logs
      save_video
      save_screenshots
    end

    def delete_assets
      start_time = Time.now
      begin
        response = JSON.parse(SauceWhisk::Assets.delete(job_id).data.body)
        raise APIError, "Can not delete assets: #{response}" if response.is_a?(String)
      rescue APIError
        retry if (Time.now - start_time < 5)
        raise
      end
    end

    private

    def save_file(path:, data:, file_name:, type:)
      path ||= File.expand_path("../../../assets/#{job_id}/#{type}/#{file_name}", __FILE__)

      file_name = path[/[^\/]*$/]
      base_path = path.gsub(file_name, '')

      FileUtils.mkdir_p(base_path) unless File.exist?(base_path)
      File.write(path, data)
    end

    def job
      @job ||= SauceWhisk::Jobs.fetch(@job_id)
    end

    def asset(asset)
      SauceWhisk::Jobs.fetch_asset(@job_id, asset)
    end
  end
end
