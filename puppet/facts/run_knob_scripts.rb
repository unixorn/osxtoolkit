#
# Return script values based on contents of /var/puppet/fact_scripts.
# executable files will be run, and if they exit 0, a fact will be created
# named after the script with the fact value set to the last line of the script
# output.
#
# Author: jpb@ooyala.com
#
# Copyright 2009 Ooyala, Inc.
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

def run_script(scriptname)
  script_output = `#{scriptname}`
  # only parse output if script exited 0
  exit_value = $?.exitstatus
  if exit_value == 0
    value = ""
    script_output.each { |line|
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
    return value
  else
    Puppet.warning("#{__FILE__} #{scriptname} failed with exit code #{exit_value}")
    return nil
  end
end

def load_scripts(script_d)
  Puppet.info "#{__FILE__} Loading fact scripts from #{script_d}..."
  if ! File.directory?(script_d)
    Puppet.warning("#{__FILE__} Can't read #{script_d}!")
    return nil
  end
  Dir["#{script_d}/*"].each do |script|
    if File.file?(script)
      if File.executable?(script)
        script_name = script.split('/')[-1]
        Facter.add(script_name) do
          setcode do
            data = run_script(script)
            data
          end
        end
      else
        Puppet.warning("#{__FILE__} Can't execute #{script}!")
      end
    else
      Puppet.warning("#{__FILE__} #{script} not a file")
    end
  end
end

if File.directory?('/etc/knobs/scripts')
  load_scripts('/etc/knobs/scripts')
end
