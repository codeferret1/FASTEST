# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.spec 'autoit' do
  developer('Mario Freitas', 'imkira@gmail.com')
  developer('Nicholas Green', 'FIXME')

  # self.rubyforge_name = 'autoitx' # if different than 'autoit'
  self.rspec_options = ['--options', 'spec/spec.opts']
end

require 'spec/rake/verify_rcov'

desc "Run all specs with RCov"
Spec::Rake::SpecTask.new('spec:rcov') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

# vim: syntax=ruby
