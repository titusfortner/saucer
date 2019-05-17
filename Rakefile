# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yaml'
require 'saucer'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc 'update platform yaml'
task :update_platforms do
  platforms = SauceWhisk::Sauce.platforms

  yaml = platforms.each_with_object({}) { |opt, hash|
    key = Saucer::Platform.key(opt)
    next if key.nil?

    hash[key] = Saucer::Platform.values(opt)
  }.to_yaml
  File.open('config/platforms.yml', 'w') { |file| file.write yaml }
end

platforms = YAML.load_file('config/platforms.yml')

platforms.each do |key, value|
  task key do
    ENV['BUILD_NAME'] = 'Platform Validation Complete'

    opts = value.merge(name: key)

    begin
      options = Saucer::Options.new(opts)
      session = Saucer::Session.begin(options)
      session.driver.get('https://google.com')
      session.end

      session.result = 'passed'
    rescue StandardError => e
      puts "Unexpected Exception: #{e.inspect}"
    end
  end
end

desc 'run tests on all platforms to validate everything is working properly'
multitask validate_platforms: platforms.keys
