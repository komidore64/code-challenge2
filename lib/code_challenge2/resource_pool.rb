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

require 'code_challenge2/logging'
require 'code_challenge2/resource'

module CodeChallenge2
  # ResourcePool
  #
  # The ResourcePool class contains all the Resources that are not currently in
  # possession of a Processor. The ResourcePool uses a mutex lock any time its
  # internal pool is accessed to maintain thread safety.
  #
  # The number of process attempts made on a Resource is configurable.
  class ResourcePool
    include Logging

    def initialize(max_attempts: 3)
      @max_attempts = max_attempts

      @pool = []
      @lock = Mutex.new
    end

    def add_resource(res)
      raise 'Object given is not a Resource.' unless res.instance_of?(Resource)

      logger.info("[ ResourcePool ]: received resource [ #{res.id} ]")
      @lock.synchronize do
        @pool << res
      end
    end

    def request_resource(&block)
      block = proc { |_| true } unless block_given? # basic default

      @lock.synchronize do
        res = resources_to_process.select { |r| block.call(r) }.pop
        if res.nil?
          logger.debug('[ ResourcePool ]: no resources to hand out')
          return nil
        end
        logger.info("[ ResourcePool ]: handing out resource [ #{res.id} ]")
        @pool.delete(res)
      end
    end

    def needs_processing?
      @lock.synchronize do
        resources_to_process.size.positive?
      end
    end

    def to_hash
      { resource_pool: @pool.map(&:to_hash) }
    end

    private

    def resources_to_process
      @pool.select { |res| !res.processed? && res.processing_attempts < @max_attempts }
    end
  end
end
