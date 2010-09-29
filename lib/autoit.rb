require 'win32ole'
require 'ostruct'

module AutoIt
  VERSION = '1.0.0'

  # COM interface for AutoItX3 Control object
  COM = WIN32OLE.new('AutoItX3.Control')  
end

require File.join(File.dirname(__FILE__), 'autoit', 'window')
require File.join(File.dirname(__FILE__), 'autoit', 'process')

