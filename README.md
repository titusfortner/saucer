# Saucer

Make running your tests on Sauce Labs easier with these helpful wrappers and convenience methods

## Disclaimer
*This code is provided on an "AS-IS” basis without warranty of any kind, either express or implied, including without limitation any implied warranties of condition, uninterrupted use, merchantability, fitness for a particular purpose, or non-infringement. Your tests and testing environments may require you to modify this framework. Issues regarding this framework should be submitted through GitHub. For questions regarding Sauce Labs integration, please see the Sauce Labs documentation at https://wiki.saucelabs.com/. This framework is not maintained by Sauce Labs Support.*

## Installation

In your Gemfile: 

`gem 'saucer'

In your project:

```ruby
require 'saucer'
```

## Usage

#### Starting the Driver
Use Saucer to start your sessions
```ruby
@session = Saucer::Session.begin
@driver = @session.driver
```
Optionally you can create options with various parameters to pass into `Session.begin`
```ruby
options = Saucer::Options.new(browser_name: 'Safari', 
                              browser_version: '12.0',
                              platform_name: 'macOS 10.14')
@session = Saucer::Session.begin(options)
@driver = @session.driver
```

#### Finishing the session
You can still quit the driver yourself if you'd like
```ruby
@driver.quit
```
You get some automatic data population if you end the Session
```ruby
@session.end
```

#### Automatic Data Population
To automatically pass in the test name, populate pass/fail and provide exception information:
RSpec doesn't need to do anything, but Cucumber will need to specify the scenario information
in the `env.rb` or `hooks.rb` file.
```ruby
Before do |scenario|
  options = Saucer::Options.new(scenario: scenario)
  session = Saucer::Session.begin(options)
  @driver = session.driver
end
```

#### Session Commands
Saucer provides a number of custom methods as part of the session instance:
```ruby
# Add useful information to a test after initializing a session
@session.comment = "Foo"
@session.tags = %w[foo bar]
@session.tags << 'foobar'
@session.data = {foo: 'bar'}
@session.data[:bar] = 'foo'

# These things should be set automatically, but can be set manually
@session.name = 'Test Name'
@session.build = 'Build Name'
@session.result = 'passed'
@session.result = 'failed'

# Special Features that might be useful
@session.stop_network
@session.start_network
@session.breakpoint

# This will cause an error, but is available as an option 
session.stop

# These things can be done after the session has ended
@session.save_screenshots
@session.save_log(log_type: :selenium) 
@session.save_log(log_type: :sauce) 
@session.save_log(log_type: :automator) 
@session.save_logs
@session.save_video
@session.save_assets
@session.delete_assets
```

#### Additional API Interactions
A more fully featured wrapping of the Sauce API is planned for upcoming releases.
For now, make use of [SauceWhisk](https://github.com/saucelabs/sauce_whisk).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/titusfortner/saucer.

## License & Copyright

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
see LICENSE.txt for full details and copyright.
