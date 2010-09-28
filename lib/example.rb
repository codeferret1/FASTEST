
require File.join(File.dirname(__FILE__), 'autoit')

before = Time.now

begin
wins = AutoIt::Window.all

=begin
wins.where(".process.name =~ /notepad/i").each_value do |win|
  puts "#{win}\n\n"
  #win.maximize
  #win.minimize
end
=end
end

#puts AutoIt::Window.wait(".process.name =~ /notepad/i", { :timeout => 3 })

procs = AutoIt::Process.all
procs.each_value do |proc|
  puts "#{proc.name}\n#{'-' * 60}\n#{proc.windows.values.join("\n-\n")}\n#{'-' * 60}\n\n"
end

puts Time.now - before

