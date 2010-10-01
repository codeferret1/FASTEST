
require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)
require 'autoit'

class Util
  def self.async_sys (cmd, cwd = Dir.pwd)
    options = {
      :app_name => cmd,
      :cwd => cwd,
      :creation_flags => Windows::Process::DETACHED_PROCESS
    }
    begin
      ::Process.create(options).process_id
    rescue
      nil
    end
  end
end

