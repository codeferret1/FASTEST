
require File.join(File.dirname(__FILE__), 'autoit')

before = Time.now

begin
wins = AutoIt::Window.all

wins.where(".process.name =~ /notepad/i").each_value do |win|
  puts "#{win}\n\n"
  #win.maximize
  #win.minimize
end
end

#puts AutoIt::Window.wait(".process.name =~ /notepad/i", { :timeout => 3 })

=begin
procs = AutoIt::Process.all
procs.each do |proc|
  puts "#{proc.name}\n#{'-' * 60}\n#{proc.windows.join("\n-\n")}\n#{'-' * 60}\n\n"
end
=end

puts Time.now - before

