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
  class RetryProcessorTest < MiniTest::Test
    include Logging

    def setup
      logger.level = :warn
      @respool = ResourcePool.new
      @processor = RetryProcessor.new(id: 'retry1', resource_pool: @respool, max_startup_seconds: 0)
    end

    def teardown
      @respool = nil
      @processor = nil
    end

    def test_fill_the_resource_bucket
      res = Resource.new(TestHelper.generate_resource_data, max_seconds: 0, fail_rate: 0)
      res.instance_variable_set(:@processing_attempts, 1)
      @respool.add_resource(res)

      @processor.send(:fill_the_resource_bucket)
      refute(@processor.resource_bucket_empty?)
    end

    def test_fill_the_resource_bucket_no_available_resource
      res = Resource.new(TestHelper.generate_resource_data, max_seconds: 0, fail_rate: 0)
      @respool.add_resource(res)

      @processor.send(:fill_the_resource_bucket)
      assert(@processor.resource_bucket_empty?)
    end
  end
end
