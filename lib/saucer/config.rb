module Saucer
  class Config

    def initialize(opt = {})
      ENV['SAUCE_USERNAME'] = opt[:username] if opt.key?(:username)
      ENV['SAUCE_ACCESS_KEY'] = opt[:access_key] if opt.key(:access_key)
    end

    def url
      "https://#{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']}@ondemand.saucelabs.com:443/wd/hub"
    end

    def opts
      {url: url, desired_capabilities: capabilities}
    end

    def capabilities
      {browser_name: :chrome}
    end
  end
end
