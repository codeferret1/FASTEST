# vim: set ts=2 sw=2 :
require 'spec_helper'

describe AutoIt::Process do
  before(:all) do
    @my_pid = ::Process.pid
    @fixtures = File.expand_path(File.join(File.dirname(__FILE__),"..","fixtures"))
  end

  after(:each) do
    ::Process.kill(9, @p.pid) unless @p.nil?
  end

  context "when listing all processes" do
    before(:each) do
      @procs = AutoIt::Process.all
    end

    it "should have the pids correctly associated with respective process" do
      @procs.each do |pid, p|
        pid.should == p.pid
      end
    end

    it "should have the ppids correctly associated with respective parent" do
      @procs.each do |pid, p|
        if p.parent.nil?
          @procs[p.ppid].pid.should == p.ppid unless p.ppid.nil? or not @procs.has_key?(p.ppid)
        else
          p.ppid.should == p.parent.pid
        end
      end
    end

    it "should have all in running state" do
      @procs.each do |pid, p|
        p.should be_running
        AutoIt::Process.should be_running(p.pid)
      end
    end

    it "should be printable" do
      @procs.each do |pid,p|
        s = p.to_s
        s.should_not be_empty
        s.should match(/Process.*Name.*Path.*Created.*CmdLine.*Parent/mi)
      end
    end

    it "should have no cycles when moving up in the ancestors chain" do
      @procs.each do |pid,p|
        p2 = p
        visited = [ p2.pid ]
        while not (p2 = p2.parent).nil?
          visited.should_not include(p2.pid)
          visited.push(p2.pid)
        end 
      end
    end

    it "should have oldest ancestor as the system or an already non-existent process" do
      @procs.each do |pid,p|
        next if p.ancestors.empty?
        if p.ancestors.last.pid != 0
          p.ancestors.last.ppid.should_not be_nil
          p.ancestors.last.should be_an_orphan
        end
      end
    end

    it "should not include parent of orphan processes" do
      @procs.each do |pid,p|
        next unless p.orphan?
        p.parent.should be_nil
        next if p.ppid.nil?
        # not running is the "general" case
        next unless AutoIt::Process.running?(p.ppid)
        # confirm that PID has been reused
        @procs.should include(p.ppid)
        @procs[p.ppid].created.should > p.created
      end
    end

    it "should have parents of non-orphan processes in running state" do
      @procs.each do |pid,p|
        next if p.orphan?
        AutoIt::Process.should be_running(p.ppid)
      end
    end

    it "should not have a process whose parent is itself" do
      @procs.each do |pid,p|
        p.pid.should_not satisfy do |pid|
          not p.parent.nil? and p.parent.pid == pid
        end
      end
    end

    it "should not have a process with a child as ancestor or vice-versa" do
      @procs.each do |pid,p|
        expand = lambda do |p, e|
          e.should_not include(p.pid)
          e[p.pid] = p
          p.children.each { |c| expand.call(c, e) }
        end
        e = expand.call(p, {})
      end
    end

    it "should not have unordered ancestors or not defined as the parent plus its ancestors" do
      @procs.each do |pid,p|
        ascend = lambda do |p|
          p.parent.should == p.ancestors.first
          if p.parent.nil?
            p.ancestors.should be_empty
          else
            parent_ancestors = p.parent.ancestors
            parent_ancestors.should == p.ancestors[1..-1]
            parent_ancestors.each { |a| ascend.call(a) }
          end
        end
        ascend.call(p)
      end
    end

    context "and checking for the current process" do
      before(:each) do
        @proc = @procs[@my_pid]
      end

      it "should exist" do
        @proc.should_not be_nil
      end

      it "should contain 'ruby' in the name" do
        @proc.name =~ /ruby/i
      end

      it "should contain 'ruby' in the path" do
        @proc.path =~ /ruby/i
      end
    end

    context "and checking for the system process" do
      before(:each) do
        @proc = @procs[0]
      end

      it "should exist" do
        @proc.should_not be_nil
      end

      it "should contain the default name" do
        @proc.name.should == "System Idle Process"
      end

      it "should not have parent" do
        @proc.ppid.should be_nil
      end

      it "should be an orphan" do
        @proc.should be_an_orphan
      end
    end
  end

  context "when running a new process" do
    before(:each) do
      @exec_path = File.join(@fixtures,"KnownTitle.exe")
      @cmd_line = ["arg1", "arg2"]
      @cmd_line_str = "\"#{@cmd_line[0]}\" \"#{@cmd_line[1]}\""
      @p = AutoIt::Process.run(@exec_path, @cmd_line)
    end

    context "for non-existent executables" do
      it "should return nil" do
        p = AutoIt::Process.run("C:\Wow\I\Am\Not\A\Path.exe", "bad_arg!")
        p.should be_nil
      end

      context "and we inspect the process list" do
        it "should not be contained in it" do
          p = AutoIt::Process.find_all_by_path("C:\Wow\I\Am\Not\A\Path.exe")
          p.should be_empty
          p = AutoIt::Process.find_all_by_cmd_line("bad_arg!")
          p.should be_empty
        end
      end
    end

    context "for an existent executable" do
      it "should return the process" do
        @p.should_not be_nil
        @p.should be_instance_of AutoIt::Process
      end

      it "should be possible to get the id" do
        @p.pid.should_not be_nil
        @p.pid.should > 0
      end

      it "should be possible to get the parent" do
        @p.ppid.should_not be_nil
        @p.ppid.should == @my_pid
        @p.parent.should_not be_nil
        @p.parent.pid == @my_pid
      end

      it "should have the correct name" do
        @p.name.should == "KnownTitle.exe"
      end

      it "should have the correct path to the executable" do
        p1 = @p.path.gsub("\\", "/")
        p2 = @exec_path.gsub("\\", "/")
        p1.casecmp(p2).should == 0
      end

      it "should have the correct command line" do
        p_cmd_line = @p.cmd_line
        p_cmd_line.should_not be_nil
        p_cmd_line.gsub!("\\", "/")
        expected_cmd_line = @exec_path.gsub("\\", "/")
        expected_cmd_line = "\"#{expected_cmd_line}\" #{@cmd_line_str}"
        p_cmd_line.should == expected_cmd_line
      end

      context "and we inspect the process list" do
        it "should be contained in it" do
          p = AutoIt::Process.find_all_by_path(@p.path)
          p.should have_exactly(1).items
          p[0].pid.should == @p.pid
          p[0].path.should == @p.path
          p = AutoIt::Process.find_all_by_cmd_line(@p.cmd_line)
          p.should have_exactly(1).items
          p[0].pid.should == @p.pid
          p[0].cmd_line.should == @p.cmd_line
          p = AutoIt::Process.find_by_pid_and_name(@p.pid, @p.name)
          p.should_not be_nil 
          p.pid.should == @p.pid
          p.name.should == @p.name
        end
      end
    end
  end

  context "when checking the list of windows" do
    context "for a process that has windows" do
      before(:each) do
        @exec_path = File.join(@fixtures,"PlayThing.exe")
        @p = AutoIt::Process.run(@exec_path)
        sleep 0.5
        @wins = @p.windows
      end

      it "should return a non-empty list" do
        @wins.should_not be_empty
      end

      it "should contain a window with the main title" do
        @wins.select do |w|
          w.title == "PlayThing"
        end.should_not be_empty
      end

      it "should have all windows refering to that process" do
        @wins.select do |w|
          w.process.pid.should == @p.pid
        end
      end
    end

    context "for a process that has no windows" do
      before(:each) do
        @exec_path = File.join(@fixtures,"KnownTitle.exe")
        @p = AutoIt::Process.run(@exec_path)
      end

      it "should return an empty list" do
        sleep 0.5
        wins = @p.windows
        wins.should be_empty
      end
    end
  end
end

