require 'spec_helper'

describe MethodFilter do

  module FooFunc
    def func (x, y, z)
      r = x * y + z
    end
  end

  class FilteredFoo
    include FooFunc
  end

  class FilteredFooJustInclude
    include FooFunc
    include MethodFilter
  end

  class FilteredFooBeforeLogger
    include FooFunc
    include MethodFilter

    attr_accessor :logged

    before_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << "#{call[:method]}'s #{call[:type]} filter called with #{args.inspect}"
    end
  end

  class FilteredFooBeforeLogger2
    include FooFunc
    include MethodFilter

    attr_accessor :logged

    before_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << "#{call[:method]}'s #{call[:type]} filter called with #{args.inspect}"
    end
  end

  class FilteredFooBeforeManipulateArgs
    include FooFunc
    include MethodFilter

    before_filter(:func) do |call, *args|
      call[:args] = args.reverse 
    end

    before_filter(:func) do |call, x, y, z|
      call[:args] = [x * 2, y * 2, z * 2]
    end
  end

  class FilteredFooBeforeReturn
    include FooFunc
    include MethodFilter

    attr_accessor :logged

    before_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << 1
    end

    before_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << 2
      call[:return] = "success"
    end

    before_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << 3
      call[:return] = "failure"
    end

    before_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << 4 
      call[:return] = "failure2"
    end
  end

  class FilteredFooAfterManipulateReturn
    include FooFunc
    include MethodFilter

    attr_accessor :logged

    after_filter(:func) do |call, *args|
      call[:return] *= 2
    end

    after_filter(:func) do |call, *args|
      call[:return] *= 3
    end

    after_filter(:func) do |call, *args|
      call[:return] *= 4
    end
  end

  class FilteredFooOrder
    include FooFunc
    include MethodFilter

    attr_accessor :logged

    before_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << :b1
    end

    after_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << :a1
    end

    before_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << :b2
    end

    after_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << :a2
    end

    before_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << :b3
    end

    after_filter(:func) do |call, *args|
      call[:instance].logged ||= []
      call[:instance].logged << :a3
    end
  end

  before(:all) do
    f = FilteredFoo.new
    f.func(2, 3, 4).should == 10
  end

  context "when included in a class" do
    it "should not change the way existing functions behave" do
      f = FilteredFooJustInclude.new
      f.func(2, 3, 4).should == 10
    end
  end

  context "when defining a logger filter" do
    it "should just log the call" do
      f = FilteredFooBeforeLogger.new
      f.logged.should be_nil
      f.func(2, 3, 4).should == 10
      f.logged.should have_exactly(1).items
      f.logged[0].should == "func's before filter called with [2, 3, 4]"
    end

    context "and erasing it" do
      context "before calling the filtered method even once" do
        it "should log nothing" do
          f = FilteredFooBeforeLogger.new
          f.logged.should be_nil
          f.class.remove_filter(:before, :func)
          f.func(2, 3, 4).should == 10
          f.logged.should be_nil
        end
      end

      context "after calling the filtered method several times" do
        it "should stop logging after being erased" do
          f = FilteredFooBeforeLogger2.new
          f.logged.should be_nil
          10.times do |i|
            f.func(2, 3, 4).should == 10
            f.logged.should have_exactly(i+1).items
          end
          f.class.remove_filter(:before, :func)
          f.func(2, 3, 4).should == 10
          f.logged.should have_exactly(10).items
          f = FilteredFooBeforeLogger2.new
          f.func(2, 3, 4).should == 10
          f.logged.should be_nil
        end
      end
    end
  end

  context "when defining a before filter that forces a return" do
    it "should return the expected value" do
      f = FilteredFooBeforeReturn.new
      f.func(2, 3, 4).should == "success"
      f.logged.should == [1, 2]
    end
  end

  context "when defining a before filter that manipulates args" do
    it "should change the behavior of the filtered method" do
      f = FilteredFooBeforeManipulateArgs.new
      f.func(2, 3, 4).should == 52
    end
  end

  context "when defining before and after filters" do
    it "should execute in the correct order" do
      f = FilteredFooOrder.new
      f.logged.should be_nil
      f.func(2, 3, 4).should == 10
      f.logged.should == [:b1, :b2, :b3, :a1, :a2, :a3]
    end
  end

  context "when defining after filters that manipulate the return value" do
    it "should change the final return value" do
      f = FilteredFooAfterManipulateReturn.new
      f.func(2, 3, 4).should == 240 
    end
  end
end
