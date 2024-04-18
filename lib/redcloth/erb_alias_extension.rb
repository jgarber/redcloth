
require 'erb'
require 'redcloth/erb_extension'

class ERB
  module Util
    alias t textilize
    module_function :t
  end
end

begin
  include ERB::Util
rescue LoadError
end
