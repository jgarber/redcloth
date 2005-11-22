$:.unshift(File.dirname(__FILE__))

unless defined? RedCloth
  require 'base'
  require 'textile'
  require 'markdown'
end

require 'docbook'