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
  class ResourceTest < MiniTest::Test
    include Logging

    def setup
      logger.level = :warn
    end

    def teardown; end

    def test_process_success
      expected_attempts = 1

      res = Resource.new(TestHelper.generate_resource_data, fail_rate: 0, max_seconds: 0)

      assert(res.process)
      assert_equal(expected_attempts, res.processing_attempts)
      assert(res.processed?)
    end

    def test_process_failure
      expected_attempts = 1

      res = Resource.new(TestHelper.generate_resource_data, fail_rate: 1, max_seconds: 0)

      refute(res.process)
      assert_equal(expected_attempts, res.processing_attempts)
      refute(res.processed?)
    end

    def test_timed_processing_success
      max_seconds = 3
      res = Resource.new(TestHelper.generate_resource_data, fail_rate: 0, max_seconds: max_seconds)

      start = DateTime.now.new_offset(0).to_time.to_i
      res.process
      assert_in_delta(DateTime.parse(res.instance_variable_get(:@processing_date)).to_time.to_i, start, max_seconds)
    end

    def test_unequal
      res = Resource.new(TestHelper.generate_resource_data, fail_rate: 0, max_seconds: 0)
      diff_res = Resource.new(TestHelper.generate_resource_data, fail_rate: 0, max_seconds: 0)
      refute_equal(res, diff_res)
    end

    def test_to_hash
      data = TestHelper.generate_resource_data
      expected_hash = {
        processed: false,
        processing_date: nil
      }.merge(data)

      res_hash = Resource.new(data, fail_rate: 0, max_seconds: 0).to_hash
      assert_equal(expected_hash, res_hash)
    end
  end
end
