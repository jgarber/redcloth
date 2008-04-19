require 'mkmf'

$CFLAGS << " -O2 "

### It seems to work fine without these
# dir_config("redcloth_scan")
# have_library("c", "main")

create_makefile("redcloth_scan")
