# vim: set ts=2 sw=2 :
require 'spec_helper'

describe AutoIt::Process do
  before(:all) do
    @my_pid = ::Process.pid
    @fixtures = File.expand_path(File.join(File.dirname(__FILE__),"..","fixtures"))
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

    it "should include the current process" do  
      @procs.should include(@my_pid)
      my_proc = @procs[@my_pid]
      my_proc.should_not be_nil
      my_proc.name =~ /ruby/i
    end

    it "should have all in running state" do
      @procs.each do |pid, p|
        p.should be_running
        AutoIt::Process.should be_running(p.pid)
      end
    end

    it "should have oldest ancestor as the system or an already non-existent process" do
      @procs.each do |pid,p|
        next if p.ancestors.empty?
        if p.ancestors.last.pid != 0
          p.ancestors.last.ppid.should_not be_nil
          AutoIt::Process.should_not be_running(p.ancestors.last.ppid)
        end
      end
    end

    it "should not include parents of orphan processes" do
      @procs.each do |pid,p|
        next unless p.orphan?
        @procs.should_not include(p.ppid)
      end
    end

    it "should not have parents of orphan processes in running state" do
      @procs.each do |pid,p|
        next if p.ppid.nil? or not p.orphan?
        AutoIt::Process.should_not be_running(p.ppid)
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
          p.children.each_value { |c| expand.call(c, e) }
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
  end

  context "when checking the system process" do
    before(:each) do
      @proc = AutoIt::Process.all[0]
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

    it "should be printable" do
      s = @proc.to_s
      s.should_not be_empty
      s.should match(/Process.*Path.*CmdLine.*Parent/mi)
    end
  end

  context "when running a new process" do
    before(:each) do
      @exec_path = File.join(@fixtures,"PlayThing.exe")
      @cmd_line = ["arg1", "arg2"]
      @cmd_line_str = "\"#{@cmd_line[0]}\" \"#{@cmd_line[1]}\""
      @p = AutoIt::Process.run(@exec_path, @cmd_line)
    end

    after(:each) do
      ::Process.kill(9, @p.pid) unless @p.nil?
    end

    it "should not be possible for non-existent executables" do
      p = AutoIt::Process.run("C:\Wow\I\Am\Not\A\Path.exe", "bad_arg!")
      p.should be_nil
    end

    it "should be possible for existing executables" do
      @p.should_not be_nil
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

    it "should be possible to get the name" do
      @p.name.should == "PlayThing.exe"
    end

    it "should be possible to get the executable's path" do
      p1 = @p.path.gsub("\\", "/")
      p2 = @exec_path.gsub("\\", "/")
      p1.casecmp(p2).should == 0
    end

    it "should be possible to get the command line" do
      p_cmd_line = @p.cmd_line
      p_cmd_line.should_not be_nil
      p_cmd_line.gsub!("\\", "/")
      expected_cmd_line = @exec_path.gsub("\\", "/")
      expected_cmd_line = "\"#{expected_cmd_line}\" #{@cmd_line_str}"
      p_cmd_line.should == expected_cmd_line
    end
  end

  context "when a process is running and has windows" do
    before(:each) do
      @exec_path = File.join(@fixtures,"PlayThing.exe")
      @p = AutoIt::Process.run(@exec_path)
    end

    after(:each) do
      ::Process.kill(9, @p.pid) unless @p.nil?
    end

    it "should be possible get them" do
      sleep 0.5
      wins = @p.windows
      wins.should_not be_empty
      wins2 = wins.select do |h,w|
        w.process.pid == @p.pid and w.title == "PlayThing"
      end
      wins2.should_not be_empty
    end
  end

  context "when a windowless process is running" do
    before(:each) do
      @exec_path = File.join(@fixtures,"KnownTitle.exe")
      @p = AutoIt::Process.run(@exec_path)
    end

    after(:each) do
      ::Process.kill(9, @p.pid) unless @p.nil?
    end

    it "should have no windows associated" do
      sleep 0.5
      wins = @p.windows
      wins.should be_empty
    end
  end
end

