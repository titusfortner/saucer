# frozen_string_literal: true

require 'selenium-webdriver'
require 'saucer/options'
require 'saucer/data_collection'
require 'saucer/asset_management'
require 'saucer/custom_commands'
require 'saucer/job_update'
require 'saucer/runners'
require 'saucer/session'
require 'saucer/platform'
require 'saucer/version'

module Saucer
  class AuthenticationError < StandardError
  end

  class APIError < StandardError
  end
end
