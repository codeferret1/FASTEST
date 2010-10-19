# vim: set ts=2 sw=2:

module AutoIt
  # Window Class
  class Window
    extend Inspectable
    include MethodFilter

    CACHE_TIME = 0.25
    @@wins_cached = nil

    STATE_EXISTS = 1
    STATE_VISIBLE = 2
    STATE_ENABLED = 4
    STATE_ACTIVE = 8
    STATE_MINIMIZED = 16
    STATE_MAXIMIZED = 32

    attr_reader :handle

    def initialize (handle=nil)
      @handle = handle.hex
    end

    # actions

    def show
      AutoIt::COM.WinSetState(handle_filter, "", AutoIt::COM.SW_SHOW)
    end

    def hide
      AutoIt::COM.WinSetState(handle_filter, "", AutoIt::COM.SW_HIDE)
    end

    def visible= (flag)
      return show if flag
      hide
    end

    def activate
      AutoIt::COM.WinActivate(handle_filter)
    end

    def minimize
      AutoIt::COM.WinSetState(handle_filter, "", AutoIt::COM.SW_MINIMIZE)
    end

    def maximize
      AutoIt::COM.WinSetState(handle_filter, "", AutoIt::COM.SW_MAXIMIZE)
    end

    def restore
      AutoIt::COM.WinSetState(handle_filter, "", AutoIt::COM.SW_RESTORE)
    end

    def always_on_top= (flag)
      flag = flag ? 1 : 0
      AutoIt::COM.WinSetState(handle_filter, "", flag)
    end

    def close
      AutoIt::COM.WinClose(handle_filter)
    end

    def kill
      AutoIt::COM.WinKill(handle_filter)
    end

    # properties

    def exists?
      (state & AutoIt::Window::STATE_EXISTS) !=0
    end

    def visible?
      (state & AutoIt::Window::STATE_VISIBLE) != 0
    end

    def enabled?
      (state & AutoIt::Window::STATE_ENABLED) != 0
    end

    def active?
      AutoIt::COM.WinActive(handle_filter) == 1
    end

    def minimized?
      (state & AutoIt::Window::STATE_MINIMIZED) != 0
    end

    def maximized?
      (state & AutoIt::Window::STATE_MAXIMIZED) != 0
    end

    def class_name
      @@__User32GetClassName__ ||= Win32::API.new('GetClassName', 'LPI', 'I', 'user32')
      tmp = "\0" * 256
      @@__User32GetClassName__.call(handle, tmp, tmp.size - 1)
      tmp.rstrip
    end

    def title
      AutoIt::COM.WinGetTitle(handle_filter)
    end

    def title= (title)
      AutoIt::COM.WinSetTitle(handle_filter, "", title)
    end

    def text
      AutoIt::COM.WinGetText(handle_filter)
    end

    def owner
      @@__User32GetWindow__ ||= Win32::API.new('GetWindow','LI','L', 'user32')
      p = @@__User32GetWindow__.call(handle, 4)
      p = AutoIt::Window.all[p]
    end

    def parent
      @@__User32GetAncestor__ ||= Win32::API.new('GetAncestor','LI','L', 'user32')
      p = @@__User32GetAncestor__.call(handle, 1)
      p = AutoIt::Window.all[p]
    end

    def children
      AutoIt::Window.all.values.select do |w|
        w.parent == self
      end
    end

    def ancestors 
      ps = []
      p = self
      while not (p = p.parent).nil?
        ps.push(p)
      end
      ps
    end

    def pos
      p = OpenStruct.new({
        :x => AutoIt::COM.WinGetPosX(handle_filter).to_i,
        :y => AutoIt::COM.WinGetPosY(handle_filter).to_i
      })
      p
    end

    def pos= (p)
      AutoIt::COM.WinMove(handle_filter, "", p[0], p[1], nil, nil)
    end

    alias :move :pos=

    def size
      OpenStruct.new({
        :w => AutoIt::COM.WinGetPosWidth(handle_filter).to_i,
        :h => AutoIt::COM.WinGetPosHeight(handle_filter).to_i
      })
    end

    def size= (s)
      p = pos
      AutoIt::COM.WinMove(handle_filter, "", p.x, p.y, s[0], s[1])
    end

    alias :resize :size=

    before_filter(:pos=, :move, :size=, :resize) do |call, *args|
      if args.size == 2
        call[:args] = [[args[0], args[1]]] 
      elsif args[0].is_a? OpenStruct
        if args[0].respond_to?(:x=)
          call[:args] = [[args[0].x, args[0].y]]
        else
          call[:args] = [[args[0].w, args[0].h]]
        end
      end
    end

    def client
      c = OpenStruct.new
      c.pos = OpenStruct.new({
        :x => 0,
        :y => 0
      })
      c.size = OpenStruct.new({
        :w => AutoIt::COM.WinGetClientSizeWidth(handle_filter).to_i,
        :h => AutoIt::COM.WinGetClientSizeHeight(handle_filter).to_i
      })
      c
    end

    def state
      AutoIt::COM.WinGetState(handle_filter)
    end

    def process
      return @process unless @process.nil?
      pid = AutoIt::COM.WinGetProcess(handle_filter).to_i
      @process = AutoIt::Process.all[pid]
      return Process.new(pid) if @process.nil?
      @process
    end

    def to_s
      states = []
      states << (visible? ? "Visible" : "Hidden")
      states << (active? ? "Active" : "Inactive")
      states << (minimized? ? "Minimized" : nil)
      states << (maximized? ? "Maximized" : nil)

      as = ancestors.map { |a| a.handle.to_s(16) }
      cs = children.map { |c| c.handle.to_s(16) }

      "Window\t\t[#{handle.to_s(16)}]\n" \
      "Process\t\t[ID: #{process.pid}, Name: #{process.name}, Path: #{process.path}]\n" \
      "Title\t\t[#{title.inspect[1..-2]}]\n" \
      "Class\t\t[#{class_name}]\n" \
      "Pos\t\t[#{pos.x},#{pos.y}]\n" \
      "Size\t\t[#{size.w},#{size.h}]\n" \
      "Client\t\t[#{client.size.w},#{client.size.h}]\n" \
      "Text\t\t[#{text.inspect[1..-2]}]\n" \
      "State\t\t[#{states.compact.join(", ")}]\n" \
      "Ancestors\t[#{as.join(" -> ")}]\n" \
      "Children\t[#{cs.join(", ")}]\n" \
      "Owner\t\t[#{owner.nil? ? "" : owner.handle.to_s(16)}]"
    end

    # refresh cached window list if older than X seconds (nil to avoid refresh)
    def self.all (cache_refresh = CACHE_TIME)
      if @@wins_cached.nil? or (not cache_refresh.nil? and (Time.now - @@wins_cached) >= cache_refresh)
        # search top-level and child windows
        AutoIt::COM.AutoItSetOption("WinSearchChildren", "1")
        @@win_list = list("[ALL]")
        @@wins_cached = Time.now
      end
      @@win_list
    end

    def self.find_all
      all.values
    end

    def self.wait_until (options = {})
      options = { :timeout => nil,
        :polling => CACHE_TIME }.merge(options)
      start_time = Time.now
      while (match = all(0).values.select{ |w| yield(w) }).empty?
        sleep_time = options[:polling]
        unless options[:timeout].nil?
          end_time = start_time + options[:timeout]
          return [] if (Time.now + sleep_time) > end_time
        end
        sleep(sleep_time)
      end
      match
    end

    def self.wait_active (options = {})
      wait_until(options) do |w|
        w.exists? and w.active? and yield(w)
      end
    end

    def self.wait_not_active (options = {})
      wait_until(options) do |w|
        w.exists? and not w.active? and yield(w)
      end
    end

    def self.wait_exists (options = {})
      wait_until(options) do |w|
        w.exists? and yield(w)
      end
    end

    def self.wait (options = {})
      wait_exists(options) { |w| yield(w) }
    end

    def self.wait_not_exists (options = {})
      wait_exists(options) { |w| not yield(w) }
    end

    def self.list (title = "", text = "")
      titles, handles = AutoIt::COM.WinList(title, text)
      windows = {}
      (1...handles.size).each do |i|
        w = AutoIt::Window.new(handles[i])
        windows[w.handle] = w
      end
      windows
    end

    def handle_filter
      "[HANDLE:#{@handle.to_s(16)}]"
    end
  end
end

