module AutoIt

  # Process Class
  class Process

    CACHE_TIME = 0.50
    @@procs_cached = nil

    attr_reader :pid, :ppid, :path, :name, :cmd_line

    def initialize (pid, ppid = nil, path = nil, name = nil, cmd_line = nil)
      @pid = pid
      @ppid = ppid
      @path = path
      @name = name
      @cmd_line = cmd_line
    end

    def running?
      AutoIt::Process.running?(@pid)
    end

    def orphan?
      running? and not AutoIt::Process.running?(@ppid)
    end

    def parent
      # system process?
      return nil if @ppid.nil?
      AutoIt::Process.all[@ppid]
    end

    def children
      AutoIt::Process.all.select do |pid, p|
        p.parent == self
      end.to_h_from_kv
    end

    def ancestors 
      ps = []
      p = self
      while not (p = p.parent).nil?
        ps.push(p)
      end
      ps
    end

    def windows
      AutoIt::Window.all.select do |handle,w|
        w.process.pid == @pid
      end.to_h_from_kv
    end

    def to_s
      "Process\t[#{@pid},#{@name}]\n" \
      "Path\t[#{@path}]\n" \
      "CmdLine\t[#{@cmd_line}]\n" \
      "Parent\t[#{@ppid},#{parent.nil? ? '' : parent.name}]"
    end

    def self.running? (pid)
      AutoIt::Process.all.has_key?(pid)
    end

    def self.run (path, args = nil, options = {})
      options = { :workingdir => nil,
                  :flag => nil
      }.merge(options)
      args = [ args ].compact unless args.is_a? Array
      cmd = "\"#{path}\""
      cmd += " \"#{args.join('" "')}\"" unless args.empty?
      pid = AutoIt::COM.Run(cmd, options[:workingdir], options[:flag])
      return nil if pid == 0
      AutoIt::Process.all(0)[pid]
    end

    def self.containing_window (pid = $$)
      p = AutoIt::Process.all[pid]
      return nil if p.nil?
      p = p.parent
      return nil if p.nil?
      w = p.windows.values.first
      return w unless w.nil?
      containing_window(p.pid)
    end

    # refresh cached process list if older than X seconds (nil to avoid refresh)
    def self.all (cache_refresh = CACHE_TIME)
      if @@procs_cached.nil? or (not cache_refresh.nil? and (Time.now - @@procs_cached) >= cache_refresh)
        procs = WIN32OLE.connect("winmgmts:{impersonationLevel=impersonate,(Debug)}\\\\.")
        @@proc_list = {}
        procs.InstancesOf("Win32_Process").each do |p|
          pid = p.ProcessId
          ppid = p.ParentProcessId
          ppid = nil if pid == 0
          np = AutoIt::Process.new(pid, ppid, p.ExecutablePath, p.Name, p.CommandLine)
          @@proc_list[np.pid] = np
        end
        @@procs_cached = Time.now
      end
      @@proc_list
    end

  end
end

