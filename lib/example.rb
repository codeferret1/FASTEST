
require File.join(File.dirname(__FILE__), 'autoit')

before = Time.now

w = AutoIt::Window.wait_exists do |w|
  w.title =~ /Play/
end.first

p = w.size
p.w += 200
p.h += 50
w.resize(p)

#puts AutoIt::Window.wait(".process.name =~ /notepad/i", { :timeout => 3 })

=begin
  procs = AutoIt::Process.all
  procs.each_value do |proc|
    puts "#{proc.name}\n#{'-' * 60}\n#{proc.windows.values.join("\n-\n")}\n#{'-' * 60}\n\n"
  end
=end

puts Time.now - before

