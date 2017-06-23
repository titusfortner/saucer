module Saucer
  module Annotations

    def comment=(comment)
      driver.execute_script("sauce:context=#{comment}")
    end

    def job_result=(result)
      raise ArgumentError, "invalid value for result" unless ['passed', 'failed', true, false].include?(result)
      driver.execute_script("sauce:job-result=#{result}")
    end

    def job_name=(name)
      driver.execute_script("sauce:job-name=#{name}")
    end

    def job_tags=(tags)
      tags = tags.join(',') if tags.is_a?(Array)
      driver.execute_script("sauce:job-tags=#{tags}")
    end

    def job_info=(info)
      raise ArgumentError, "job info must be JSON" unless info.is_a? JSON
      driver.execute_script("sauce:job-info=#{info}")
    end

    def build_name=(name)
      driver.execute_script("sauce:job-build=#{name}")
    end

    def stop_vm
      driver.execute_script("sauce: stop network")
    end

    def start_vm
      driver.execute_script("sauce: start network")
    end

    def breakpoint
      driver.execute_script("sauce: break")
    end

  end
end
