
require File.join(File.dirname(__FILE__), 'autoit')

before = Time.now

ws = AutoIt::Window.wait_exists do |w|
  w.process.name =~ /notepad/
end

ws.each do |w|
  puts w
  puts "-" * 90
  #puts w.children.join("\n" + "c" * 80 + "\n")
end

#puts AutoIt::Window.wait(".process.name =~ /notepad/i", { :timeout => 3 })

=begin
  procs = AutoIt::Process.all
  procs.each_value do |proc|
    puts "#{proc.name}\n#{'-' * 60}\n#{proc.windows.values.join("\n-\n")}\n#{'-' * 60}\n\n"
  end
=end

puts Time.now - before

