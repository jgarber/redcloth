require 'mkmf'

# do not optimize (takes too much memory and performance gain is negligeable)
$CFLAGS << " -O0 "

dir_config("superredcloth_scan")
have_library("c", "main")

create_makefile("superredcloth_scan")
