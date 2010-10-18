require 'spec_helper'
require 'ostruct'

describe Inspectable do

  class FooNoCallbackMethodDefined
    include Inspectable
  end

  class FooCallbackDefined
    include Inspectable

    attr_accessor :all

    def find_all
      @all
    end
  end

  before(:all) do
    @people = [
        {:mail => "person1@example1.com",
         :name => "Person 1"},
        {:mail => "robot1@example1.com",
         :name => "Fake Person 1" },
        {:mail => "person2@example2.com",
         :name => "Person 2"},
        {:mail => "robot2@example2.com",
         :name => "Fake Person 2" },
        {:mail => "person3@ExAmPlE3.cOm",
         :name => "Person 3"},
        {:mail => "robot3@example3.com",
         :name => "Fake Person 3" }
      ]
    @people.map! do |p|
      OpenStruct.new(p)
    end
  end

  before(:each) do
    @f = FooCallbackDefined.new 
  end

  context "when inspecting a class" do
    it "should raise an error if `find_all' method is not defined" do
      f = FooNoCallbackMethodDefined.new
      lambda {
        f.find_by_whatever(:bar)
      }.should raise_error(NameError, /method `find_all'/)
      lambda {
        f.match_by_whatever(:bar)
      }.should raise_error(NameError, /method `find_all'/)
    end

    it "should return nothing when nothing should be found" do
      [[], [:a], [:b, 1], [nil]].each do |a|
        @f.all = a
        @f.find_by_class(String).should be_nil
      end
      [[], ["a"], ["b", "1"], ["C"]].each do |a|
        @f.all = a
        @f.match_by_swapcase(/C/).should be_nil
      end
    end

    it "should return results according to selector" do
      @f.all = ["2", 3, "4"] 
      @f.find_all_by_class(String).should == ["2", "4"]
      @f.find_first_by_class(String).should == "2" 
      @f.find_last_by_class(String).should == "4"
      @f.find_by_class(String).should == ["2", "4"]
      @f.find_all_by_class(Fixnum).should == [3]
      @f.find_first_by_class(Fixnum).should == 3 
      @f.find_last_by_class(Fixnum).should == 3
      @f.find_by_class(Fixnum).should == 3
      @f.find_all_by_class(Float).should == []
      @f.find_first_by_class(Float).should == nil 
      @f.find_last_by_class(Float).should == nil 
      @f.find_by_class(Float).should == nil
    end

    it "should be able to use regexps in matches" do
      @f.all = []
      @people.each do |p|
        @f.all << p
      end
      @f.match_by_mail(/example\d.com/i).should == @people
      @f.match_by_mail(/example2.com/i).should == [@people[2], @people[3]]
      @f.match_all_by_mail(/example4.com/i).should be_empty
    end

    it "should be able to find/match by multiple fields" do
      @f.all = []
      @people.each do |p|
        @f.all << p
      end
      @f.find_by_mail_and_name("robot1@example1.com", "Fake Person 1").should == @people[1]
      @f.match_by_mail_and_name(/example\d.com/i, /fake/i).should == [@people[1], @people[3], @people[5]]
      @f.match_by_name_and_mail(//, /example\d.com/i).should == @people 
      @f.find_by_name_and_mail("Person 3", "person3@ExAmPlE3.cOm").should == @people[4]
      @f.match_all_by_mail_and_name(/example2.com/i, /person/i).should == [@people[2], @people[3]]
      @f.find_all_by_mail_and_name("person3@ExAmPlE3.com", "Person 3").should be_empty 
      @f.match_all_by_mail_and_name(/example\d.com/i, /person/).should be_empty
    end
  end
end

