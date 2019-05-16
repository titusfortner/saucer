# frozen_string_literal: true

module Saucer
  module CustomCommands
    def comment=(comment)
      @driver.execute_script("sauce: context=#{comment}")
    end

    def stop_network
      @driver.execute_script('sauce: stop network')
    end

    def start_network
      @driver.execute_script('sauce: start network')
    end

    def breakpoint
      @driver.execute_script('sauce: break')
    end
  end
end
