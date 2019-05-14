require 'rspec'
require 'saucer'

include Saucer

RSpec.configure do |config|
  config.filter_run_including focus: true unless ENV['CI']
  config.run_all_when_everything_filtered = true
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
