require 'yaml'


d = YAML::load_file('config.yml')

list = []

d["ip"].each do |ip|
  list << ip
end
puts list
