/*
 * redcloth_attributes.c.rl
 *
 * Copyright (C) 2009 Jason Garber
 */
#include <ruby.h>
#include "redcloth.h"

%%{

  machine redcloth_attributes;
  include redcloth_common "redcloth_common.c.rl";
  include redcloth_attributes "redcloth_attributes.rl";

}%%

%% write data nofinal;


VALUE
redcloth_attribute_parser(machine, self, p, pe)
  int machine;
  VALUE self;
  char *p, *pe;
{
  int cs, act;
  char *ts = 0, *te = 0, *reg = 0, *bck = NULL, *eof = NULL;
  VALUE regs = rb_hash_new();

  %% write init;

  cs = machine;

  %% write exec;

  return regs;
}

VALUE
redcloth_attributes(self, str)
  VALUE self, str;
{
  StringValue(str);
  int cs = redcloth_attributes_en_inline;
  return redcloth_attribute_parser(cs, self, RSTRING_PTR(str), RSTRING_PTR(str) + RSTRING_LEN(str) + 1);
}

VALUE
redcloth_link_attributes(self, str)
  VALUE self, str;
{
  StringValue(str);
  int cs = redcloth_attributes_en_link_says;
  return redcloth_attribute_parser(cs, self, RSTRING_PTR(str), RSTRING_PTR(str) + RSTRING_LEN(str) + 1);
}