module AutoIt

  # Process Class
  class Process

    CACHE_TIME = 0.50
    @@procs_cached = nil

    attr_reader :pid, :ppid, :path, :name, :command_line

    def initialize (pid, ppid = nil, path = nil, name = nil, cmd_line = nil)
      @pid = pid
      @ppid = ppid
      @path = path
      @name = name
      @cmd_line = cmd_line
    end

    def parent
      AutoIt::Process.all[@ppid]
    end

    def windows
      AutoIt::Window.all.select do |handle,w|
        w.process.pid == @pid
      end
    end

    def self.my_console
       Process.new(::Process.ppid).windows.values.first
    end

    # refresh cached process list if older than X seconds (nil to avoid refresh)
    def self.all (cache_refresh = CACHE_TIME)
      if @@procs_cached.nil? or (not cache_refresh.nil? and (Time.now - @@procs_cached) >= cache_refresh)
        procs = WIN32OLE.connect("winmgmts:{impersonationLevel=impersonate,(Debug)}\\\\.")
        @@proc_list = {}
        procs.InstancesOf("Win32_Process").each do |p|
          np = AutoIt::Process.new(p.ProcessId, p.ParentProcessId, p.ExecutablePath, p.Name, p.CommandLine)
          @@proc_list[np.pid] = np
        end
        @@procs_cached = Time.now
      end
      @@proc_list
    end

  end
end

