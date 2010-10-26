# -*- ruby -*-

require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)

Hoe.spec 'autoit' do
  developer('Mario Freitas', 'imkira@gmail.com')
  developer('Nicholas Green', 'cruzmail.ngreen@gmail.com')
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--colour --format nested'
  t.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new('spec:rcov') do |t|
  t.rcov = true
  t.rcov_opts = '--exclude spec/'
  t.rspec_opts = '--colour --format nested'
  t.pattern = 'spec/**/*_spec.rb'
end

# vim: syntax=ruby
