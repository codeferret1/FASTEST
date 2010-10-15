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
    # if you want to exit the filters chain and return a value immediately,
    # you can define call[:return] to something (including nil) and that will
    # be returned to the caller.
  end
  
  before_filter(:func) do |call, x, y, z|
    puts "Reversing order of arguments passed to func"
    call[:args] = [ z, y, x ]
  end
end

f = Foo.new
puts "ALL filters enabled"
puts f.func(1,2,3)
puts "AFTER filters disabled"
Foo.remove_filter(:after, :func)
puts f.func(1,2,3)
puts "ALL filters disabled"
Foo.remove_filter(:before, :func)
puts f.func(1,2,3)
