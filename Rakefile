# encoding: utf-8
require 'rubygems'
require 'bundler'
Bundler.setup
ENV['RUBYOPT'] = nil # Necessary to prevent Bundler from *&^%$#ing up rake-compiler.

require 'rake/clean'

if File.directory? "ragel"
  Bundler::GemHelper.install_tasks
  Bundler.setup(:development)
  Dir['tasks/**/*.rake'].each { |rake| load File.expand_path(rake) }
else
  # Omit generation/compile tasks. In a gem package we only need testing tasks.
  load 'tasks/rspec.rake'
end