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
  class ResourcePoolTest < MiniTest::Test
    include Logging

    def setup
      logger.level = :warn
      @respool = ResourcePool.new
      @res = Resource.new(TestHelper.generate_resource_data, max_seconds: 0, fail_rate: 0)
    end

    def teardown
      @respool = nil
      @res = nil
    end

    def test_add_resource
      expected_size = 1
      assert_empty(@respool.instance_variable_get(:@pool))
      @respool.add_resource(@res)
      assert_equal(expected_size, @respool.instance_variable_get(:@pool).size)
    end

    def test_request_resource
      @respool.instance_variable_set(:@pool, [@res])

      retobj = @respool.request_resource
      assert_same(@res, retobj)

      # the pool should now be empty
      assert_equal(0, @respool.instance_variable_get(:@pool).size)
      assert_nil(@respool.request_resource)
    end

    def test_needs_processing
      @respool.instance_variable_set(:@pool, [@res])

      assert(@respool.needs_processing?)
    end

    def test_needs_processing_empty
      refute(@respool.needs_processing?)
    end

    def test_needs_processing_all_done
      @res.process
      @respool.instance_variable_set(:@pool, [@res])
      refute(@respool.needs_processing?)
    end

    def test_to_hash
      @respool.add_resource(@res)
      expected_hash = { resource_pool: [@res.to_hash] }

      assert_equal(expected_hash, @respool.to_hash)
    end
  end
end
