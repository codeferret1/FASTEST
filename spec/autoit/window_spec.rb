require 'spec_helper'
# vim: set ts=2 sw=2:

describe AutoIt::Window do
  before(:all) do 
    @fixtures = File.join(File.dirname(__FILE__),"..","fixtures")
  end
  before(:each) do 
    @console = AutoIt::Process.containing_window
  end
  context "when listing windows" do 
    it "should list existing windows" do 
      old_title = @console.title
      @console.title = "KnownTitle"
      all = AutoIt::Window::all.values.map { |w| w.title }
      all.should include("KnownTitle")
      @console.title = old_title
    end
    it "should not list windows that are gone" do 
      @console.title = "SomeStrangeTitle"
      all = AutoIt::Window::all.values.map { |w| w.title }
      all.should_not include("KnownTitle")
    end
  end
  context "when hiding or showing a window" do 
    it "should stop or start being visible" do 
      @console.should be_visible
      @console.hide
      @console.should_not be_visible
      @console.show
      @console.should be_visible
    end
  end
  context "when minimizing or maximizing a window" do 
    it "should stop or start being minimized" do 
      @console.maximize
      @console.should be_maximized
      @console.minimize
      @console.should be_minimized
      @console.maximize
      @console.should be_maximized
    end
  end
  context "when restoring a window" do 
    it "should restore to its previous state" do 
      @console.maximize
      @console.should be_maximized
      @console.minimize
      @console.should_not be_maximized
      @console.restore
      @console.should be_maximized
    end
  end
  context "closing and killing windows" do
    before(:each) do
      Util::async_sys(File.join(@fixtures,"PlayThing.exe"))
      sleep 0.5
      @plaything = AutoIt::Window.find_by_title("PlayThing")
      @plaything.should be_a AutoIt::Window
    end

    it "should die when killed" do 
      @plaything.kill 
      AutoIt::Window.find_by_title("PlayThing").should be_nil
    end
  end
  context "when waiting for a window" do
    context "to be active" do 
      it "should return nil if it times out" do 
        AutoIt::Window.wait_active(:timeout => 2) { |t| t.title == "PlayThing" }.should be_nil
      end
    end
  end


end
