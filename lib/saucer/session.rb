# frozen_string_literal: true

require 'sauce_whisk'

module Saucer
  class Session
    class << self
      def begin(options = nil, scenario: nil)
        options ||= Options.new(scenario: scenario)
        options.name ||= test_name if test_name
        options.build ||= build_name

        driver = Selenium::WebDriver.for :remote, url: options.url, desired_capabilities: options.capabilities
        new(driver, options)
      end

      def test_name
        if RSpec.respond_to?(:current_example) && !RSpec.current_example.nil?
          RSpec.current_example.full_description
        elsif scenario
          scenario.source.map(&:name).join(" ")
        else
          nil
        end
      end

      def build_name
        if ENV['BUILD_NAME']
          ENV['BUILD_NAME']
        elsif ENV['BUILD_TAG']
          ENV['BUILD_TAG']
        elsif ENV['TRAVIS_JOB_NUMBER']
          "#{ENV['TRAVIS_REPO_SLUG'][/[^\/]+$/]}: #{ENV['TRAVIS_JOB_NUMBER']}"
        elsif ENV['SAUCE_BAMBOO_BUILDNUMBER']
          ENV['SAUCE_BAMBOO_BUILDNUMBER']
        elsif ENV['CIRCLE_BUILD_NUM']
          "#{ENV['CIRCLE_JOB']}: #{ENV['CIRCLE_BUILD_NUM']}"
        else
          "Local Execution - #{Time.now.to_i}"
        end
      end
    end

    attr_accessor :tags, :data
    attr_reader :driver, :options, :job_id, :scenario, :runner

    def initialize(driver, options)
      @driver = driver
      @options = options
      @job_id = driver.session_id
      @tags = []
      @data = {}
      @scenario = options.scenario
      @runner = if RSpec.respond_to?(:current_example) && !RSpec.current_example.nil?
                  :rspec
                elsif @scenario
                  :cucumber
                else
                  nil # unknown
                end

      generate_data
      SauceWhisk.data_center = options.data_center
    end

    def generate_data
      gems = Bundler.definition.specs.map(&:name).each_with_object({}) do |gem_name, gems|
        next if Bundler.environment.specs.to_hash[gem_name].empty?
        gems[gem_name] = Bundler.environment.specs.to_hash[gem_name].first.version
      end

      data[:selenium_version] = gems['selenium-webdriver']

      data[:test_library] = if gems['watir'] && gems['capybara']
                              'multiple'
                            elsif gems['capybara']
                              'capybara'
                            elsif gems['watir']
                              'watir'
                            else
                              'unknown'
                            end

      page_objects = %w(site_prism page-object watirsome watir_drops) & gems.keys

      data[:page_object] = if page_objects.size > 1
                             'multiple'
                           elsif page_objects.empty?
                             'unknown'
                           else
                             page_objects.first
                           end


      data[:runner] = gems[runner.to_s] ? "#{runner} v#{gems[runner.to_s]}" : "Unknown"

      data[:language] = "Ruby v#{Selenium::WebDriver::Platform.ruby_version}"
      data[:ci_tool] = Selenium::WebDriver::Platform.ci if Selenium::WebDriver::Platform.ci
      data[:operating_system] = Selenium::WebDriver::Platform.os
    end

    def end
      self.result = result unless result.nil?
      if exception
        self.data[:error] = exception.inspect
        self.data[:stacktrace] = exception.backtrace
      end
      save
      driver.quit

      start_time = Time.now
      loop do
        break if details.end_time || Time.now - start_time > 10
      end

    end

    def result
      if runner == :rspec
        RSpec.current_example.exception.nil?
      elsif runner == :cucumber
        scenario.passed?
      else
        nil
      end
    end

    def exception
      if runner == :rspec
        RSpec.current_example.exception
      elsif runner == :cucumber
        scenario.exception
      else
        nil
      end
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

    def details
      SauceWhisk::Jobs.fetch(@job_id)
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
