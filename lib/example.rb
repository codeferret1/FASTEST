
require File.join(File.dirname(__FILE__), 'autoit')

before = Time.now

w = AutoIt::Window.match_by_title_and_text(/Play/, //)
puts w.inspect

p = AutoIt::Process.find_by_pid(0)
puts p.inspect

#puts AutoIt::Window.wait(".process.name =~ /notepad/i", { :timeout => 3 })

=begin
  procs = AutoIt::Process.all
  procs.each_value do |proc|
    puts "#{proc.name}\n#{'-' * 60}\n#{proc.windows.values.join("\n-\n")}\n#{'-' * 60}\n\n"
  end
=end

puts Time.now - before

