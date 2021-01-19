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

require 'json'
require 'net/http'

require 'code_challenge2/logging'
require 'code_challenge2/resource'
require 'code_challenge2/resource_pool'
require 'code_challenge2/processor'
require 'code_challenge2/retry_processor'

module CodeChallenge2
  # Director Class
  #
  # The Director ties all of the object creation, and orchestration together.
  class Director
    include Logging

    ProcessorWithThread = Struct.new(:processor, :thread)

    attr_accessor :max_attempts, :num_processors, :num_retry_processors,
                  :proc_max_startup_seconds, :proc_resource_bucket_size,
                  :resource_max_seconds, :resource_fail_rate

    def initialize
      @max_attempts = 3
      @num_processors = 4
      @num_retry_processors = 1
      @proc_max_startup_seconds = 2
      @proc_resource_bucket_size = 5
      @resource_max_seconds = 7
      @resource_fail_rate = 0.25

      @source_api = '' # TODO: accept a file instead
      @processors_with_threads = []
      @shutdown = false
    end

    def start!
      request_payload
      create_resource_pool
      create_processors(@num_processors, Processor)
      create_processors(@num_retry_processors, RetryProcessor)
      populate_resource_pool_from_payload

      # loop
      monitor_resource_pool_and_processors

      generate_output
    ensure
      kill_processors
    end

    private

    def request_payload
      logger.info("[ Director ]: acquiring payload from: #{@source_api}")
      @raw_payload = Net::HTTP.get(URI(@source_api))
    end

    def create_resource_pool
      logger.debug('[ Director ]: creating resource pool')
      @resource_pool = ResourcePool.new(max_attempts: @max_attempts)
    end

    def create_processors(num_processors, klass, ext_thread: nil)
      num_processors.times do |num|
        processor = klass.new(id: klass.id_template(num), resource_pool: @resource_pool,
                              max_startup_seconds: @proc_max_startup_seconds,
                              resource_bucket_size: @proc_resource_bucket_size)
        logger.debug("[ Director ]: processor [ #{processor.id} ] created")
        thread = ext_thread || processor.start
        @processors_with_threads << ProcessorWithThread.new(processor, thread)
      end
    end

    def populate_resource_pool_from_payload
      hash_resources = JSON.parse(@raw_payload)
      logger.debug("[ Director ]: total number of resources to process: #{hash_resources.size}")
      hash_resources.each_with_index do |hash_res, index|
        res = Resource.new(hash_res.transform_keys(&:to_sym),
                           max_seconds: @resource_max_seconds,
                           fail_rate: @resource_fail_rate)
        logger.info("[ Director ]: adding resource [ #{res.id} ] to pool [ #{index + 1} of #{hash_resources.size} ]")
        @resource_pool.add_resource(res)
        sleep(0.5) # give the processors a chance
      end
      logger.debug('[ Director ]: finished adding resources to the pool')
    end

    def monitor_resource_pool_and_processors
      loop do
        if @resource_pool.needs_processing?
          logger.debug('[ Director ]: there are still resources in the resource pool that require processing')
          sleep(2)
          next
        else
          logger.debug('[ Director ]: there are no more resources in the resource pool that require processing')
          if all_processors_have_empty_buckets?
            logger.debug('[ Director ]: all processors report their resource buckets are empty')
            kill_processors
            break
          else
            logger.debug('[ Director ]: processors still have resources in their possession that require processing')
            sleep(2)
          end
        end
      end
    end

    def generate_output
      completed_resources = @resource_pool.to_hash[:resource_pool]
      filename = 'output.json'

      logger.info("[ Director ]: writing output file: #{filename}")
      File.open(filename, 'w+') do |file|
        file.write(JSON.generate(completed_resources))
      end
    end

    def all_processors_have_empty_buckets?
      @processors_with_threads.map(&:processor).reduce(true) do |col, processor|
        col && processor.resource_bucket_empty?
      end
    end

    def kill_processors
      return if @shutdown

      logger.debug('[ Director ]: shutting down processors')
      @processors_with_threads.each do |struct|
        struct.thread.kill
        sleep(0.5) until struct.thread.status == false
        logger.info("[ Director ]: processor [ #{struct.processor.id} ] terminated")
      end
      @shutdown = true
    end
  end
end
