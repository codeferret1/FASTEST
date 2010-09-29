require 'spec_helper'

describe AutoIt::Process do

  before(:each) do
  end

  context "when a new process is created" do
    it "should be " do
      p = AutoIt::Process.new
    end
    it "should get the name AND THEN FAILZ" do
      # @p.get_name.should == "foo"
      my_name = "foo"
      my_name.should == "bar"
    end
  end

end

