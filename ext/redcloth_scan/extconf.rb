require 'mkmf'

$CFLAGS << " -O0 " # do not optimize (takes too much memory and performance gain is negligeable)

dir_config("superredcloth_scan")
have_library("c", "main")

create_makefile("superredcloth_scan")
