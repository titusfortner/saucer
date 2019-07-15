# frozen_string_literal: true

module Saucer
  class DataCollection
    PAGE_OBJECTS = %w[site_prism page-object watirsome watir_drops].freeze

    def gems
      ::Bundler.definition.specs.map(&:name).each_with_object({}) do |gem_name, hash|
        name = ::Bundler.environment.specs.to_hash[gem_name]
        next if name.empty?

        hash[gem_name] = name.first.version
      end
    end

    def page_objects
      page_objects_gems = PAGE_OBJECTS & gems.keys
      if page_objects_gems.size > 1
        'multiple'
      elsif page_objects_gems.empty?
        'unknown'
      else
        page_objects_gems.first
      end
    end

    def selenium_version
      gems['selenium-webdriver']
    end

    def test_library
      if gems['watir'] && gems['capybara']
        'multiple'
      elsif gems['capybara']
        'capybara'
      elsif gems['watir']
        'watir'
      else
        'unknown'
      end
    end

    def test_runner(runner)
      gems[runner.name.to_s] ? "#{runner.name} v#{gems[runner.name.to_s]}" : 'Unknown'
    end
  end
end
