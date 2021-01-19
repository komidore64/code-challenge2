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

module CodeChallenge2
  # Processor Class
  #
  # The Processor runs in its own thread, looping infinitely asking the
  # ResourcePool for any Resources that need processing. The loop will break
  # once the thread receives `kill()` from the Director.
  #
  # The Processor's local resources are guarded with a mutex due to the
  # possibility that other threads (main from the Director) asking the
  # Processor for its bucket status.
  class Processor
    include Logging

    attr_reader :id

    def self.id_template(id)
      "proc-#{id}"
    end

    def initialize(id:, resource_pool:, max_startup_seconds: 2, resource_bucket_size: 5)
      @id = id
      @resource_pool = resource_pool
      @max_startup_seconds = max_startup_seconds
      @resource_bucket_size = resource_bucket_size

      @local_resources = []
      @lock = Mutex.new
    end

    def start
      logger.info("[ #{@id} ]: started!")
      Thread.start { run! }
    end

    def resource_bucket_empty?
      @lock.synchronize do
        @local_resources.empty?
      end
    end

    private

    def run!
      loop do
        run_single
      end
    ensure
      return_all_local_resources
      logger.info("[ #{@id} ]: terminating ...")
    end

    def run_single
      fill_the_resource_bucket
      startup_delay unless resource_bucket_empty?
      process_and_return_local_resources
    end

    def fill_the_resource_bucket
      until resource_bucket_full?
        logger.info("[ #{@id} ]: requesting resource...")
        res = ask_for_resource
        break if res.nil?

        place_resource_into_local_bucket(res)
      end
    end

    def startup_delay
      delay_seconds = rand(0..@max_startup_seconds)
      logger.info("[ #{@id} ]: completing startup in [ #{delay_seconds} ] seconds")
      sleep(delay_seconds)
    end

    def process_and_return_local_resources
      return_all_local_resources(process: true)
    end

    def return_all_local_resources(process: false)
      sleep(2) and return if resource_bucket_empty? # slow down empty processors hammering the pool

      until resource_bucket_empty?
        res = resource_from_local_bucket
        process_resource(res) if process
        return_resource(res)
      end
    end

    def resource_bucket_full?
      @lock.synchronize do
        @local_resources.size == @resource_bucket_size
      end
    end

    def ask_for_resource
      @resource_pool.request_resource do |res|
        res.processing_attempts.zero?
      end
    end

    def resource_from_local_bucket
      @lock.synchronize do
        @local_resources.pop
      end
    end

    def place_resource_into_local_bucket(res)
      logger.info("[ #{@id} ]: acquired resource [ #{res.id} ]")
      @lock.synchronize do
        @local_resources << res
      end
    end

    def process_resource(res)
      logger.info("[ #{@id} ]: processing resource [ #{res.id} ]")
      res.process
    end

    def return_resource(res)
      logger.info("[ #{@id} ]: returning resource [ #{res.id} ] to resource pool")
      @resource_pool.add_resource(res)
    end
  end
end
