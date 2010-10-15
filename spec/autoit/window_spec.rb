require 'spec_helper'
# vim: set ts=2 sw=2:

describe AutoIt::Window do
  before(:all) do 
    @fixtures = File.join(File.dirname(__FILE__),"..","fixtures")
    @console = AutoIt::Process.containing_window
  end

  after(:each) do
    begin
      ::Process.kill(9, @pid) unless @pid.nil?
      sleep 0.5
    rescue
    end
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

    it "should be printable" do
      all = AutoIt::Window::all.values.each do |w|
        s = w.to_s
        s.should_not be_empty
        s.should match(/Window.*Process.*Title.*Classes.*Pos.*Size.*Client.*Text.*State/mi)
      end
    end
  end

  context "when a new window is opened" do
    before(:each) do
      AutoIt::Window.all.values.select { |w| w.title == "PlayThing" }.should be_empty
      @pid = Util::async_sys(File.join(@fixtures,"PlayThing.exe"))
      @pid.should_not be_nil
      @plaything = AutoIt::Window.wait_exists(:timeout => 2) { |w| w.title == "PlayThing" }.first
    end

    it "should be contained in the window list" do
      @plaything.should_not be_nil
    end

    context "and we change its title" do
      before(:each) do
        @plaything.title.should == "PlayThing"
        @plaything.title = "SomeStrangeTitle"
      end

      it "should have its title changed" do  
        @plaything.title.should == "SomeStrangeTitle"
      end

      it "should be reflected in the window list" do
        all = AutoIt::Window::all.values.map { |w| w.title }
        all.should_not include("KnownTitle")
        all.should include("SomeStrangeTitle")
      end
    end

    context "and we try hiding or showing it" do 
      it "should stop or start being visible" do 
        @plaything.should be_visible
        @plaything.visible=false
        @plaything.should_not be_visible
        @plaything.show
        @plaything.should be_visible
        @plaything.hide
        @plaything.should_not be_visible
        @plaything.visible=true
        @plaything.should be_visible
      end
    end

    context "and we try minimizing or maximizing it" do 
      it "should stop or start being minimized" do 
        @plaything.maximize
        @plaything.should be_maximized
        @plaything.minimize
        @plaything.should be_minimized
        @plaything.maximize
        @plaything.should be_maximized
      end

      it "should restore to its previous state" do 
        @plaything.maximize
        @plaything.should be_maximized
        @plaything.minimize
        @plaything.should_not be_maximized
        @plaything.restore
        @plaything.should be_maximized
      end
    end

    context "and we close it" do
      it "should be gone" do 
        @plaything.should be_a AutoIt::Window
        @plaything.close
        AutoIt::Window.find_by_title("PlayThing").should be_nil
      end
    end

    context "and we kill it" do
      it "should be gone" do 
        @plaything.should be_a AutoIt::Window
        @plaything.kill
        AutoIt::Window.find_by_title("PlayThing").should be_nil
      end
    end
  end

  context "when waiting for a window" do
    before(:each) do
      AutoIt::Window.all.select { |h, w| w.title == "PlayThing" }.should be_empty
    end

    context "to be active" do
      context "but it does not exist" do
        it "should timeout" do 
          AutoIt::Window.wait_active(:timeout => 2) { |w| w.title == "PlayThing" }.should be_empty
        end
      end

      context "and it exists" do
        context "before and during the wait" do
          before(:each) do
            @pid = Util::async_sys(File.join(@fixtures,"PlayThing.exe"))
            @pid.should_not be_nil
            @wins = AutoIt::Window.wait_active(:timeout => 2) { |w| w.title == "PlayThing" }
          end

          it "should find exactly one window" do
            @wins.should_not be_nil
            @wins.should have_exactly(1).items
          end

          it "should not timeout" do
            @wins.should_not be_empty
            @wins.each { |w| w.should_not be_nil }
          end

          it "should be active" do
            @wins.should_not be_empty
            @wins.each { |w| w.should be_active }
          end
        end

        context "only after the wait is initiated" do
          before(:each) do
            t = Thread.new do
              AutoIt::Window.wait_active(:timeout => 2) { |w| w.title == "PlayThing" }
            end

            sleep 1
            @pid = Util::async_sys(File.join(@fixtures,"PlayThing.exe"))
            @pid.should_not be_nil
            @wins = t.value
          end

          it "should only find one window" do
            @wins.should have_exactly(1).items
          end

          it "should not timeout" do
            @wins.should_not be_empty
            @wins.each { |w| w.should_not be_nil }
          end

          it "should be active" do
            @wins.should_not be_empty
            @wins.each { |w| w.should be_active }
          end
        end
      end
    end
  end
end

