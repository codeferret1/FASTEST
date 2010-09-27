require 'win32ole'
require 'ostruct'

module AutoIt
  VERSION = '1.0.0'

  # COM interface for AutoItX3 Control object
  COM = WIN32OLE.new('AutoItX3.Control')

  # Window Class
  class Win
    attr_reader :handle
    attr_accessor :title

    def initialize (handle)
      @handle = handle
    end

    def active?
      AutoIt::COM.WinActive(handle_filter) == 1
    end

    def activate
      AutoIt::COM.WinActivate(handle_filter)
    end

    def close
      AutoIt::COM.WinClose(handle_filter)
    end

    def class_list
      AutoIt::COM.WinGetClassList(handle_filter)
    end

    def has_class? (c)
      class_list.include?(c)
    end

    def title
      AutoIt::COM.WinGetTitle(handle_filter)
    end

    def pos
      OpenStruct.new({
        :x => AutoIt::COM.WinGetPosX(handle_filter).to_i,
        :y => AutoIt::COM.WinGetPosY(handle_filter).to_i
      })
    end

    def size
      OpenStruct.new({
        :w => AutoIt::COM.WinGetPosWidth(handle_filter).to_i,
        :h => AutoIt::COM.WinGetPosHeight(handle_filter).to_i
      })
    end

    def to_s
      "[#{title}]: (#{pos.x},#{pos.y} #{size.w}x#{size.h})"
    end

    def self.list (title = "", text = "")
      titles, handles = AutoIt::COM.WinList(title, text)
      windows = []
      (1...handles.size).each do |i|
        w = AutoIt::Win.new(handles[i])
        windows.push(w)
      end
      windows
    end

    def self.all
      list("[ALL]")
    end

    private

    def handle_filter
      "[HANDLE:#{@handle}]"
    end
  end
end
