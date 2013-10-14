#!/home/sun/.rvm/rubies/ruby-1.9.3-p448/bin/ruby

$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'net/ssh'
require 'net/scp'
require 'socket'
require 'yaml'
require 'eventmachine'
require 'sysdump'
require 'processdump'

#run mutithread system dump

$list = []
$yml = nil

def init()
  $yml = YAML::load_file('config.yml')
  $yml["ip"].each do |ip|
    $list << ip
  end
end


loop do
  init()
  if $yml['process'] == 1
    puts "start VM dump!"
    process_dump($list)
  else
    puts "start process random dump!"
    dumpVM($list)
  end

  sleep($yml['time'].to_i)

end


