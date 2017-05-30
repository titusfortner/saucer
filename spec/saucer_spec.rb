require "spec_helper"

RSpec.describe Saucer do

  after { @driver.quit if @driver }
  it 'initializes browser' do
    @driver = Saucer::Driver.new
    expect(@driver).to be_a Selenium::WebDriver::Driver
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
    @driver = Saucer::Driver.new(config_selenium)
    expect(@driver.capabilities['browserVersion']).to eq '53.0'
  end

  it 'uses annotations' do
    @driver = Saucer::Driver.new
    @driver.get('http://google.com')
    @driver.comment('Hi Mom!')
    @driver.job_result(true)
    @driver.job_name("Testing Annotations")
    @driver.job_tags(['1', '2', '3'])
    @driver.build_name("Annotation Build")
  end

end