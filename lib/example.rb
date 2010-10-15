
require File.join(File.dirname(__FILE__), 'autoit')

before = Time.now

wins = AutoIt::Window.wait_exists do |w|
  w.title =~ /Play/
end
wins.first.move(100,100)

#puts AutoIt::Window.wait(".process.name =~ /notepad/i", { :timeout => 3 })

=begin
  procs = AutoIt::Process.all
  procs.each_value do |proc|
    puts "#{proc.name}\n#{'-' * 60}\n#{proc.windows.values.join("\n-\n")}\n#{'-' * 60}\n\n"
  end
=end

puts Time.now - before

