require 'time'

module AutoIt

  # Process Class
  class Process
    extend Inspectable

    CACHE_TIME = 0.50
    @@procs_cached = nil

    attr_reader :pid, :ppid, :created, :path, :name, :cmd_line

    def initialize (pid, ppid = nil, created = nil, path = nil, name = nil, cmd_line = nil)
      @pid = pid
      @ppid = ppid
      @created = created
      @path = path
      @name = name
      @cmd_line = cmd_line
    end

    def running?
      AutoIt::Process.running?(@pid)
    end

    def orphan?
      return false unless running?
      return true if parent.nil?
      not AutoIt::Process.running?(@ppid)
    end

    def parent
      # system process?
      return nil if @ppid.nil?
      p = AutoIt::Process.all[@ppid]
      return nil if p.nil?
      # incorrectly referring to a process that reuses PID of a dead parent?
      return nil if p.created > @created
      # parent was created before child (as expected)
      return p
    end

    def children
      c = AutoIt::Process.all.select do |pid, p|
        p.parent == self
      end
      c.to_h_from_kv
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
      wins = AutoIt::Window.all.select do |handle,w|
        w.process.pid == @pid
      end
      wins.to_h_from_kv
    end

    def to_s
      "Process\t[#{@pid}]\n" \
        "Name\t[#{@name}]\n" \
          "Path\t[#{@path}]\n" \
            "Created\t[#{@created}]\n" \
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
        # more info on the following link
        # http://msdn.microsoft.com/en-us/library/aa394372(VS.85).aspx
        procs.InstancesOf("Win32_Process").each do |p|
          pid = p.ProcessId
          ppid = p.ParentProcessId
          ppid = nil if pid == 0
          created = p.CreationDate
          # fails for the system process
          created = Time.parse(created) unless created.nil?
          created = Time.at(0) if created.nil?
          np = AutoIt::Process.new(pid, ppid, created, p.ExecutablePath, p.Name, p.CommandLine)
          @@proc_list[np.pid] = np
        end
        @@procs_cached = Time.now
      end
      @@proc_list
    end

    def self.find_all
      all.values
    end
  end
end

