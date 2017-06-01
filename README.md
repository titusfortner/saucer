# Saucer

Convenience methods for running your Ruby tests on Sauce Labs

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'saucer'
```

## Usage

The most basic usage for parallel execution is to define the following Rake task, which 
will every spec in the spec directory in 4 processes on the default Sauce platform (Linux with Chrome v48)

```ruby
Saucer::Parallel.new.run
```

To Specify basic number of processes, a specific subdirectory (Cucumber or RSpec), and
output file:

```ruby
Saucer::Parallel.new(number: 7,
                     path: 'features/foo',
                     output: 'foo').run
```


To specify Sauce configurations, create a Rake Task that takes parameters like this:

```ruby
task :parallel_sauce do
  configs = [{os: :mac_10_10, browser: :chrome, browser_version: 38},
             {os: :mac_10_11, browser: :firefox, browser_version: 46},
             {os: :mac_10_8, browser: :chrome, browser_version: 42}]

  platforms = configs.map { |c| Saucer::PlatformConfiguration.new(c) }

  Saucer::Parallel.new(platforms: platforms).run
end
```

or you can create a yaml file in `configs/platform_configs.yml` like this:
```yaml
  - :os: :mac_10_10
    :browser: :chrome
    :browser_version: 38
  - :os: :mac_10_11
    :browser: :firefox
    :browser_version: 46
  - :os: :mac_10_8
    :browser: :chrome
    :browser_version: 42
```
 
 and have a Rake Task like this:
 
```ruby
task :parallel_sauce do
  Saucer::Parallel.new(number: 7,
                       path: 'spec/foo',
                       output: 'foo').run
end

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/saucer.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
