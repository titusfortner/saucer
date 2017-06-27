require "spec_helper"

RSpec.describe Saucer do

  context 'without errors' do
    after { @driver.quit if @driver }

    it 'initializes browser' do
      @driver = Saucer::Driver.new
      expect(@driver.driver).to be_a Selenium::WebDriver::Driver
    end

    it 'uses config parameters' do
      params = Config::Selenium.new.config_params
      expect(params.size).to eq 32
    end

    it 'sets capabilities' do
      config_selenium = Config::Selenium.new(version: 'foo', browser_name: :chrome, command_timeout: 4)
      caps = config_selenium.capabilities
      expect(caps[:version]).to eq 'foo'
      expect(caps[:command_timeout]).to eq 4
    end

    it 'uses capabilities to initialize browser' do
      @driver = Driver.new(desired_capabilities: {version: '53', browser_name: :firefox})
      expect(@driver.capabilities['browserVersion']).to eq '53.0'
    end

    it 'checking name & build' do
      @driver = Driver.new
      @driver.get('http://google.com')
      @driver.sauce.api.job
      @driver.comment = 'Hi Mom!'
      @driver.job_result = true
      @driver.job_name = "Testing Annotations"
      @driver.job_tags = ['1', '2', '3']
      @driver.build_name = "Annotation Build"
    end

    it 'uses Sauce Whisk' do
      @driver = Driver.new
      api = @driver.sauce.api
      expect(api.account.username).to eq ENV['SAUCE_USERNAME']
      expect(api.job.id).to eq(@driver.session_id)
      expect(api.concurrency[:total_concurrency]).to eq 100
    end
  end

  context 'after exit' do
    it 'auto adds name' do
      @driver = Driver.new
      @driver.quit
      j = @driver.sauce.api.job
      expect(j.name).to eq "Saucer after exit auto adds name"
    end

    it 'sets platform specific data' do
      @driver = Driver.new
      @driver.quit
      caps = @driver.config.capabilities[:"sauce:data"]
      expect(caps[:language]).to eq 'Ruby'
      expect(caps[:harness]).to include 'rspec'
    end
  end

  context 'error testing' do

    # This has to be tested manually because... test depends on a failing RSpec test which
    # by default can't give a passing test.
    # The test is passing if it returns a StandardError, and failing if it returns an ArgumentError

    after do
      @driver.quit
      j = @driver.sauce.api.job
      raise ArgumentError unless j.passed == false
    end

    xit 'automatically records results checking' do
      @driver = Driver.new
      raise StandardError, 'error raised'
    end

  end
end
