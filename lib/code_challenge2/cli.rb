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

require 'optparse'
require 'code_challenge2/logging'
require 'code_challenge2/director'

module CodeChallenge2
  # CLI class
  #
  # CLI defines the command-line interface for running the program.
  class CLI
    include Logging

    def initialize
      @options = {
        max_attempts: 3,
        num_processors: 4,
        num_retry_processors: 1,
        proc_max_startup_seconds: 2,
        proc_resource_bucket_size: 5,
        resource_max_seconds: 7,
        resource_fail_rate: 0.25,
        log_level: :info,
        dry_run: false
      }
    end

    def parse!(input_arr: ARGV)
      optparse = OptionParser.new do |opts|
        opts.banner = 'USAGE: code-challenge2 [OPTIONS] INPUTFILE'
        opts.version = "0.0.1 Copyright (C) #{Time.now.year} M. Adam Price"

        define_max_attempts_option(opts)
        define_num_processors_option(opts)
        define_num_retry_processors_option(opts)
        define_processor_max_startup_time_option(opts)
        define_processor_bucket_size_option(opts)
        define_resource_max_process_time_option(opts)
        define_resource_fail_rate_option(opts)
        define_log_level_option(opts)
        define_dry_run_option(opts)
      end

      optparse.parse!(input_arr)

      @input_path = input_arr.pop
      raise 'Need to specify an input file.' unless @input_path
    end

    def jack_in
      log_level = @options[:dry_run] ? :debug : @options[:log_level]
      logger.level = log_level

      logger.debug('!!! DRY RUN INITIATED !!!') if @options[:dry_run]
      logger.debug('received options:')
      @options.each { |key, val| logger.debug("\t#{key}: #{val}") }
      return if @options[:dry_run]

      logger.info('creating director')
      director = create_director

      director.start!
    end

    private

    def create_director
      dir = Director.new
      dir.max_attempts = @options[:max_attempts]
      dir.num_processors = @options[:num_processors]
      dir.num_retry_processors = @options[:num_retry_processors]
      dir.proc_max_startup_seconds = @options[:proc_max_startup_seconds]
      dir.proc_resource_bucket_size = @options[:proc_resource_bucket_size]
      dir.resource_max_seconds = @options[:resource_max_seconds]
      dir.resource_fail_rate = @options[:resource_fail_rate]
      dir.input_path = @input_path
      dir
    end

    def define_max_attempts_option(opts)
      opts.on('--max-attempts ATTEMPTS',
              Integer,
              'Maximum times to attempt processing a single',
              'resource before considering it unprocessable.',
              "(default: #{@options[:max_attempts]})") do |attempts|
        raise OptionParser::InvalidArgument, 'Value must be greater than zero.' unless attempts.positive?

        @options[:max_attempts] = attempts
      end
    end

    def define_num_processors_option(opts)
      opts.on('--processors PROCESSORS',
              Integer,
              'Number of processors to create.',
              "(default: #{@options[:num_processors]})") do |processors|
        raise OptionParser::InvalidArgument, 'Value must be greater than zero.' unless processors.positive?

        @options[:num_processors] = processors
      end
    end

    def define_num_retry_processors_option(opts)
      opts.on('--retry-processors PROCESSORS',
              Integer,
              'Number of retry processors to create.',
              "(default: #{@options[:num_retry_processors]})") do |retry_processors|
        raise OptionParser::InvalidArgument, 'Value must be greater than zero.' unless retry_processors.positive?

        @options[:num_retry_processors] = retry_processors
      end
    end

    def define_processor_max_startup_time_option(opts)
      opts.on('--max-startup-time SECONDS',
              Integer,
              'Set the maximum time it can take a processor to',
              'startup after filling its bucket of resources.',
              "(default: #{@options[:proc_max_startup_seconds]})") do |seconds|
        raise OptionParser::InvalidArgument, 'Value must be greater than zero.' unless seconds.positive?

        @options[:proc_max_startup_seconds] = seconds
      end
    end

    def define_processor_bucket_size_option(opts)
      opts.on('--bucket-size COUNT',
              Integer,
              'Set the size of processor resource buckets.',
              "(default: #{@options[:proc_resource_bucket_size]})") do |size|
        raise OptionParser::InvalidArgument, 'Value must be greater than zero.' unless size.positive?

        @options[:proc_resource_bucket_size] = size
      end
    end

    def define_resource_max_process_time_option(opts)
      opts.on('--max-process-time SECONDS',
              Integer,
              'Set the maximum amount of time a resource can take',
              'to process.',
              "(default: #{@options[:resource_max_seconds]})") do |seconds|
        raise OptionParser::InvalidArgument, 'Value must be greater than zero.' unless seconds.positive?

        @options[:resource_max_seconds] = seconds
      end
    end

    def define_resource_fail_rate_option(opts)
      opts.on('--fail-rate FAIL_RATE',
              Float,
              'Set the rate at which a resource will fail to',
              'process. [0.0 to 1.0 inclusive]',
              "(default: #{@options[:resource_fail_rate]})") do |rate|
        raise OptionParser::InvalidArgument, 'Value must be between 0 and 1, inclusive.' if rate.negative? || rate > 1

        @options[:resource_fail_rate] = rate
      end
    end

    def define_log_level_option(opts)
      opts.on('-l', '--log-level LEVEL',
              %i[debug info warn],
              'Set the log level. [debug, info, warn]',
              "(default: #{@options[:log_level]})") do |level|
        @options[:log_level] = level
      end
    end

    def define_dry_run_option(opts)
      opts.on('--dry-run',
              'Parse all arguments, describe what we would have',
              'done then exit.') do
        @options[:dry_run] = true
      end
    end
  end
end
