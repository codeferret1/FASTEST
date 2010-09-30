
require 'rubygems'
require 'bundler'
Bundler.require(:default)

module AutoIt
  VERSION = '1.0.0'
end

# load all .rb files
autoit = File.join(File.dirname(__FILE__), 'autoit', '**', '*.rb') 
Dir.glob(autoit).each do |rb|
  #puts "Loading #{rb}..."
  require rb
end

