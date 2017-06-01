require 'sauce_platforms'
require 'yaml'

module Saucer
  class Parallel

    attr_accessor :number, :path, :output

    def initialize(opt = {})
      @number = opt[:number] || ENV['PARALLEL_PROCESSES']
      @path = opt[:path] || ENV['TEST_PATH'] || "spec"
      @output = opt[:output] || ENV['REPORT_OUTPUT'] || 'output'
      @platforms = opt[:platforms] || []
      if File.exist?('configs/platform_configs.yml')
        yaml = YAML.load_file('configs/platform_configs.yml')
        @platforms ||= yaml.map { |c| Saucer::PlatformConfiguration.new(c) }
      end
      @success = true
    end

    def run
      if @platforms.empty?
        raise StandardError, "Tests failed!" unless execute_test
        return
      end

      @platforms.each do |platform|
        Rake::Task.define_task(platform.name) {
          ENV['platform'] = platform.to_hash[:platform]
          ENV['browser_name'] = platform.to_hash[:browserName]
          ENV['version'] = platform.to_hash[:version]

          begin
            @result = execute_test
          ensure
            @success &= @result
          end
        }
      end

      Rake::MultiTask.define_task(sauce_tests: @platforms.map(&:name)) {
        raise StandardError, "Tests failed!" unless @success
      }.invoke
    end

    def execute_test
      if path.include?('spec')
        ENV['PARALLEL_SPLIT_TEST_PROCESSES'] = number.to_s if number
        system "parallel_split_test #{path} --out #{@output}.xml"
      elsif path.include?('features')
        system "parallel_cucumber #{path} -o \"--format junit --out #{@output} --format pretty\" -n #{number.to_s}"
      else
        raise ArgumentError, "Unable to determine if using rspec or cucumber"
      end
    end
  end
end
