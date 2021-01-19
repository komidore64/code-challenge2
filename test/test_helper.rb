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

require 'securerandom'

class TestHelper
  def self.fixture(filename)
    File.open(File.join(File.dirname(__FILE__), 'fixtures', filename), 'r', &:read)
  end

  def self.generate_resource_data
    t = Time.at(SecureRandom.random_number(1_000_000))
    {
      'id': SecureRandom.hex,
      'source': SecureRandom.alphanumeric,
      'title': SecureRandom.alphanumeric,
      'creation_date': DateTime.parse(t.to_s).new_offset(0).iso8601(6),
      'message': SecureRandom.alphanumeric,
      'tags': SecureRandom.random_number(5).times.each_with_object([]) { |_, col| col << SecureRandom.alphanumeric },
      'author': SecureRandom.alphanumeric
    }
  end
end
