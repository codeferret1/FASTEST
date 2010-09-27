

require File.join(File.dirname(__FILE__), 'autoit')

wins = AutoIt::Win.all

wins.each do |win|
  puts win
  puts win.class_list
end

