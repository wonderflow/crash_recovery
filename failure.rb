#!/home/sun/.rvm/rubies/ruby-1.9.3-p448/bin/ruby

require 'rubygems'
require 'net/ssh'
require 'net/scp'
require 'socket'

def ssh_exec!(ssh,command)
  stdout_data = ""
  stderr_data = ""
  exit_code = nil
  exit_signal = nil
  ssh.open_channel do |channel|
    channel.exec(command) do |ch,success|
      unless success
        abort "FAILED: couldn't execute command (ssh.channel.exec)"
      end

      channel.on_data do |ch,data|
        stdout_data += data
      end

      channel.on_extended_data do |ch,type,data|
        stderr_data += data
      end

      channel.on_request("exit-status") do |ch,data|
        exit_code = data.read_long
      end

      channel.on_request("exit-signal") do |ch,data|
        exit_signal = data.read_long
      end
    end
  end
  ssh.loop
  [stdout_data, stderr_data, exit_code, exit_signal]
end




ConfigureList = Struct.new(:ip,:timesec)
list = []
$thread = []

File.open("configure","r+") do |file|
  while line = file.gets do
    if(line.strip!="" && line.index("#")==nil)
      ip,time_sec = line.split(" ")
      print "ip: "+ip+" time: "+time_sec+" seconds\n"
      if ip != "" && time_sec !="" 
        list << ConfigureList.new(ip,time_sec)
      end
    end
  end
end

def run(list) 
  puts list.size()
  list.each do |host|
    $thread << Thread.new do
      puts host.ip, host.timesec
      num = 0
      while true do
        begin
          Net::SSH.start(host.ip,'root',:password=>"password",:timeout=>5) do |ssh|
            puts "success to setup. #{host.ip}"
            puts ssh.scp.upload!('sysdump.sh','.')
            ssh.exec("bash sysdump.sh &")
          end
        rescue Timeout::Error
          puts " Connection Time out."
        rescue Errno::ECONNREFUSED
          puts "  Connection refused"
        end
        puts host.ip + "sleeping..."
        sleep(host.timesec.to_i)
      end
    end
  end
end

run(list)
$thread.each {|x| x.join}



# HTTP server
server = TCPServer.new('localhost',2345)

loop do
  socket = server.accept
  request = socket.gets
  STDERR.puts request
  response = "Hello World!\n"
  socket.print "HTTP/1.1 200 OK\r\n" + 
               "Content-Type: text/plain\r\n" + 
               "Content-Length: #{response.bytesize}\r\n" + 
               "Connection: close\r\n"

  socket.print "\r\n"
  socket.print response
  socket.close
end




