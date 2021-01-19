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

require 'test_helper'
require 'minitest/autorun'

require 'code_challenge2'
require 'code_challenge2/logging'

module CodeChallenge2
  #
  # Processor is a really weird one to test because in its normal running
  # environment, it's just doing its own thing in a loop indefinitely until the
  # thread is told to exit.
  class ProcessorTest < MiniTest::Test
    include Logging

    def setup
      logger.level = :warn
      @respool = ResourcePool.new
      @processor = Processor.new(id: 'proc1', resource_pool: @respool, max_startup_seconds: 0)
    end

    def teardown
      @respool = nil
      @processor = nil
    end

    def test_fill_the_resource_bucket_and_resource_bucket_full
      populate_respool(5)

      @processor.send(:fill_the_resource_bucket)

      assert_equal(5, @processor.instance_variable_get(:@local_resources).size)
      assert(@processor.send(:resource_bucket_full?))
    end

    def test_fill_the_resource_bucket_break_on_nil
      populate_respool(3)

      @processor.send(:fill_the_resource_bucket)

      assert_equal(3, @processor.instance_variable_get(:@local_resources).size)
    end

    def test_process_and_return_local_resources
      populate_respool(5)

      @processor.send(:fill_the_resource_bucket)
      @processor.send(:process_and_return_local_resources)

      assert(@processor.resource_bucket_empty?)
      refute(@respool.needs_processing?)
    end

    def test_return_all_local_resources
      populate_respool(5)

      @processor.send(:fill_the_resource_bucket)
      @processor.send(:return_all_local_resources)

      assert(@processor.resource_bucket_empty?)
      assert(@respool.needs_processing?)
    end

    def test_resource_bucket_empty
      @respool.add_resource(resource)

      assert(@processor.resource_bucket_empty?)
      @processor.send(:fill_the_resource_bucket)
      refute(@processor.resource_bucket_empty?)
    end

    def test_fill_the_resource_bucket_no_available_resources
      @respool.add_resource(resource)
      @processor.send(:fill_the_resource_bucket)

      # process the resource
      @processor.send(:process_and_return_local_resources)

      # ask for more, but there shouldn't be anymore left to process
      @processor.send(:fill_the_resource_bucket)

      assert(@processor.resource_bucket_empty?)
    end

    def populate_respool(num)
      num.times do
        @respool.add_resource(resource)
      end
    end

    def resource
      Resource.new(TestHelper.generate_resource_data, max_seconds: 0, fail_rate: 0)
    end
  end
end
