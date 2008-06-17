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
  mtext_without_attributes = ( mtext ) >X ;
  
  main := |*
    
    mtext_with_attributes { SET_ATTRIBUTES(); } ;
    mtext ;
    
  *|;

}%%

%% write data nofinal;


VALUE
redcloth_attributes(self, p, pe)
  VALUE self;
  char *p, *pe;
{
  int cs, act;
  char *ts, *te, *reg, *eof;
  VALUE regs = rb_hash_new();
  
  %% write init;

  %% write exec;

  return regs;
}

VALUE
redcloth_attributes2(self, str)
  VALUE self, str;
{
  StringValue(str);
  return redcloth_attributes(self, RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1);
}