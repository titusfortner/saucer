module Saucer
  module Config
    class Sauce

      def self.scenario=(scenario)
        @@scenario = scenario
      end

      def self.scenario
        @@scenario
      end

      DATA_PARAMS = %i(name build language host_os version ci ip gems framework page_object harness).freeze

      FRAMEWORKS = %w(capybara watir).freeze
      PAGE_OBJECTS = %w(site_prism page-object watirsome watir_drops).freeze

      def initialize(opt = {})
        @gems = {}
        Bundler.definition.dependencies.map(&:name).each do |gem_name|
          @gems[gem_name] = Bundler.environment.specs.to_hash[gem_name].first.version.version
        end

        frameworks = @gems.select { |gem| FRAMEWORKS.include? gem }
        @framework = frameworks.first if frameworks.size == 1

        page_objects = @gems.select { |gem| PAGE_OBJECTS.include? gem }
        @page_object = page_objects.first if page_objects.size == 1

        @name = opt[:name] if opt.key? :name
        @build = opt[:build] if opt.key? :build

        if RSpec.respond_to?(:current_example) && !RSpec.current_example.nil?
          @name ||= RSpec.current_example.full_description
          @location = RSpec.current_example.location
          @harness = ["rspec", @gems["rspec"]]
        elsif @@scenario
          @name ||= @@scenario.source.map(&:name).join(" ")
          @location = @@scenario.location.to_s
          @harness = ["cucumber", @gems["cucumber"]]
        end

        @language = 'Ruby'
        @host_os = ::Selenium::WebDriver::Platform.os
        @version = ::Selenium::WebDriver::Platform.ruby_version
        @ci = ::Selenium::WebDriver::Platform.ci
        @ip = ::Selenium::WebDriver::Platform.ip
      end

      def to_hash
        DATA_PARAMS.each_with_object({}) do |name, hash|
          var = eval("@#{name}")
          hash[name] = var if var
        end
      end
    end
  end
end
