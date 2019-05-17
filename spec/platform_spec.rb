# frozen_string_literal: true

require 'spec_helper'

module Saucer
  describe Platform do
    describe 'Sets values from ENV' do
      after { ENV.delete('PLATFORM') }

      it 'mac_13_safari_12' do
        ENV['PLATFORM'] = 'mac_13_safari_12'
        option = Options.new

        expect(option.browser_name).to eq 'safari'
        expect(option.platform_name).to eq 'Mac 10.13'
        expect(option.browser_version).to eq '12'
      end

      it 'mac_11_chrome_34' do
        ENV['PLATFORM'] = 'mac_11_chrome_34'
        option = Options.new

        expect(option.browser_name).to eq 'chrome'
        expect(option.platform_name).to be_nil
        expect(option.browser_version).to be_nil
        expect(option.remaining[:platform]).to eq('Mac 10.11')
        expect(option.remaining[:version]).to eq('34')
      end

      it 'does not interfere with additional values' do
        ENV['PLATFORM'] = 'mac_13_safari_12'
        option = Options.new(accept_insecure_certs: false, video_upload_on_pass: false)

        expect(option.browser_name).to eq 'safari'
        expect(option.platform_name).to eq 'Mac 10.13'
        expect(option.browser_version).to eq '12'
        expect(option.accept_insecure_certs).to eq false
        expect(option.video_upload_on_pass).to eq false
      end
    end
  end
end
