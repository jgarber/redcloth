/*
 * redcloth_inline.c.rl
 *
 * Copyright (C) 2009 Jason Garber
 */
#include <ruby.h>
#include "redcloth.h"

%%{

  machine redcloth_inline;
  include redcloth_common "redcloth_common.c.rl";
  include redcloth_inline "redcloth_inline.rl";

}%%

%% write data nofinal;

VALUE
red_pass(VALUE self, VALUE regs, VALUE ref, ID meth, VALUE refs)
{
  VALUE txt = rb_hash_aref(regs, ref);
  if (!NIL_P(txt)) rb_hash_aset(regs, ref, redcloth_inline2(self, txt, refs));
  return rb_funcall(self, meth, 1, regs);
}

VALUE
red_parse_attr(VALUE self, VALUE regs, VALUE ref)
{
  VALUE txt = rb_hash_aref(regs, ref);
  VALUE new_regs = redcloth_attributes(self, txt);
  return rb_funcall(regs, rb_intern("update"), 1, new_regs);
}

VALUE
red_parse_link_attr(VALUE self, VALUE regs, VALUE ref)
{
  VALUE txt = rb_hash_aref(regs, ref);
  VALUE new_regs = red_parse_title(redcloth_link_attributes(self, txt), ref);
  
  return rb_funcall(regs, rb_intern("update"), 1, new_regs);
}

VALUE
red_parse_image_attr(VALUE self, VALUE regs, VALUE ref)
{
  
  return red_parse_title(regs, ref);
}

VALUE
red_parse_title(VALUE regs, VALUE ref)
{
  // Store title/alt
  VALUE txt = rb_hash_aref(regs, ref);
  if ( txt != Qnil ) {
    char *p = RSTRING_PTR(txt) + RSTRING_LEN(txt);
    if (*(p - 1) == ')') {
      char level = -1;
      p--;
      while (p > RSTRING_PTR(txt) && level < 0) {
        switch(*(p - 1)) {
          case '(': ++level; break;
          case ')': --level; break;
        }
        --p;
      }
      VALUE title = STR_NEW(p + 1, RSTRING_PTR(txt) + RSTRING_LEN(txt) - 2 - p );
      if (p > RSTRING_PTR(txt) && *(p - 1) == ' ') --p;
      if (p != RSTRING_PTR(txt)) {
        rb_hash_aset(regs, ref, STR_NEW(RSTRING_PTR(txt), p - RSTRING_PTR(txt) ));
        rb_hash_aset(regs, ID2SYM(rb_intern("title")), title);
      }
    }
  }
  return regs;
}

VALUE
red_pass_code(VALUE self, VALUE regs, VALUE ref, ID meth)
{
  VALUE txt = rb_hash_aref(regs, ref);
  if (!NIL_P(txt)) {
    VALUE txt2 = STR_NEW2("");
    rb_str_cat_escaped_for_preformatted(self, txt2, RSTRING_PTR(txt), RSTRING_PTR(txt) + RSTRING_LEN(txt));
    rb_hash_aset(regs, ref, txt2);
  }
  return rb_funcall(self, meth, 1, regs);
}

VALUE
red_block(VALUE self, VALUE regs, VALUE block, VALUE refs)
{
  ID method;
  VALUE fallback;
  VALUE sym_text = ID2SYM(rb_intern("text"));
  VALUE btype = rb_hash_aref(regs, ID2SYM(rb_intern("type")));
  block = rb_funcall(block, rb_intern("strip"), 0);
  if ((!NIL_P(block)) && !NIL_P(btype))
  {
    method = rb_str_intern(btype);
    if (method == ID2SYM(rb_intern("notextile"))) {
      rb_hash_aset(regs, sym_text, block);
    } else {
      rb_hash_aset(regs, sym_text, redcloth_inline2(self, block, refs));
    }
    if (rb_ary_includes(rb_funcall(self, rb_intern("formatter_methods"), 0), method)) {
      block = rb_funcall(self, SYM2ID(method), 1, regs);
    } else {
      fallback = rb_hash_aref(regs, ID2SYM(rb_intern("fallback")));
      if (!NIL_P(fallback)) {
        rb_str_append(fallback, rb_hash_aref(regs, sym_text));
        CLEAR_REGS();
        rb_hash_aset(regs, sym_text, fallback);
      }
      block = rb_funcall(self, rb_intern("p"), 1, regs);
    }
  }
  return block;
}

VALUE
red_blockcode(VALUE self, VALUE regs, VALUE block)
{
  VALUE btype = rb_hash_aref(regs, ID2SYM(rb_intern("type")));
  if (RSTRING_LEN(block) > 0)
  {
    rb_hash_aset(regs, ID2SYM(rb_intern("text")), block);
    block = rb_funcall(self, rb_intern(RSTRING_PTR(btype)), 1, regs);
  }
  return block;
}

void
red_inc(VALUE regs, VALUE ref)
{
  int aint = 0;
  VALUE aval = rb_hash_aref(regs, ref);
  if (aval != Qnil) aint = NUM2INT(aval);
  rb_hash_aset(regs, ref, INT2NUM(aint + 1));
}

VALUE
redcloth_inline(self, p, pe, refs)
  VALUE self;
  char *p, *pe;
  VALUE refs;
{
  int cs, act;
  char *ts = NULL, *te = NULL, *reg = NULL, *eof = NULL;
  char *orig_p = p;
  VALUE block = STR_NEW2("");
  VALUE regs = Qnil;
  
  %% write init;

  %% write exec;

  return block;
}

/** Append characters to a string, escaping (&, <, >, ", ') using the formatter's escape method.
  * @param str ruby string
  * @param ts  start of character buffer to append
  * @param te  end of character buffer
  */
void
rb_str_cat_escaped(self, str, ts, te)
  VALUE self, str;
  char *ts, *te;
{
  VALUE source_str = STR_NEW(ts, te-ts);
  VALUE escaped_str = rb_funcall(self, rb_intern("escape"), 1, source_str);
  rb_str_concat(str, escaped_str);
}

void
rb_str_cat_escaped_for_preformatted(self, str, ts, te)
  VALUE self, str;
  char *ts, *te;
{
  VALUE source_str = STR_NEW(ts, te-ts);
  VALUE escaped_str = rb_funcall(self, rb_intern("escape_pre"), 1, source_str);
  rb_str_concat(str, escaped_str);
}

VALUE
redcloth_inline2(self, str, refs)
  VALUE self, str, refs;
{
  StringValue(str);
  return redcloth_inline(self, RSTRING_PTR(str), RSTRING_PTR(str) + RSTRING_LEN(str) + 1, refs);
}
