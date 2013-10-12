#!/home/sun/.rvm/rubies/ruby-1.9.3-p448/bin/ruby

$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'net/ssh'
require 'net/scp'
require 'socket'
require 'netsshex.rb'
require 'yaml'
require 'eventmachine'

#run mutithread system dump

ConfigureList = Struct.new(:ip,:timesec)
list = []

yml = YAML::load_file('config.yml')

yml["ip"].each do |ip|
  list << ip
end

def thread_process(host)
  begin
    Net::SSH.start(host,'root',:password=>"password",:timeout=>5) do |ssh|
      puts "success to setup. #{host}"
      puts ssh.scp.upload!('sysdump.sh','.')
      ssh.exec("bash sysdump.sh &")
    end
  rescue Timeout::Error
    #puts " Connection Time out."
  rescue Errno::ECONNREFUSED
    #puts "  Connection refused"
  end
  #puts host + " sleeping..."
end

def heartbeat_test(host)
  puts host+" hearbeat..."
  num = 0;
  begin
    Timeout::timeout(3){
      TCPSocket.new(host,22)
    }
  rescue Timeout::Error
    num = 1
    puts host+" timed out. Thread killed."
  end
  return num
end


$flag = 1;

loop do

  EM.run do
    EM.defer do
      thread = []
      puts list.size()
      list.each do |host|
        thread << Thread.new{ thread_process(host) }
      end
      thread.each do |s|
        s.join
      end
    end
    EM.add_periodic_timer(2) do
      num = 0
      list.each do |host|
        num += heartbeat_test(host)
      end
      puts "heartbeats "+num.to_s
      if num == list.size()
        puts "new loop begain"
        EM.stop
      end
    end
  end

  sleep(yml['time'].to_i)

end


