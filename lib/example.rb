
require File.join(File.dirname(__FILE__), 'autoit')

before = Time.now

ws = AutoIt::Window.wait_exists do |w|
  w.process.name =~ /chrome/i 
end

def print_menu_tree (m, level = 0)
  puts " " * level + "[#{m.index}][#{m.text}]"
  puts "*" * 50
  puts m 
  puts "*" * 50
  m.submenus.each do |s|
    print_menu_tree(s, level + 3)
  end
end

def print_window_tree (w, level = 0)
  puts " " * level + "[#{w.handle.to_s(16)}] [#{w.title.delete("\r\n")}] [#{w.class_name}]"
  unless w.menus.empty?
    puts "-" * 80
    w.menus.each do |m|
      print_menu_tree(m, level)
    end
    puts "-" * 80
  end
  w.children.each do |c|
    print_window_tree(c, level + 2)
  end
end

ws.each do |w|
  next unless w.top_level?
  print_window_tree(w)
end

#puts AutoIt::Window.wait(".process.name =~ /notepad/i", { :timeout => 3 })

=begin
  procs = AutoIt::Process.all
  procs.each_value do |proc|
    puts "#{proc.name}\n#{'-' * 60}\n#{proc.windows.values.join("\n-\n")}\n#{'-' * 60}\n\n"
  end
=end

puts Time.now - before

