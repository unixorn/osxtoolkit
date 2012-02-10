#
# fact returns knob values based on contents of /etc/knobs.
#
# Author: jpb@ooyala.com
#
# Copyright 2009-2012 Ooyala, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# facts can only have one value. Ignore lines with shell style comments,
# and return the last valid line.

require 'puppet'

def read_knob(filename)
  knob_name = filename.split('/')[-1]
  knob_file = File.open(filename)
  value = nil
  knob_file.each { |line|
    if line[0,1] != "#"
      if (line.downcase.chomp == "true") or (line.downcase.chomp == "t")
        value = true
      elsif (line.downcase.chomp == "false") or (line.downcase.chomp == "f")
        value = false
      else
        value = line.chomp
      end
    end
  }
  knob_file.close

  # an empty knob file must have been created for a reason, so set default
  # value to true - an empty file might just have a single newline so check
  # for non-whitespace characters and assume whitespace only means true
  if value.nil? or (value.is_a?(String) and value.match(/\S/).nil?)
    value = true
  end

  return value
end

def load_knobs(knob_d)
  if ! File.directory?(knob_d)
    return nil
  end

  Dir["#{knob_d}/*"].each do |knob|
    if File.file?(knob)
      if File.readable?(knob)
        knob_name = knob.split('/')[-1]
        Facter.add("#{knob_name}") do
          setcode do
            data = read_knob(knob)
          end
        end
      end
    end
  end
end

if File.directory?('/etc/knobs')
  load_knobs('/etc/knobs')
end

