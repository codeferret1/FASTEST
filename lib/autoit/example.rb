require File.join(File.dirname(File.expand_path(__FILE__)),"method_filter")

class Foo
  include MethodFilter

  def func (x, y, z)
    puts "func(#{x}, #{y}, #{z})"
    r = x * y + z
    puts "func = #{r}"
    r
  end

  after_filter(:func) do |call, x, y, z|
    puts "Multiplying return value of func by 2"
    call[:return] *= 2
  end

  after_filter(:func) do |call, *args|
    puts "#{call[:method]}'s #{call[:type]} filter called with #{args.inspect}"
  end

  before_filter(:func) do |call, *args|
    puts "#{call[:method]}'s #{call[:type]} filter called with #{args.inspect}"
  end
  
  before_filter(:func) do |call, x, y, z|
    puts "Reversing order of arguments passed to func"
    call[:args] = [ z, y, x ]
  end

end

f = Foo.new
puts f.func(1,2,3)


