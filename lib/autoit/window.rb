# vim: set ts=2 sw=2:

module AutoIt
  # Window Class
  class Window

    CACHE_TIME = 0.25
    @@wins_cached = nil

    attr_reader :handle

    def initialize (handle=nil)
      @handle = handle
    end

    # actions

    def show
      AutoIt::COM.WinSetState(handle_filter, "", AutoIt::COM.SW_SHOW)
    end

    def hide
      AutoIt::COM.WinSetState(handle_filter, "", AutoIt::COM.SW_HIDE)
    end

    def visible= (flag)
      return show if flag == true
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

    def state= (state)
      AutoIt::COM.WinSetState(handle_filter, "", state)
    end

    def close
      AutoIt::COM.WinClose(handle_filter)
    end

    def kill
      AutoIt::COM.WinKill(handle_filter)
    end

    # properties

    def exists?
      (state & 1) != 0
    end

    def visible?
      (state & 2) != 0
    end

    def active?
      AutoIt::COM.WinActive(handle_filter) == 1
    end

    def minimized?
      (state & 16) != 0
    end

    def maximized?
      (state & 32) != 0
    end

    def classes
      AutoIt::COM.WinGetClassList(handle_filter).split("\n")
    end

    def has_class? (c)
      classes.include?(c)
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

    def pos
      p = OpenStruct.new({
        :x => AutoIt::COM.WinGetPosX(handle_filter).to_i,
        :y => AutoIt::COM.WinGetPosY(handle_filter).to_i
      })
      p.inspect
      p
    end

    def size
      OpenStruct.new({
        :w => AutoIt::COM.WinGetPosWidth(handle_filter).to_i,
        :h => AutoIt::COM.WinGetPosHeight(handle_filter).to_i
      })
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

      "Window\t[#{handle}]\n" \
      "Process\t[ID: #{process.pid}, Name: #{process.name}, Path: #{process.path}]\n" \
      "Title\t[#{title.inspect}]\n" \
      "Classes\t[#{classes.join(" -> ")}]\n" \
      "Pos\t[#{pos.x},#{pos.y}]\n" \
      "Size\t[#{size.w},#{size.h}]\n" \
      "Client\t[#{client.size.w},#{client.size.h}]\n" \
      "Text\t[#{text.inspect}]\n" \
      "State\t[#{states.compact.join(", ")}]"# \
      #"Children\t[#{children}]"
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

    def self.wait_until (condition, options = {})
      options = { :timeout => nil,
                  :polling => CACHE_TIME }.merge(options)
      start_time = Time.now
      while (match = all(0).select(condition)).empty?
        sleep_time = options[:polling]
        unless options[:timeout].nil?
          end_time = start_time + options[:timeout]
          return nil if (Time.now + sleep_time) > end_time
        end
        sleep(sleep_time)
      end
      match
    end

    def self.wait_active (condition, options = {})
      wait_until(".exists? and .active? and (#{condition})", options)
    end

    def self.wait_not_active (condition, options = {})
      wait_until(".exists? and not .active? and (#{condition})", options)
    end

    def self.wait_exists (condition, options = {})
      wait_until(".exists? and (#{condition})", options)
    end

    def self.wait (condition, options = {})
      wait_exists(condition, options)
    end

    def self.wait_not_exists (condition, options = {})
      wait_until("not .exists? and (#{condition})", options)
    end

    def self.method_missing(method, *args, &block)
      if method =~ /\Afind_by_(\S+)\Z/
        attribute = $1
        if AutoIt::Window.new.respond_to? attribute
          res = all.values.select { |w| eval("w.#{attribute} == args.first") }
          case res.size
          when 0
            nil 
          when 1
            res.first 
          else 
            res
          end
        else
          super
        end
      else
        super
      end
    end

    private

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
      "[HANDLE:#{@handle}]"
    end
  end
end

