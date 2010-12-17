#
# Return script values based on contents of /var/puppet/fact_scripts.
# executable files will be run, and if they exit 0, a fact will be created
# named after the script with the fact value set to the last line of the script
# output.
#
# Author: jpb@ooyala.com
#
# Copyright 2009 Ooyala
# License: BSD

def logger(message)
  system("/usr/bin/logger -t scripts_to_facts #{message}")
end

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
    logger("#{scriptname} failed with exit code #{exit_value}")
    return nil
  end
end

def load_scripts(script_d)
  logger "Loading fact scripts from #{script_d}..."
  if ! File.directory?(script_d)
    logger("Can't read #{script_d}!")
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
        logger("Can't execute #{script}!")
      end
    else
      logger("#{script} not a file")
    end
  end
end

load_scripts('/etc/knob_scripts')
