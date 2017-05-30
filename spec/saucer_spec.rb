require "spec_helper"

RSpec.describe Saucer do
  it 'initializes browser' do
    begin
      @driver = Saucer::Driver.new
      expect(@driver).to be_a Selenium::WebDriver::Driver
    ensure
      @driver.quit if @driver
    end
  end

  it 'uses config parameters' do
    params = Saucer::Config::Selenium.new.config_params
    expect(params.size).to eq 32
  end

  it 'sets capabilities' do
    config_selenium = Saucer::Config::Selenium.new(version: 'foo', browser_name: :chrome, command_timeout: 4)
    caps = config_selenium.capabilities
    expect(caps[:version]).to eq 'foo'
    expect(caps[:command_timeout]).to eq 4
  end

  it 'uses capabilities to initialize browser' do
    config_selenium = Saucer::Config::Selenium.new(version: '53', browser_name: :firefox)
    begin
      @driver = Saucer::Driver.new(config_selenium)
      expect(@driver.capabilities['browserVersion']).to eq '53.0'
    ensure
      @driver.quit if @driver
    end
  end

end
