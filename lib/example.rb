
require File.join(File.dirname(__FILE__), 'autoit')

before = Time.now

ws = AutoIt::Window.wait_exists do |w|
  w.process.name =~ /notepad/i 
end

def print_tree (w, level = 0)
  puts " " * level + "[#{w.handle.to_s(16)}] [#{w.title.strip}] [#{w.class}]"
  w.children.each do |c|
    print_tree(c, level + 2)
  end
end

ws.each do |w|
  next unless w.top_level?
  print_tree(w)
end

#puts AutoIt::Window.wait(".process.name =~ /notepad/i", { :timeout => 3 })

=begin
  procs = AutoIt::Process.all
  procs.each_value do |proc|
    puts "#{proc.name}\n#{'-' * 60}\n#{proc.windows.values.join("\n-\n")}\n#{'-' * 60}\n\n"
  end
=end

puts Time.now - before

