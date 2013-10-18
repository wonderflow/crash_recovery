#!/home/sun/.rvm/rubies/ruby-1.9.3-p448/bin/ruby
#
$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'net/ssh'
require 'net/scp'
require 'socket'
require 'yaml'
require 'eventmachine'
require 'sysdump'

def process_dump_thread(host,tp)
  begin
    Net::SSH.start(host,'root',:password=>"password",:timeout=>5) do |ssh|
      puts "success to connect. #{host}"
      path = "/var/vcap/sys/run/"
      str =  ssh.exec!("ls #{path}")
      jobs = str.split.map(&:chomp)
      pid = []
      if jobs[0] != "ls:"
        jobs.each do |job|
          if job == 'nginx'
            pid << '-1'
          else
            pid << ssh.exec!("cat #{path}/#{job}/#{job}.pid").chomp
          end
        end
      end
      if pid.size > 0
        i = tp % pid.size
        if pid[i] != '-1'
          ssh.exec!("kill -9 #{pid[i]}")
        else
          tmp = ssh.exec!("lsof -i:80 | grep nginx | awk '{print $2}'").split
          tmp.each do |num|
            ssh.exec!("kill -9 #{num}")
          end
        end
        puts "host "+host+" : "+jobs[i]+" killed"
      else
        puts "No process in this vm."
      end
    end
  rescue Timeout::Error
    puts " Connection Time out."
  rescue Errno::ECONNREFUSED
    puts " Connection refused"
  end
end


def process_dump(list,num)
  list.each do |host|
    process_dump_thread(host,num)
  end
end



