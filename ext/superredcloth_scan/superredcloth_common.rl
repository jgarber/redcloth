%%{

  machine superredcloth_common;

  action A { reg = p; }
  action T { STORE(text); }
  action X { regs = rb_hash_new(); reg = NULL; }
  action cat { CAT(block); }
  action esc { rb_str_cat_escaped(block, tokstart, tokend); }
  action ignore { rb_str_append(block, rb_funcall(rb_formatter, rb_intern("ignore"), 1, regs)); }

  # simple
  CRLF = ( '\r'? '\n' ) ;
  default = ^0 ;
  EOF = 0 ;

  # textile modifiers
  A_LEFT = "<" %{ ASET(align, left) } ;
  A_RIGHT = ">" %{ ASET(align, right) } ;
  A_JUSTIFIED = "<>" %{ ASET(align, justified) } ;
  A_CENTER = "=" %{ ASET(align, center) } ;
  A_PADLEFT = "(" >A %{ AINC(padding-left) } ;
  A_PADRIGHT = ")" >A %{ AINC(padding-right) } ;
  A_HLGN = ( A_LEFT | A_RIGHT | A_JUSTIFIED | A_CENTER | A_PADLEFT | A_PADRIGHT ) ;
  A_LIMIT = ( A_LEFT | A_CENTER | A_RIGHT ) ;
  A_VLGN = ( "-" %{ ASET(valign, middle) } | "^" %{ ASET(valign, top) } | "~" %{ ASET(valign, bottom) } ) ;
  C_CLAS = ( "(" ( [^)#]+ >A %{ STORE(class) } )? ("#" [^)]+ >A %{STORE(id)} )? ")" ) ;
  C_LNGE = ( "[" [^\]]+ >A %{ STORE(lang) } "]" ) ;
  C_STYL = ( "{" [^}]+ >A %{ STORE(style) } "}" ) ;
  S_CSPN = ( "\\" [0-9]+ >A %{ STORE(colspan) } ) ;
  S_RSPN = ( "/" [0-9]+ >A %{ STORE(rowspan) } ) ;
  D_HEADER = "_" %{ ASET(th, true) } ;
  A = ( ( A_HLGN | A_VLGN )* ) ;
  A2 = ( A_LIMIT? ) ;
  S = ( S_CSPN | S_RSPN )* ;
  C = ( C_CLAS | C_STYL | C_LNGE )* ;
  D = ( D_HEADER ) ;
  N_CONT = "_" %{ ASET(start, continue) };
  N_NUM = digit+ >A %{ STORE(start) };
  N = ( N_CONT | N_NUM )? ;
  PUNCT = ( "!" | '"' | "#" | "$" | "%" | "&" | "'" | "," | "--" | "." | "/" | ":" | ";" | "=" | "?" | "\\" | "^" | "`" | "|" | "~" | "[" | "(" | "<" ) ;
  dotspace = ("." " "*) ;

  # text blocks
  trailing = PUNCT - ("'" | '"') ;
  chars = (default - space)+ ;
  phrase = chars -- trailing ;

  # html tags (from Hpricot)
  NameChar = [\-A-Za-z0-9._:?] ;
  Name = [A-Za-z_:] NameChar* ;
  NameAttr = NameChar+ ;
  Q1Attr = [^']* ;
  Q2Attr = [^"]* ;
  UnqAttr = ( space | [^ \t\r\n<>"'] [^ \t\r\n<>]* ) ;
  Nmtoken = NameChar+ ;
  Attr =  NameAttr space* "=" space* ('"' Q2Attr '"' | "'" Q1Attr "'" | UnqAttr space+ ) space* ;
  AttrEnd = ( NameAttr space* "=" space* UnqAttr? | Nmtoken ) ;
  AttrSet = ( Attr | Nmtoken space+ ) ;
  start_tag = "<" Name space+ AttrSet* (AttrEnd)? ">" | "<" Name ">";
  empty_tag = "<" Name space+ AttrSet* (AttrEnd)? "/>" | "<" Name "/>" ;
  end_tag = "</" Name space* ">" ;
  html_comment = "<!--" (default+) :> "-->";

}%%;
