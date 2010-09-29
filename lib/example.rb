
require File.join(File.dirname(__FILE__), 'autoit')

before = Time.now

begin

  wins = AutoIt::Window.all.select do |h, w|
    w.process.name =~ /notepad/i
  end

  wins.each do |h, w|
    puts "#{win}\n\n"
    #win.maximize
    #win.minimize
  end
end

#puts AutoIt::Window.wait(".process.name =~ /notepad/i", { :timeout => 3 })

=begin
  procs = AutoIt::Process.all
  procs.each_value do |proc|
    puts "#{proc.name}\n#{'-' * 60}\n#{proc.windows.values.join("\n-\n")}\n#{'-' * 60}\n\n"
  end
=end

puts Time.now - before

