/*
 * redcloth_scan.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
#define redcloth_scan_c

#include <ruby.h>
#include "redcloth.h"

VALUE mRedCloth, super_ParseError, super_RedCloth, super_HTML, super_LATEX;
int SYM_escape_preformatted, SYM_escape_attributes;

%%{

  machine redcloth_scan;
  include redcloth_common "redcloth_common.rl";

  action extend { extend = rb_hash_aref(regs, ID2SYM(rb_intern("type"))); }

  # blocks
  notextile_tag_start = "<notextile>" ;
  notextile_tag_end = "</notextile>" LF? ;
  noparagraph_line_start = " "+ ;
  notextile_block_start = ( "notextile" >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) " "+ ) ;
  pre_tag_start = "<pre" [^>]* ">" (space* "<code>")? ;
  pre_tag_end = ("</code>" space*)? "</pre>" LF? ;
  pre_block_start = ( "pre" >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) " "+ ) ;
  bc_start = ( "bc" >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) " "+ ) ;
  bq_start = ( "bq" >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) ( ":" %A uri %{ STORE(cite) } )? " "+ ) ;
  non_ac_btype = ( "bq" | "bc" | "pre" | "notextile" );
  btype = (alpha alnum*) -- (non_ac_btype | "fn" digit+);
  block_start = ( btype >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) " "+ ) >B %{ STORE_B(fallback) };
  all_btypes = btype | non_ac_btype;
  next_block_start = ( all_btypes A_noactions C_noactions :> "."+ " " ) >A @{ p = reg - 1; } ;
  double_return = LF{2,} ;
  block_end = ( double_return | EOF );
  ftype = ( "fn" >A %{ STORE(type) } digit+ >A %{ STORE(id) } ) ;
  footnote_start = ( ftype A C :> dotspace ) ;
  ul = "*" %{nest++; list_type = "ul";};
  ol = "#" %{nest++; list_type = "ol";};
  list_start  = ( ( ul | ol )+ N A C :> " "+ ) >{nest = 0;} ;
  dt_start = "-" . " "+ ;
  dd_start = ":=" ;
  long_dd  = dd_start " "* LF %{ ADD_BLOCK(); ASET(type, dd); } any+ >A %{ TRANSFORM(text) } :>> "=:" ;
  dl_start = (dt_start mtext (LF dt_start mtext)* " "* dd_start)  ;
  blank_line = LF;
  link_alias = ( "[" >{ ASET(type, ignore) } %A chars %T "]" %A uri %{ STORE_URL(href); } ) ;
  
  # image lookahead
  IMG_A_LEFT = "<" %{ ASET(float, left) } ;
  IMG_A_RIGHT = ">" %{ ASET(float, right) } ;
  aligned_image = ( "["? "!" (IMG_A_LEFT | IMG_A_RIGHT) ) >A @{ p = reg - 1; } ;
  
  # html blocks
  BlockTagName = Name - ("pre" | "notextile" | "a" | "applet" | "basefont" | "bdo" | "br" | "font" | "iframe" | "img" | "map" | "object" | "param" | "q" | "script" | "span" | "sub" | "sup" | "abbr" | "acronym" | "cite" | "code" | "del" | "dfn" | "em" | "ins" | "kbd" | "samp" | "strong" | "var" | "b" | "big" | "i" | "s" | "small" | "strike" | "tt" | "u");
  block_start_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? ">" | "<" BlockTagName ">";
  block_empty_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? "/>" | "<" BlockTagName "/>" ;
  block_end_tag = "</" BlockTagName space* ">" ;
  html_start = indent >B %{STORE_B(indent_before_start)} block_start_tag >B %{STORE_B(start_tag)}  indent >B %{STORE_B(indent_after_start)} ;
  html_end = indent >B %{STORE_B(indent_before_end)} block_end_tag >B %{STORE_B(end_tag)} (indent LF?) >B %{STORE_B(indent_after_end)} ;
  standalone_html = indent (block_start_tag | block_empty_tag | block_end_tag) indent LF+;
  html_end_terminating_block = ( LF indent block_end_tag ) >A @{ p = reg - 1; } ;

  # tables
  para = ( default+ ) -- LF ;
  btext = para ( LF{2} )? ;
  tddef = ( D? S A C :> dotspace ) ;
  td = ( tddef? btext >A %T :> "|" >{PASS(table, text, td);} ) >X ;
  trdef = ( A C :> dotspace ) ;
  tr = ( trdef? "|" %{INLINE(table, tr_open);} td+ ) >X %{INLINE(table, tr_close);} ;
  trows = ( tr (LF >X tr)* ) ;
  tdef = ( "table" >X A C :> dotspace LF ) ;
  table = ( tdef? trows >{table = rb_str_new2(""); INLINE(table, table_open);} ) >{ reg = NULL; } ;

  # info
  redcloth_version = ("RedCloth" >A ("::" | " " ) "VERSION"i ":"? " ")? %{STORE(prefix)} "RedCloth::VERSION" (LF* EOF | double_return) ;

  pre_tag := |*
    pre_tag_end         { CAT(block); DONE(block); fgoto main; };
    default => esc_pre;
  *|;
  
  pre_block := |*
    EOF { 
      ADD_BLOCKCODE(); 
      fgoto main; 
    };
    double_return { 
      if (NIL_P(extend)) { 
        ADD_BLOCKCODE(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
      } 
    };
    double_return next_block_start { 
      if (NIL_P(extend)) { 
        ADD_BLOCKCODE(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        END_EXTENDED(); 
        fgoto main; 
      } 
    };
    default => esc_pre;
  *|;

  script_tag := |*
    script_tag_end   { CAT(block); ASET(type, ignore); ADD_BLOCK(); fgoto main; };
    EOF              { ASET(type, ignore); ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;

  noparagraph_line := |*
    LF  { ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;

  notextile_tag := |*
    notextile_tag_end   { ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;
  
  notextile_block := |*
    EOF {
      ADD_BLOCK();
      fgoto main;
    };
    double_return {
      if (NIL_P(extend)) {
        ADD_BLOCK();
        CAT(html);
        fgoto main;
      } else {
        CAT(block);
        ADD_EXTENDED_BLOCK();
        CAT(html);
      }
    };
    double_return next_block_start {
      if (NIL_P(extend)) {
        ADD_BLOCK();
        CAT(html);
        fgoto main;
      } else {
        CAT(block);
        ADD_EXTENDED_BLOCK();
        END_EXTENDED();
        fgoto main; 
      } 
    };
    default => cat;
  *|;
 
  html := |*
    html_end        { ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;

  bc := |*
    EOF { 
      ADD_BLOCKCODE(); 
      INLINE(html, bc_close); 
      plain_block = rb_str_new2("p"); 
      fgoto main;
    };
    double_return { 
      if (NIL_P(extend)) { 
        ADD_BLOCKCODE(); 
        INLINE(html, bc_close); 
        plain_block = rb_str_new2("p"); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        CAT(html); 
      } 
    };
    double_return next_block_start { 
      if (NIL_P(extend)) { 
        ADD_BLOCKCODE(); 
        INLINE(html, bc_close); 
        plain_block = rb_str_new2("p"); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        CAT(html); 
        INLINE(html, bc_close); 
        plain_block = rb_str_new2("p");  
        END_EXTENDED(); 
        fgoto main; 
      } 
    };
    default => esc_pre;
  *|;

  bq := |*
    EOF { 
      ADD_BLOCK(); 
      INLINE(html, bq_close); 
      fgoto main; 
    };
    double_return { 
      if (NIL_P(extend)) { 
        ADD_BLOCK(); 
        INLINE(html, bq_close); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
      } 
    };
    double_return next_block_start { 
      if (NIL_P(extend)) { 
        ADD_BLOCK(); 
        INLINE(html, bq_close); 
        fgoto main; 
      } else {
        ADD_EXTENDED_BLOCK(); 
        INLINE(html, bq_close); 
        END_EXTENDED(); 
        fgoto main; 
      }
    };
    html_end_terminating_block { 
        if (NIL_P(extend)) { 
          ADD_BLOCK(); 
          INLINE(html, bq_close); 
          fgoto main; 
        } else {
          ADD_EXTENDED_BLOCK(); 
          INLINE(html, bq_close); 
          END_EXTENDED(); 
          fgoto main; 
        }
      };
    default => cat;
  *|;

  block := |*
    EOF { 
      ADD_BLOCK(); 
      fgoto main;
    };
    double_return {
      if (NIL_P(extend)) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
      } 
    };
    double_return next_block_start { 
      if (NIL_P(extend)) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
        END_EXTENDED(); 
        fgoto main; 
      }      
    };
    html_end_terminating_block { 
      if (NIL_P(extend)) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
        END_EXTENDED(); 
        fgoto main; 
      }      
    };
    LF list_start { 
      ADD_BLOCK(); 
      list_layout = rb_ary_new(); 
      LIST_ITEM(); 
      fgoto list; 
    };
    
    default => cat;
  *|;

  footnote := |*
    block_end       { ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;

  list := |*
    LF list_start   { ADD_BLOCK(); LIST_ITEM(); };
    block_end       { ADD_BLOCK(); nest = 0; LIST_CLOSE(); fgoto main; };
    default => cat;
  *|;

  dl := |*
    LF dt_start     { ADD_BLOCK(); ASET(type, dt); };
    dd_start        { ADD_BLOCK(); ASET(type, dd); };
    long_dd         { INLINE(html, dd); };
    block_end       { ADD_BLOCK(); INLINE(html, dl_close);  fgoto main; };
    default => cat;
  *|;

  main := |*
    noparagraph_line_start  { ASET(type, ignored_line); fgoto noparagraph_line; };
    notextile_tag_start { ASET(type, notextile); fgoto notextile_tag; };
    notextile_block_start { ASET(type, notextile); fgoto notextile_block; };
    script_tag_start { CAT(block); fgoto script_tag; };
    pre_tag_start       { ASET(type, notextile); CAT(block); fgoto pre_tag; };
    pre_block_start { fgoto pre_block; };
    standalone_html { ASET(type, html); CAT(block); ADD_BLOCK(); };
    html_start      { ASET(type, html_block); fgoto html; };
    bc_start        { INLINE(html, bc_open); ASET(type, code); plain_block = rb_str_new2("code"); fgoto bc; };
    bq_start        { INLINE(html, bq_open); ASET(type, p); fgoto bq; };
    block_start     { fgoto block; };
    footnote_start  { fgoto footnote; };
    list_start      { list_layout = rb_ary_new(); LIST_ITEM(); fgoto list; };
    dl_start        { p = ts; INLINE(html, dl_open); ASET(type, dt); fgoto dl; };
    table           { INLINE(table, table_close); DONE(table); fgoto block; };
    link_alias      { rb_hash_aset(refs_found, rb_hash_aref(regs, ID2SYM(rb_intern("text"))), rb_hash_aref(regs, ID2SYM(rb_intern("href")))); DONE(block); };
    aligned_image   { rb_hash_aset(regs, ID2SYM(rb_intern("type")), plain_block); fgoto block; };
    redcloth_version { INLINE(html, redcloth_version); };
    blank_line => cat;
    default
    { 
      CLEAR_REGS();
      rb_hash_aset(regs, ID2SYM(rb_intern("type")), plain_block);
      CAT(block);
      fgoto block;
    };
    EOF;
  *|;

}%%

%% write data nofinal;

VALUE
redcloth_transform(self, p, pe, refs)
  VALUE self;
  char *p, *pe;
  VALUE refs;
{
  char *orig_p = p, *orig_pe = pe;
  int cs, act, nest;
  char *ts = NULL, *te = NULL, *reg = NULL, *bck = NULL, *eof = NULL;
  VALUE html = rb_str_new2("");
  VALUE table = rb_str_new2("");
  VALUE block = rb_str_new2("");
  VALUE regs; CLEAR_REGS()
  
  
  VALUE list_layout = Qnil;
  char *list_type = NULL;
  VALUE list_index = rb_ary_new();
  int list_continue = 0;
  VALUE plain_block = rb_str_new2("p");
  VALUE extend = Qnil;
  char listm[10] = "";
  VALUE refs_found = rb_hash_new();
  
  %% write init;

  %% write exec;

  if (RSTRING(block)->len > 0)
  {
    ADD_BLOCK();
  }

  if ( NIL_P(refs) && rb_funcall(refs_found, rb_intern("empty?"), 0) == Qfalse ) {
    return redcloth_transform(self, orig_p, orig_pe, refs_found);
  } else {
    rb_funcall(self, rb_intern("after_transform"), 1, html);
    return html;
  }
}

VALUE
redcloth_transform2(self, str)
  VALUE self, str;
{
  rb_str_cat2(str, "\n");
  StringValue(str);
  rb_funcall(self, rb_intern("before_transform"), 1, str);
  return redcloth_transform(self, RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1, Qnil);
}

/*
 * Converts special characters into HTML entities.
 */
static VALUE
redcloth_html_esc(int argc, VALUE* argv, VALUE self) //(self, str, level)
{
  VALUE str, level;
  
  rb_scan_args(argc, argv, "11", &str, &level);
  
  VALUE new_str = rb_str_new2("");
  StringValue(str);
  
  if (RSTRING(str)->len == 0)
    return new_str;
  
  char *ts = RSTRING(str)->ptr, *te = RSTRING(str)->ptr + RSTRING(str)->len;
  char *t = ts, *t2 = ts, *ch = NULL;
  if (te <= ts) return;

  while (t2 < te) {
    ch = NULL;
    
    // normal + pre
    switch (*t2)
    {
      case '&':  ch = "amp";    break;
      case '>':  ch = "gt";     break;
      case '<':  ch = "lt";     break;
    }
    
    // normal (non-pre)
    if (level != SYM_escape_preformatted) {
      switch (*t2)
      {
        case '\n': ch = "br";     break;
        case '"' : ch = "quot";   break;
        case '\'': 
          ch = (level == SYM_escape_attributes) ? "apos" : "squot";
          break;
      }
    }
    
    if (ch != NULL)
    {
      if (t2 > t)
        rb_str_cat(new_str, t, t2-t);
      rb_str_concat(new_str, rb_funcall(self, rb_intern(ch), 1, rb_hash_new()));
      t = t2 + 1;
    }

    t2++;
  }
  if (t2 > t)
    rb_str_cat(new_str, t, t2-t);
  
  return new_str;
}

/*
 * Converts special characters into LaTeX entities.
 */
static VALUE
redcloth_latex_esc(VALUE self, VALUE str)
{  
  VALUE new_str = rb_str_new2("");
  StringValue(str);
  
  char *ts = RSTRING(str)->ptr, *te = RSTRING(str)->ptr + RSTRING(str)->len;
  char *t = ts, *t2 = ts, *ch = NULL;
  if (te <= ts) return;

  while (t2 < te) {
    ch = NULL;
    
    switch (*t2) 
    { 
      case '{':  ch = "#123";   break;
      case '}':  ch = "#125";   break;
      case '\\': ch = "#92";    break;
      case '#':  ch = "#35";    break;
      case '$':  ch = "#36";    break;
      case '%':  ch = "#37";    break;
      case '&':  ch = "amp";    break;
      case '_':  ch = "#95";    break;
      case '^':  ch = "circ";   break;
      case '~':  ch = "tilde";  break;
      case '<':  ch = "lt";     break;
      case '>':  ch = "gt";     break;
      case '\n': ch = "#10";    break;
    }

    if (ch != NULL)
    {
      if (t2 > t)
        rb_str_cat(new_str, t, t2-t);
      VALUE opts = rb_hash_new();
      rb_hash_aset(opts, ID2SYM(rb_intern("text")), rb_str_new2(ch));
      rb_str_concat(new_str, rb_funcall(self, rb_intern("entity"), 1, opts));
      t = t2 + 1;
    }

    t2++;
  }
  if (t2 > t)
    rb_str_cat(new_str, t, t2-t);
  
  return new_str;
}

static VALUE
redcloth_to(self, formatter)
  VALUE self, formatter;
{
  char *pe, *p;
  int len = 0;
  
  rb_funcall(self, rb_intern("delete!"), 1, rb_str_new2("\r"));
  VALUE working_copy = rb_obj_clone(self);
  rb_extend_object(working_copy, formatter);
  if (rb_funcall(working_copy, rb_intern("lite_mode"), 0) == Qtrue) {
    return redcloth_inline2(working_copy, self, rb_hash_new());
  } else {
    return redcloth_transform2(working_copy, self);
  }
}

void Init_redcloth_scan()
{
  mRedCloth = rb_define_module("RedCloth");
  /* A Textile document that can be converted to other formats. See
   the README for Textile syntax. */
  super_RedCloth = rb_define_class_under(mRedCloth, "TextileDoc", rb_cString);
  rb_define_method(super_RedCloth, "to", redcloth_to, 1);
  super_ParseError = rb_define_class_under(super_RedCloth, "ParseError", rb_eException);
  /* Escaping */
  rb_define_method(super_RedCloth, "html_esc", redcloth_html_esc, -1);
  rb_define_method(super_RedCloth, "latex_esc", redcloth_latex_esc, 1);
  SYM_escape_preformatted   = ID2SYM(rb_intern("html_escape_preformatted"));
  SYM_escape_attributes     = ID2SYM(rb_intern("html_escape_attributes"));
}
