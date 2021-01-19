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
require 'code_challenge2/processor'

module CodeChallenge2
  # RetryProcessor Class
  #
  # The RetryProcessor is identical to the Processor class except for it only
  # desires resources which have been attempted at least once.
  class RetryProcessor < Processor
    include Logging

    def self.id_template(id)
      "proc-#{id}-retry"
    end

    def ask_for_resource
      @resource_pool.request_resource do |res|
        res.processing_attempts.positive?
      end
    end
  end
end
