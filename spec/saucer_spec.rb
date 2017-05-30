require "spec_helper"

RSpec.describe Saucer do
  it 'initializes browser' do
    begin
      @driver = Saucer::Driver.new
      expect(@driver).to be_a Selenium::WebDriver::Driver
    ensure
      @driver.quit
    end
  end

end
