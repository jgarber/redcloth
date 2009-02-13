/*
 * redcloth_attributes.c.rl
 *
 * Copyright (C) 2008 Jason Garber
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
  char *ts, *te, *reg, *bck, *eof;
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
  VALUE regs = redcloth_attribute_parser(cs, self, RSTRING_PTR(str), RSTRING_PTR(str) + RSTRING_LEN(str) + 1);
  
  // Store title/alt
  VALUE name = rb_hash_aref(regs, ID2SYM(rb_intern("name")));
  if ( name != Qnil ) {
    char *p = RSTRING_PTR(name) + RSTRING_LEN(name);
    if (*(p - 1) == ')') {
      char level = -1;
      p--;
      while (p > RSTRING_PTR(name) && level < 0) {
        switch(*(p - 1)) {
          case '(': ++level; break;
          case ')': --level; break;
        }
        --p;
      }
      VALUE title = rb_str_new(p + 1, RSTRING_PTR(name) + RSTRING_LEN(name) - 2 - p );
      if (p > RSTRING_PTR(name) && *(p - 1) == ' ') --p;
      if (p != RSTRING_PTR(name)) {
        rb_hash_aset(regs, ID2SYM(rb_intern("name")), rb_str_new(RSTRING_PTR(name), p - RSTRING_PTR(name) ));
        rb_hash_aset(regs, ID2SYM(rb_intern("title")), title);
      }
    }
  }
  
  return regs;
}