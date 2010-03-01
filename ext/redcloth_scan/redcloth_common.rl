%%{

  machine redcloth_common;

  action A { MARK(); }
  action B { MARK_B(); }
  action ATTR { MARK_ATTR(); }
  action SET_ATTR { SET_ATTRIBUTES(); }
  action T { STORE("text"); }
  action X { CLEAR_REGS(); RESET_REG(); }
  action cat { CAT(block); }

  # simple
  LF = ( '\n' ) ;
  default = ^0 ;
  EOF = 0 ;

  # textile element attributes
  class = [A-Za-z0-9\- _]+ ;
  id = [A-Za-z0-9\-_]+ ;
  style_chars = [A-Za-z0-9: ;\-_#&.%'"];
  style_url = "url(" [a-z0-9'".\\/#?=+@_\-]+ ")";
  style = style_chars (style_chars+ | style_url)* ; # maybe put in uri when in url()
  language = [a-z\-_]+ ;

  A_LEFT = "<" %{ ATTR_SET("align", "left"); } ;
  A_RIGHT = ">" %{ ATTR_SET("align", "right"); } ;
  A_JUSTIFIED = "<>" %{ ATTR_SET("align", "justify"); } ;
  A_CENTER = "=" %{ ATTR_SET("align", "center"); } ;
  A_PADLEFT = "(" when following_hash_is_ol_not_id %{ ATTR_INC("padding-left"); } ;
  A_PADRIGHT = ")" %{ ATTR_INC("padding-right"); } ;
  A_HLGN = ( A_LEFT | A_RIGHT | A_JUSTIFIED | A_CENTER | A_PADLEFT | A_PADRIGHT ) ;
  A_LIMIT = ( A_LEFT | A_CENTER | A_RIGHT ) ;
  A_VLGN = ( "-" %{ ATTR_SET("vertical-align", "middle"); } | "^" %{ ATTR_SET("vertical-align", "top"); } | "~" %{ ATTR_SET("vertical-align", "bottom"); } ) ;
  C_CLASS = class >ATTR %{ STORE_ATTR("class"); } ;
  C_ID = "#" id >ATTR %{ STORE_ATTR("id"); } ;
  C_CLASS_ID = "(" ( C_CLASS | C_ID | C_CLASS C_ID ) ")" ;
  C_LNGE = ( "[" language >ATTR %{ STORE_ATTR("lang"); } "]" ) ;
  C_STYL = ( "{" style >ATTR %{ STORE_ATTR("style"); } "}" ) ;
  S_CSPN = ( "\\" [0-9]+ >ATTR %{ STORE_ATTR("colspan"); } ) ;
  S_RSPN = ( "/" [0-9]+ >ATTR %{ STORE_ATTR("rowspan"); } ) ;
  D_HEADER = "_" %{ ATTR_SET("th", "true"); } ;
  A = ( ( A_HLGN | A_VLGN )* ) ;
  A2 = ( A_LIMIT? ) ;
  S = ( S_CSPN | S_RSPN )* ;
  C = ( C_CLASS_ID | C_STYL | C_LNGE )* ;
  D = ( D_HEADER ) ;
  N_CONT = "_" %{ ATTR_SET("list_continue", "true"); };
  N_NUM = digit+ >ATTR %{ STORE_ATTR("start"); };
  N = ( N_CONT | N_NUM )? ;
  PUNCT = ( "!" | '"' | "#" | "$" | "%" | "&" | "'" | "," | "-" | "." | "/" | ":" | ";" | "=" | "?" | "\\" | "^" | "`" | "|" | "~" | "[" | "]" | "(" | ")" | "<" ) ;
  dotspace = ("." " "*) ;
  indent =  [ \t]* ;
  
  # very un-DRY; Adrian says an action-stripping macro will come in a future Ragel version
  A_LEFT_noactions = "<" ;
  A_RIGHT_noactions = ">" ;
  A_JUSTIFIED_noactions = "<>" ;
  A_CENTER_noactions = "=" ;
  A_PADLEFT_noactions = "(" ;
  A_PADRIGHT_noactions = ")"  ;
  A_HLGN_noactions = ( A_LEFT_noactions | A_RIGHT_noactions | A_JUSTIFIED_noactions | A_CENTER_noactions | A_PADLEFT_noactions | A_PADRIGHT_noactions ) ;
  A_VLGN_noactions = ( "-" | "^" | "~" ) ;
  C_CLASS_noactions = ( "(" ( class )? ("#" id )? ")" ) ;
  C_LNGE_noactions = ( "[" language "]" ) ;
  C_STYL_noactions = ( "{" style "}" ) ;
  A_noactions = ( ( A_HLGN_noactions | A_VLGN_noactions )* ) ;
  C_noactions = ( C_CLASS_noactions | C_STYL_noactions | C_LNGE_noactions )* ;
  C_noquotes_noactions = C_noactions -- '"' ;
  N_CONT_noactions = "_" ;
  N_NUM_noactions = digit+ ;
  N_noactions = ( N_CONT_noactions | N_NUM_noactions )? ;

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
  Attr =  NameAttr "="  ('"' Q2Attr '"' | "'" Q1Attr "'" ) space* ;
  AttrEnd = ( NameAttr space* "=" space* UnqAttr? | Nmtoken ) ;
  AttrSet = ( Attr | Nmtoken space+ ) ;
  
  script_tag_start = ( "<script" [^>]* ">" ) >X >A %T ;
  script_tag_end = ( "</script>" >A %T LF? ) >X ;
  
  code_tag_start = "<code" [^>]* ">" ;
  code_tag_end = "</code>" ;
  
  notextile = "<notextile>" >X LF? default+ >A %T :>> "</notextile>";
  
  # URI tokens (lifted from Mongrel)
  CTL = (cntrl | 127);
  safe = ("$" | "-" | "_" | ".");
  extra = ("!" | "*" | "'" | "(" | ")" | "," | "#");
  reserved = (";" | "/" | "?" | ":" | "@" | "&" | "=" | "+");
  unsafe = (CTL | " " | "\"" | "%" | "<" | ">");
  national = any -- (alpha | digit | reserved | extra | safe | unsafe);
  unreserved = (alpha | digit | safe | extra | national);
  escape = ("%" xdigit xdigit);
  uchar = (unreserved | escape);
  pchar = (uchar | ":" | "@" | "&" | "=" | "+");
  scheme = ( alpha | digit | "+" | "-" | "." )+ ;
  absolute_uri = (scheme ":" (uchar | reserved )*);
  safepath = (pchar* (alpha | digit | safe) pchar*) ;
  path = (safepath ( "/" pchar* )*) ;
  query = ( uchar | reserved )* ;
  param = ( pchar | "/" )* ;
  params = (param ( ";" param )*) ;
  rel_path = (path (";" params)?) ("?" query)?;
  absolute_path = ("/"+ rel_path?);
  target = ("#" pchar*) ;
  uri = (target | absolute_uri | absolute_path | rel_path) ;

  # common
  title = ( '(' default+ >ATTR %{ STORE_ATTR("title"); } :> ')' ) ;
  word = ( alnum | safe | " " ) ;
  mspace = ( ( " " | "\t" | LF )+ ) -- LF{2} ;
  mtext = ( chars (mspace chars)* ) ;
  

}%%;
