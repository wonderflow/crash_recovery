$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'net/ssh'
require 'net/scp'
require 'socket'
require 'yaml'
require 'eventmachine'

def vm_dump_thread(host)
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

def dumpVM(list)
  EM.run do
    EM.defer do
      thread = []
      puts list.size()
      list.each do |host|
        thread << Thread.new{ vm_dump_thread(host) }
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
end


