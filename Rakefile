# encoding: utf-8
require 'rubygems'
require 'bundler'
Bundler.setup
Bundler::GemHelper.install_tasks
ENV['RUBYOPT'] = nil # Necessary to prevent Bundler from *&^%$#ing up rake-compiler.

require 'rake/clean'

Dir['tasks/**/*.rake'].each { |rake| load File.expand_path(rake) }