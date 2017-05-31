require 'sauce_whisk'

module Saucer
  module API

    def jobs
      SauceWhisk::Jobs
    end

    def assets
      SauceWhisk::Assets
    end

    def accounts
      SauceWhisk::Accounts
    end

    def tunnels
      SauceWhisk::Tunnels.all
    end

    def job
      jobs.fetch(@driver.session_id)
    end

    def account
      accounts.fetch(@config.username)
    end

    def concurrency
      accounts.concurrency_for(@config.username)
    end

    def tunnel(id)
      tunnels.fetch(id)
    end

    def platforms
      SauceWhisk::Sauce.platforms
    end

    def storage
      @storage ||= SauceWhisk::Storage.new
    end

    def service_status
      SauceWhisk::Sauce.service_status
    end

    def total_job_count
      SauceWhisk::Sauce.total_job_count
    end
  end
end
