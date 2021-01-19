# frozen_string_literal: true

# code-challenge2
# Copyright (C) 2021  M. Adam Price
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'date'

require 'code_challenge2/logging'

module CodeChallenge2
  # Resource Class
  #
  # This Represents a single resource from the source API.
  class Resource
    UTC_TIMEZONE = 0
    FRACTIONAL_SECONDS = 6 # digits

    include Logging

    attr_reader :processing_attempts

    def initialize(data, max_seconds: 7, fail_rate: 0.25)
      @data = data
      @max_seconds = max_seconds
      @fail_rate = fail_rate

      @processed = false
      @processing_date = nil
      @processing_attempts = 0
    end

    def process
      @processing_attempts += 1
      delay
      set_as_processed if succeeded?

      @processed
    end

    def id
      @data[:id]
    end

    def ==(other)
      return false unless other.respond_to?(:id)

      @data[:id] == other.id
    end

    def eql?(other)
      self == other
    end

    def hash
      @data[:id].hash
    end

    def processed?
      @processed
    end

    def to_hash
      metadata = {
        'processed': processed?,
        'processing_date': @processing_date
      }
      @data.merge(metadata)
    end

    private

    def succeeded?
      success = rand(1..100) >= @fail_rate * 100
      if success
        logger.info("[ #{id} ]: processed successfully")
      else
        logger.info("[ #{id} ]: processing attempt [ #{@processing_attempts} ] failed")
      end
      success
    end

    def delay
      delay_seconds = rand(0..@max_seconds)
      logger.info("[ #{id} ]: will process in [ #{delay_seconds} ] seconds")
      sleep(delay_seconds)
    end

    def set_as_processed
      @processed = true
      @processing_date = DateTime.now.new_offset(UTC_TIMEZONE).iso8601(FRACTIONAL_SECONDS)
    end
  end
end
