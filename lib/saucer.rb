# frozen_string_literal: true

require 'selenium-webdriver'
require 'saucer/options'
require 'saucer/session'
require 'saucer/version'

module Saucer
  class AuthenticationError < StandardError
  end

  class APIError < StandardError
  end
end
