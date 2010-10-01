
require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)
require 'autoit'

class Util
  def self.async_sys cmd
    Thread.new(cmd) { |cmd|
      system(cmd)
    }
  end
end

