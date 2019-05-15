# frozen_string_literal: true

require 'spec_helper'

module Saucer
  describe Options do
    let(:options) { Options.new }

    describe '#new' do
      it 'generates username and password from ENV by default' do
        expect(options.username).to eq ENV['SAUCE_USERNAME']
        expect(options.access_key).to eq ENV['SAUCE_ACCESS_KEY']
      end

      it 'specifies latest Selenium Server version by default' do
        expect(options.selenium_version).to eq '3.141.59'
      end

      it 'specifies url by default' do
        expect(options.url).to eq 'https://ondemand.saucelabs.com:443/wd/hub'
      end

      it 'uses default browser name, version and platform name' do
        expect(options.browser_name).to eq 'firefox'
        expect(options.browser_version).to eq 'latest'
        expect(options.platform_name).to eq 'Windows 10'
      end

      context 'when sauce environment variables are not set' do
        it 'for SAUCE_USERNAME' do
          username = ENV['SAUCE_USERNAME']
          ENV.delete('SAUCE_USERNAME')

          msg = "No valid username found; either pass the value into `Options#new` or set with ENV['SAUCE_USERNAME']"
          expect { options }.to raise_error(AuthenticationError, msg)

          ENV['SAUCE_USERNAME'] = username
        end

        it 'for SAUCE_ACCESS_KEY' do
          access_key = ENV['SAUCE_ACCESS_KEY']
          ENV.delete('SAUCE_ACCESS_KEY')

          msg = 'No valid access key found; '\
"either pass the value into `Options#new` or set with ENV['SAUCE_ACCESS_KEY']"
          expect { options }.to raise_error(AuthenticationError, msg)

          ENV['SAUCE_ACCESS_KEY'] = access_key
        end
      end

      it 'overrides default values' do
        opts = {username: 'foo',
                access_key: 'bar',
                selenium_version: '2',
                url: 'https://example.com',
                browser_name: 'Foo',
                browser_version: '1',
                platform_name: 'invalid'}
        options = Options.new(opts)

        opts.each do |key, value|
          expect(options.send(key)).to eq value
        end
      end

      it 'accepts w3c values' do
        opts = {max_duration: 1, name: 'foo', parent_tunnel: 'bar', passed: true}
        options = Options.new(opts)

        opts.each do |key, value|
          expect(options.send(key)).to eq value
        end
      end

      it 'accepts sauce values' do
        opts = {accept_insecure_certs: true, page_load_strategy: 'eager', strict_file_interactability: false}
        options = Options.new(opts)

        opts.each do |key, value|
          expect(options.send(key)).to eq value
        end
      end
    end

    describe '#data_center' do
      it 'defaults to US West' do
        expect(options.data_center).to eq(:US_WEST)
      end

      it 'sets specified value' do
        options.data_center = :EU_VDC
        expect(options.data_center).to eq(:EU_VDC)
      end

      it 'raises Exception if value is incorrect' do
        expect { options.data_center = :INVALID }.to raise_error(ArgumentError, /INVALID is an invalid data center/)
      end
    end

    describe '#capabilities' do
      it 'sets default values' do
        expected = {browser_name: 'firefox',
                    browser_version: 'latest',
                    platform_name: 'Windows 10',
                    'sauce:options' => {username: ENV['SAUCE_USERNAME'],
                                        access_key: ENV['SAUCE_ACCESS_KEY'],
                                        selenium_version: '3.141.59'}}

        expect(options.capabilities).to eq expected
      end
    end
  end
end
