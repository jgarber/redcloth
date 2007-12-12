require 'mkmf'

if /darwin9/ =~ RUBY_PLATFORM
  # OSX 10.5 doesn't like the default "-Os"
  $CFLAGS << " -O1 "
end

dir_config("superredcloth_scan")
have_library("c", "main")

create_makefile("superredcloth_scan")
