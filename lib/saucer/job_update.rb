# frozen_string_literal: true

module Saucer
  module JobUpdate
    def name=(name)
      job.name = name
    end

    def build=(name)
      job.build = name
    end

    def visibility=(value)
      valid = %i[public public_restricted share team private]
      raise ArgumentError, "#{value} is not a valid visibility value; use one of #{valid}" unless valid.include?(value)

      job.visibility = value.to_s
    end

    def save
      job.tags = tags unless tags.empty?
      job.custom_data = data unless data.empty?
      SauceWhisk::Jobs.save(job)
    end
  end
end
