/*
 * redcloth_attributes.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
#include <ruby.h>
#include "redcloth.h"

%%{

  machine redcloth_attributes;
  include redcloth_common "redcloth_common.rl";
  
  C2_CLAS = ( "(" ( [^)#]+ >A %{ STORE(class_buf) } )? ("#" [^)]+ >A %{STORE(id_buf)} )? ")" ) ;
  C2_LNGE = ( "[" [^\]]+ >A %{ STORE(lang_buf) } "]" ) ;
  C2_STYL = ( "{" [^}]+ >A %{ STORE(style_buf) } "}" ) ;
  C2 = ( C2_CLAS | C2_STYL | C2_LNGE )+ ;

  mtext_with_attributes = ( C2 mtext >A %T ) >X ;

  inline := |*

    mtext_with_attributes { SET_ATTRIBUTES(); } ;

  *|;

  link_text_with_attributes = C2 "."* " "* ( mtext+ ) >A %{ STORE(name) } ;
  link_text_without_attributes = ( mtext+ ) >B %{ STORE_B(name_without_attributes) } ;

  link_says := |*

    link_text_with_attributes { SET_ATTRIBUTES(); } ;
    link_text_without_attributes { SET_ATTRIBUTE("name_without_attributes", "name"); } ;

  *|;

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
  VALUE buf = Qnil;
  
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
  return redcloth_attribute_parser(cs, self, RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1);
}

VALUE
redcloth_link_attributes(self, str)
  VALUE self, str;
{
  StringValue(str);
  int cs = redcloth_attributes_en_link_says;
  return redcloth_attribute_parser(cs, self, RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1);
}