# vim: set ts=2 sw=2:

module AutoIt
  class Menu

    MF_BYPOSITION = 0x00000400
    MF_CHECKED = 0x00000008
    MF_DISABLED = 0x00000002
    MF_GRAYED = 0x00000001
    MF_HILITE = 0x00000080
    MF_MENUBARBREAK = 0x00000020
    MF_MENUBREAK = 0x00000040
    MF_OWNERDRAW = 0x00000100
    MF_POPUP = 0x00000010

    MFT_STRING = 0x00000000
    MFT_SEPARATOR = 0x00000800

    MIIM_STATE = 0x00000001
    MIIM_TYPE = 0x00000010

    attr_reader :handle, :index

    def initialize (handle, index = nil)
      @handle = handle
      @index = index
    end

    def item_id
      return nil if index.nil?
      @@__User32GetMenuItemID__ ||= Win32::API.new('GetMenuItemID','LI','I', 'user32')
      i = @@__User32GetMenuItemID__.call(handle, index)
      return nil if i == -1
      i
    end

    def submenus
      @@__User32GetSubMenu__ ||= Win32::API.new('GetSubMenu','LI','L', 'user32')
      h = @@__User32GetSubMenu__.call(handle, index) unless index.nil?
      h ||= handle
      @@__User32GetMenuItemCount__ ||= Win32::API.new('GetMenuItemCount','L','I', 'user32')
      cnt = @@__User32GetMenuItemCount__.call(h)
      return [] if cnt < 0
      a = (0...cnt).map do |i|
        AutoIt::Menu.new(h, i)
      end
    end

    def state
      @@__User32GetMenuState__ ||= Win32::API.new('GetMenuState','LII','I', 'user32')
      s = @@__User32GetMenuState__.call(handle, index, MF_BYPOSITION)
      return nil if s == -1
      s
    end

    def enabled?
      (state & (MF_DISABLED | MF_GRAYED)) == 0
    end

    def checked?
      (state & MF_CHECKED) != 0
    end

    def grayed?
      (state & MF_GRAYED) != 0
    end

    def highlighted?
      (state & MF_HILITE) != 0
    end

    def text?
      mi = info(MIIM_TYPE)
      (mi.fType & MFT_STRING) == MFT_STRING 
    end

    def separator?
      mi = info(MIIM_TYPE)
      (mi.fType & MFT_SEPARATOR) == MFT_SEPARATOR
    end

    def text
      return nil if index.nil?
      @@__User32GetMenuString__ ||= Win32::API.new('GetMenuString','LIPII','I', 'user32')
      str = "\0" * 256
      cnt = @@__User32GetMenuString__.call(handle, index, str, str.size - 1, MF_BYPOSITION)
      str[0...cnt]
    end

    def to_s
      states = []
      states << (enabled? ? nil : "Disabled")
      states << (checked? ? "Checked" : nil)
      states << (highlighted? ? "Highlighted" : nil)
      states << (grayed? ? "Grayed" : nil)

      types = []
      types << (text? ? "Text" : nil)
      types << (separator? ? "Separator" : nil)

      "Menu\t[#{handle.to_s(16)}]\n" \
        "Index\t[#{index}]\n" \
          "ID\t[#{item_id}]\n" \
            "Text\t[#{text}]\n" \
              "State\t[#{states.compact.join(", ")}]\n" \
                "Type\t[#{types.compact.join(", ")}]"
    end

    private

    MENUITEMINFO = Struct.new(:cbSize, :fMask, :fType, :fState,
                              :wID, :hSubMenu, :hbmpChecked, :hbmpUnchecked,
                              :dwItemData, :dwTypeData, :cch, :hbmpItem)
    MENUITEMINFO.class_eval do
      def pack
        cbSize = 12 * 4
        [cbSize, fMask, fType, fState,
          wID, hSubMenu, hbmpChecked, hbmpUnchecked,
          dwItemData, dwTypeData, cch, hbmpItem].pack('L12')
      end

      def self.unpack(s)
        new(*s.unpack('L12'))
      end
    end

    def info (mask)
      mi = MENUITEMINFO.new(0, mask, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
      s = mi.pack
      @@__User32GetMenuItemInfo__ ||= Win32::API.new('GetMenuItemInfo','LIBP','B', 'user32') 
      b = @@__User32GetMenuItemInfo__.call(handle, index, 1, s)
      return nil if b != 1
      MENUITEMINFO.unpack(s)
    end
  end
end

