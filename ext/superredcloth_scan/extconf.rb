require 'mkmf'

dir_config("superredcloth_scan")
have_library("c", "main")

create_makefile("superredcloth_scan")
