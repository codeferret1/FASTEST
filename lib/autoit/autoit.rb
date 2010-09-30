require 'win32ole'
require 'ostruct'

module AutoIt
  # COM interface for AutoItX3 Control object
  COM = WIN32OLE.new('AutoItX3.Control')  
end

