require 'rspec'
require 'saucer'

Before do |scenario|
  Saucer::Config::Sauce.scenario = scenario
  @driver = Saucer::Driver.new
end

After do |scenario|
  Saucer::Config::Sauce.scenario = scenario
  @driver.quit
end
