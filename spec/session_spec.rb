# frozen_string_literal: true

require 'spec_helper'

module Saucer
  describe Session do
    let(:options) { Options.new }
    let(:driver) { instance_double(Selenium::WebDriver::Remote::Driver, session_id: 'job_id', quit: nil) }
    let(:session) { Session.new(driver, options) }

    describe '#new' do
      it 'sets defaults' do
        expect(session.driver).to eq driver
        expect(session.options).to eq options
        expect(session.job_id).to eq 'job_id'
      end

      it 'sets Sauce Whisk data center' do
        session
        expect(SauceWhisk.data_center).to eq :US_WEST
      end
    end

    describe 'custom commands' do
      it 'comments' do
        allow(driver).to receive(:execute_script)
        session.comment = 'Foo'

        expect(driver).to have_received(:execute_script).with('sauce: context=Foo')
      end

      it 'starts and stops network' do
        allow(driver).to receive(:execute_script)

        session.stop_network
        session.start_network

        expect(driver).to have_received(:execute_script).with('sauce: stop network')
        expect(driver).to have_received(:execute_script).with('sauce: start network')
      end

      it 'sets a breakpoint' do
        allow(driver).to receive(:execute_script)

        session.breakpoint
        expect(driver).to have_received(:execute_script).with('sauce: break')
      end
    end

    describe 'api commands' do
      let(:session) { Session.begin }

      describe '#save' do
        let(:job) { instance_double(SauceWhisk::Job) }

        before do
          allow(Selenium::WebDriver).to receive(:for).and_return(driver)
          allow(SauceWhisk::Jobs).to receive(:save)
          allow(SauceWhisk::Jobs).to receive(:fetch).and_return(job)
          allow(job).to receive(:custom_data=)
        end

        it 'sets test name' do
          allow(job).to receive(:name=)

          session.name = 'Test Name'
          session.save

          expect(SauceWhisk::Jobs).to have_received(:save).with(job)
          expect(job).to have_received(:name=).with('Test Name')
        end

        it 'sets build name' do
          allow(job).to receive(:build=)

          session.build = 'Build Name'
          session.save

          expect(SauceWhisk::Jobs).to have_received(:save).with(job)
          expect(job).to have_received(:build=).with('Build Name')
        end

        it 'sets tags' do
          allow(job).to receive(:tags=)

          session.tags = %w[foo bar]
          session.tags << 'foobar'
          session.save

          expect(SauceWhisk::Jobs).to have_received(:save).with(job)
          expect(job).to have_received(:tags=).with(%w[foo bar foobar])
        end

        it 'sets custom data' do
          session.data = {foo: 'bar'}
          session.data[:bar] = 'foo'
          session.save

          expect(SauceWhisk::Jobs).to have_received(:save).with(job)
          expect(job).to have_received(:custom_data=).with(foo: 'bar', bar: 'foo')
        end

        it 'sets visibility' do
          pending 'Not yet supported by SauceWhisk: https://github.com/saucelabs/sauce_whisk/issues/63'

          job = instance_double(SauceWhisk::Job, id: '1234', updated_fields: [:visibility])
          allow(job).to receive(:visibility=)
          allow(job).to receive(:visibility).and_return('public')

          allow(SauceWhisk::Jobs).to receive(:fetch).and_return(job)
          allow(RestClient::Request).to receive(:execute)

          session.visibility = :public
          session.save

          opt = {payload: '{"public":"public"}'}
          expect(RestClient::Request).to have_received(:execute).with(hash_including(opt))
          expect(job).to have_received(:visibility=).with('public')
        end
      end

      context 'with status' do
        before { allow(Selenium::WebDriver).to receive(:for).and_return(driver) }

        it 'sets result' do
          allow(SauceWhisk::Jobs).to receive(:change_status)

          session.result = 'passed'

          expect(SauceWhisk::Jobs).to have_received(:change_status).with('job_id', 'passed')
        end

        it 'stops job' do
          allow(SauceWhisk::Jobs).to receive(:stop)

          session.stop

          expect(SauceWhisk::Jobs).to have_received(:stop).with('job_id')
        end

        it 'raises exception if delete still running job' do
          response = instance_double(RestClient::Response, body: {'error' => "Job hasn't finished running"}.to_json)
          allow(SauceWhisk::Jobs).to receive(:delete_job).with('job_id').and_return(response)

          expect { session.delete }.to raise_error(APIError, "Can not delete job: Job hasn't finished running")
        end

        it 'deletes a stopped job' do
          allow(SauceWhisk::Jobs).to receive(:stop)
          response = instance_double(RestClient::Response, body: {'value' => 'Success'}.to_json)
          allow(SauceWhisk::Jobs).to receive(:delete_job).with('job_id').and_return(response)

          session.stop
          session.delete

          expect(SauceWhisk::Jobs).to have_received(:stop).with('job_id')
          expect(SauceWhisk::Jobs).to have_received(:delete_job).with('job_id')
        end
      end

      context 'with assets' do
        let(:base_path) { File.expand_path('../assets/job_id', __dir__) }
        let(:logs) { "#{base_path}/logs/" }
        let(:screenshots) { "#{base_path}/screenshots/" }
        let(:videos) { "#{base_path}/videos/" }

        before do
          allow(Selenium::WebDriver).to receive(:for).and_return(driver)
          FileUtils.remove_dir(base_path) if File.exist?(base_path)
        end

        it 'saves screenshots' do
          response = instance_double(RestClient::Response, body: 'screenshot')
          screenshot = instance_double(SauceWhisk::Asset, name: 'Foo.png', data: response)
          job = instance_double(SauceWhisk::Job, screenshots: [screenshot, screenshot])

          allow(SauceWhisk::Jobs).to receive(:job_assets).with('job_id').and_return('screenshot_urls' => [])
          allow(SauceWhisk::Jobs).to receive(:fetch).with('job_id').and_return(job)

          session.save_screenshots

          expect(File.read("#{screenshots}/Foo.png")).to eq('screenshot')
        end

        it 'saves selenium log' do
          response = instance_double(RestClient::Response, body: 'Selenium Log Details')
          allow(SauceWhisk::Jobs).to receive(:fetch_asset).with('job_id', 'selenium-server.log').and_return(response)

          session.save_log(log_type: :selenium)
          expect(File.read("#{logs}/selenium.log")).to eq('Selenium Log Details')
        end

        it 'saves automator log' do
          response = instance_double(RestClient::Response, body: 'Automator Log Details')
          allow(SauceWhisk::Jobs).to receive(:fetch_asset).with('job_id', 'automator.log').and_return(response)

          session.save_log(log_type: :automator)
          expect(File.read("#{logs}/automator.log")).to eq('Automator Log Details')
        end

        it 'saves sauce log by default' do
          response = instance_double(RestClient::Response, body: [{'a' => 1}, {'b' => 2}].to_json)
          allow(SauceWhisk::Jobs).to receive(:fetch_asset).with('job_id', 'log.json').and_return(response)

          session.save_log
          expect(File.read("#{logs}/sauce.log")).to eq("a: 1\n\nb: 2")
        end

        it 'rasies exception if invalid log type' do
          msg = 'invalid is not a valid log type; use one of [:sauce, :selenium, :automator]'
          expect { session.save_log(log_type: :invalid) }.to raise_exception(ArgumentError, msg)
        end

        it 'saves all the logs' do
          response1 = instance_double(RestClient::Response, body: [{'a' => 1}, {'b' => 2}].to_json)
          response2 = instance_double(RestClient::Response, body: 'Selenium Log Details')
          response3 = instance_double(RestClient::Response, body: 'Automator Log Details')

          allow(SauceWhisk::Jobs).to receive(:fetch_asset).and_return(response1, response2, response3)

          session.save_logs

          expect(File.read("#{logs}/selenium.log")).to eq('Selenium Log Details')
          expect(File.read("#{logs}/automator.log")).to eq('Automator Log Details')
          expect(File.read("#{logs}/sauce.log")).to eq("a: 1\n\nb: 2")
        end

        it 'saves video' do
          response = instance_double(RestClient::Response, body: 'video')
          allow(SauceWhisk::Jobs).to receive(:fetch_asset).and_return(response)

          session.save_video

          expect(File.read("#{videos}/video.mp4")).to eq('video')
        end

        it 'deletes all assets' do
          response = instance_double(RestClient::Response, body: [].to_json)
          asset = instance_double(SauceWhisk::Asset, data: response)

          allow(SauceWhisk::Assets).to receive(:delete).with('job_id').and_return(asset)

          session.delete_assets
          expect(SauceWhisk::Assets).to have_received(:delete).with('job_id')
        end
      end
    end

    describe '#self.begin' do
      it 'creates a session without options' do
        allow(Time).to receive(:now).and_return('12345')

        allow(Selenium::WebDriver).to receive(:for).and_return(driver)
        default_options = Options.new(name: 'Saucer::Session#self.begin creates a session without options',
                                      build: 'Local Execution - 12345')

        expect(Session.begin).to be_a(Session)

        args = [:remote, {url: default_options.url, desired_capabilities: default_options.capabilities}]
        expect(Selenium::WebDriver).to have_received(:for).with(*args)
      end

      it 'creates a session with options' do
        allow(Selenium::WebDriver).to receive(:for).and_return(driver)
        options = Options.new

        expect(Session.begin(options)).to be_a(Session)

        args = [:remote, {url: options.url, desired_capabilities: options.capabilities}]
        expect(Selenium::WebDriver).to have_received(:for).with(*args)
      end

      it 'creates a session with default data' do
        expected = {page_objects: 'unknown',
                    language: "Ruby v#{Selenium::WebDriver::Platform.ruby_version}",
                    test_runner: "rspec v#{RSpec::Version::STRING}",
                    selenium_version: Bundler.environment.specs.to_hash['selenium-webdriver'].first.version,
                    test_library: 'unknown',
                    operating_system: Selenium::WebDriver::Platform.os}

        job = instance_double(SauceWhisk::Job)
        allow(SauceWhisk::Jobs).to receive(:fetch).and_return(job)
        allow(SauceWhisk::Jobs).to receive(:save).with(job)
        allow(job).to receive(:custom_data=)

        session.save

        expect(job).to have_received(:custom_data=).with(expected)
      end
    end

    describe '#end' do
      it 'fails' do
        exception = instance_double(RuntimeError, inspect: 'inspected', backtrace: %w[1 2])
        job = instance_double(SauceWhisk::Job, end_time: '1')

        allow(RSpec.current_example).to receive(:exception).and_return(exception)
        allow(session).to receive(:save)
        allow(SauceWhisk::Jobs).to receive(:fetch).with('job_id').and_return(job)
        allow(SauceWhisk::Jobs).to receive(:change_status)

        session.end

        expect(SauceWhisk::Jobs).to have_received(:change_status).with('job_id', false)
      end

      it 'passes' do
        job = instance_double(SauceWhisk::Job, end_time: '1')

        allow(RSpec.current_example).to receive(:exception)
        allow(session).to receive(:save)
        allow(SauceWhisk::Jobs).to receive(:fetch).with('job_id').and_return(job)
        allow(SauceWhisk::Jobs).to receive(:change_status)

        session.end

        expect(SauceWhisk::Jobs).to have_received(:change_status).with('job_id', true)
      end

      it 'saves session' do
        job = instance_double(SauceWhisk::Job,
                              updated_fields: %i[custom_data name build],
                              custom_data: {foo: 'bar'},
                              name: 'Test Name',
                              build: 'Build Name',
                              id: 'job_id',
                              end_time: '1')

        allow(SauceWhisk::Jobs).to receive(:fetch).with('job_id').and_return(job)
        allow(SauceWhisk::Jobs).to receive(:change_status)
        allow(SauceWhisk::Jobs).to receive(:put)
        allow(job).to receive(:tags=)
        allow(job).to receive(:custom_data=)

        tags = %w[foo bar]
        session.tags = tags

        session.end

        json = '{"custom-data":{"foo":"bar"},"name":"Test Name","build":"Build Name"}'
        expect(SauceWhisk::Jobs).to have_received(:put).with('job_id', json)
      end

      it 'quits the driver' do
        job = instance_double(SauceWhisk::Job, end_time: '1')
        allow(SauceWhisk::Jobs).to receive(:fetch).with('job_id').and_return(job)
        allow(job).to receive(:custom_data=)
        allow(SauceWhisk::Jobs).to receive(:save).with(job)
        allow(SauceWhisk::Jobs).to receive(:change_status)

        session.end

        expect(session.driver).to have_received(:quit)
      end
    end
  end
end
