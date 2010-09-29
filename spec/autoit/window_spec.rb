require 'spec_helper'

describe AutoIt::Window do
   before(:all) do 
      @fixtures = File.join(File.dirname(__FILE__),"..","fixtures")
   end
   context "when listing windows" do 
      it "should list existing windows" do 
         old_title = AutoIt::Process.my_console.title
         AutoIt::Process.my_console.title = "KnownTitle"
         all = AutoIt::Window::all.values.map { |w| w.title }
         all.should include("KnownTitle")
         AutoIt::Process.my_console.title = old_title
      end
      it "should not list windows that are gone" do 
         all = AutoIt::Window::all.values.map { |w| w.title }
         all.should_not include("KnownTitle")
      end
   end
end

