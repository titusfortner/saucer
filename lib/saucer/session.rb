# frozen_string_literal: true

require 'sauce_whisk'

module Saucer
  class Session
    class << self
      def runner
        if RSpec.respond_to?(:current_example) && !RSpec.current_example.nil?
          Rspec
        elsif @scenario
          Cucumber
        else
          Unknown
        end
      end

      def begin(options = nil, scenario: nil)
        options ||= Options.new(scenario: scenario)
        options.name ||= test_name if test_name
        options.build ||= build_name

        driver = Selenium::WebDriver.for :remote, url: options.url, desired_capabilities: options.capabilities
        new(driver, options)
      end

      def test_name
        runner.test_name
      end

      def build_name
        if ENV['BUILD_NAME']
          ENV['BUILD_NAME']
        elsif ENV['BUILD_TAG']
          ENV['BUILD_TAG']
        elsif ENV['TRAVIS_JOB_NUMBER']
          "#{ENV['TRAVIS_REPO_SLUG'][%r{[^/]+$}]}: #{ENV['TRAVIS_JOB_NUMBER']}"
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

    include CustomCommands
    include JobUpdate
    include AssetManagement

    def initialize(driver, options)
      @driver = driver
      @options = options
      @job_id = driver.session_id
      @tags = []
      @scenario = options.scenario
      @runner = self.class.runner
      @data = generate_data

      SauceWhisk.data_center = options.data_center
    end

    def generate_data
      data_collection = DataCollection.new

      opt = {selenium_version: data_collection.selenium_version,
             test_library: data_collection.test_library,
             page_objects: data_collection.page_objects,
             test_runner: data_collection.test_runner(runner),
             language: "Ruby v#{Selenium::WebDriver::Platform.ruby_version}",
             operating_system: Selenium::WebDriver::Platform.os}
      opt[:ci_tool] = Selenium::WebDriver::Platform.ci if Selenium::WebDriver::Platform.ci
      opt
    end

    def end
      self.result = runner.result unless runner.result.nil?

      if runner.exception
        data[:error] = runner.exception.inspect
        data[:stacktrace] = runner.exception.backtrace
      end

      save
      driver.quit

      wait_until_finished
    end

    def wait_until_finished
      start_time = Time.now
      loop do
        break if finished? || Time.now - start_time > 10
      end
    end

    def finished?
      details.end_time
    end

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
        retry if Time.now - start_time < 5
        raise
      end
    end

    def details
      SauceWhisk::Jobs.fetch(@job_id)
    end

    private

    def job
      @job ||= SauceWhisk::Jobs.fetch(@job_id)
    end
  end
end
