require "spec_helper"

module Saucer
  describe Session do
    let(:options) { Options.new }
    let(:driver) { instance_double(Selenium::WebDriver::Remote::Driver, session_id: '1') }
    let(:session) { Session.new(driver, options) }

    describe '#new' do
      it 'sets defaults' do
        expect(session.driver).to eq driver
        expect(session.options).to eq options
        expect(session.job_id).to eq '1'
      end

      it 'sets Sauce Whisk data center' do
        session
        expect(SauceWhisk.data_center).to eq :US_WEST
      end
    end

    describe 'custom commands' do
      it 'comments' do
        allow(driver).to receive(:execute_script)
        session.comment = "Foo"

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

    end

    describe '#self.start' do
      it 'creates a session' do
        allow(Selenium::WebDriver).to receive(:for).and_return(driver)
        session = Session.start(options)

        expect(session).to be_a(Session)

        args =[:remote, {url: options.url, desired_capabilities: options.capabilities}]
        expect(Selenium::WebDriver).to have_received(:for).with(*args)
      end
    end
  end
end