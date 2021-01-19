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

# this is picky with ordering
require 'webmock'
include WebMock::API
WebMock.enable!

require 'test_helper'
require 'minitest/autorun'
require 'minitest/mock'

require 'code_challenge2'
require 'code_challenge2/logging'

module CodeChallenge2
  class DirectorTest < MiniTest::Test
    include Logging

    def setup
      logger.level = :warn
      @director = Director.new
    end

    def teardown
      @director = nil
    end

    def test_request_payload
      expected_response = TestHelper.fixture('payload.json')
      stub_request(:get, @director.instance_variable_get(:@source_api)).to_return(body: expected_response)

      @director.send(:request_payload)
      assert_equal(expected_response, @director.instance_variable_get(:@raw_payload))
    end

    def test_create_resource_pool
      @director.send(:create_resource_pool)
      refute_nil(@director.instance_variable_get(:@resource_pool))
    end

    def test_create_processors
      mock_thread = MiniTest::Mock.new
      @director.send(:create_resource_pool)

      assert_empty(@director.instance_variable_get(:@processors_with_threads))
      add_processors(@director, mock_thread)
      assert_equal(@director.instance_variable_get(:@num_processors),
                   @director.instance_variable_get(:@processors_with_threads).size)
    end

    def test_create_retry_processors
      mock_thread = MiniTest::Mock.new
      @director.send(:create_resource_pool)

      assert_empty(@director.instance_variable_get(:@processors_with_threads))
      add_retry_processors(@director, mock_thread)
      assert_equal(@director.instance_variable_get(:@num_retry_processors),
                   @director.instance_variable_get(:@processors_with_threads).size)
    end

    def test_populate_resource_pool_from_payload
      @director.instance_variable_set(:@raw_payload, TestHelper.fixture('payload.json'))
      @director.send(:create_resource_pool)
      respool = @director.instance_variable_get(:@resource_pool)

      assert_empty(respool.instance_variable_get(:@pool))
      @director.send(:populate_resource_pool_from_payload)
      refute_empty(respool.instance_variable_get(:@pool))
    end

    def test_monitor_resource_pool_and_processors
      mock_thread = MiniTest::Mock.new
      5.times do
        mock_thread.expect(:kill, true, [])
        mock_thread.expect(:status, false, [])
      end
      @director.send(:create_resource_pool)
      add_processors(@director, mock_thread)
      add_retry_processors(@director, mock_thread)

      @director.send(:monitor_resource_pool_and_processors)
      assert(@director.instance_variable_get(:@shutdown))
      mock_thread.verify
    end

    def test_kill_processors
      mock_thread = MiniTest::Mock.new
      5.times do
        mock_thread.expect(:kill, true, [])
        mock_thread.expect(:status, false, [])
      end
      @director.send(:create_resource_pool)
      add_processors(@director, mock_thread)
      add_retry_processors(@director, mock_thread)

      @director.send(:kill_processors)
      assert(@director.instance_variable_get(:@shutdown))
      mock_thread.verify
    end

    def test_all_processors_have_empty_buckets
      mock_thread = MiniTest::Mock.new
      @director.send(:create_resource_pool)
      add_processors(@director, mock_thread)
      add_retry_processors(@director, mock_thread)

      assert(@director.send(:all_processors_have_empty_buckets?))
    end

    def test_generate_output
      skip 'mocks and stubs are the worst'
      @director.send(:create_resource_pool)
      respool = @director.instance_variable_get(:@resource_pool)
      resource = Resource.new(TestHelper.generate_resource_data, max_seconds: 0, fail_rate: 0)
      respool.add_resource(resource)
      expected_file_contents = JSON.generate(respool.to_hash[:resource_pool])

      file_open_args = lambda do |filename, mode|
        assert_equal('output.json', filename)
        assert_equal('w+', mode)
      end

      file_mock = MiniTest::Mock.new
      file_mock.expect(:write, nil, [expected_file_contents])
      File.stub(:open, file_open_args, file_mock) do
        @director.send(:generate_output)
      end
      file_mock.verify
    end

    def add_processors(dir, mock_thread)
      dir.send(:create_processors,
               dir.instance_variable_get(:@num_processors),
               Processor,
               ext_thread: mock_thread)
    end

    def add_retry_processors(dir, mock_thread)
      dir.send(:create_processors,
               dir.instance_variable_get(:@num_retry_processors),
               RetryProcessor,
               ext_thread: mock_thread)
    end
  end
end
