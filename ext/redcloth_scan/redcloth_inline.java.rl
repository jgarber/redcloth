/*
 * redcloth_inline.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.CallbackFactory;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.load.BasicLibraryService;

import org.jruby.util.ByteList;

public class RedclothInline extends RedclothScanService.Base {

%%{

  machine redcloth_inline;
  include redcloth_common "redcloth_common.java.rl";

  # links
  mtext_noquotes = mtext -- '"' ;
  quoted_mtext = '"' mtext_noquotes '"' ;
  mtext_including_quotes = (mtext_noquotes ' "' mtext_noquotes '" ' mtext_noquotes?)+ ;
  link_says = ( C_noactions "."* " "* ((quoted_mtext | mtext_including_quotes | mtext_noquotes) -- '":') ) >A %{ STORE("link_text"); } ;
  link_says_noquotes_noactions = ( C_noquotes_noactions "."* " "* ((mtext_noquotes) -- '":') ) ;
  link = ( '"' link_says '":' %A uri %{ STORE_URL("href"); } ) >X ;
  link_noquotes_noactions = ( '"' link_says_noquotes_noactions '":' uri ) ;
  bracketed_link = ( '["' link_says '":' %A uri %{ STORE("href"); } :> "]" ) >X ;

  # images
  image_src = ( uri ) >A %{ STORE("src"); } ;
  image_is = ( A2 C ". "? image_src :> title? ) ;
  image_link = ( ":" uri >A %{ STORE_URL("href"); } ) ;
  image = ( "["? "!" image_is "!" %A image_link? "]"? ) >X ;

  # footnotes
  footno = "[" >X %A digit+ %T "]" ;

  # markup
  end_markup_phrase = (" " | PUNCT | EOF | LF) @{ fhold; };
  code = "["? "@" >X mtext >A %T :> "@" "]"? ;
  code_tag_start = "<code" [^>]* ">" ;
  code_tag_end = "</code>" ;
  script_tag = ( "<script" [^>]* ">" (default+ -- "</script>") "</script>" LF? ) >X >A %T ;
  notextile = "<notextile>" >X (default+ -- "</notextile>") >A %T "</notextile>";
  strong = "["? "*" >X mtext >A %T :> "*" "]"? ;
  b = "["? "**" >X mtext >A %T :> "**" "]"? ;
  em = "["? "_" >X mtext >A %T :> "_" "]"? ;
  i = "["? "__" >X mtext >A %T :> "__" "]"? ;
  del = "[-" >X C ( mtext ) >A %T :>> "-]" ;
  emdash_parenthetical_phrase_with_spaces = " -- " mtext " -- " ;
  del_phrase = (( " " >A %{ STORE("beginning_space"); } "-") >X C ( mtext ) >A %T :>> ( "-" end_markup_phrase )) - emdash_parenthetical_phrase_with_spaces ;
  ins = "["? "+" >X mtext >A %T :> "+" "]"? ;
  sup = "[^" >X mtext >A %T :> "^]" ;
  sup_phrase = ( "^" when starts_phrase) >X ( mtext ) >A %T :>> ( "^" end_markup_phrase ) ;
  sub = "[~" >X mtext >A %T :> "~]" ;
  sub_phrase = ( "~" when starts_phrase) >X ( mtext ) >A %T :>> ( "~" end_markup_phrase ) ;
  span = "[%" >X mtext >A %T :> "%]" ;
  span_phrase = (("%" when starts_phrase) >X ( mtext ) >A %T :>> ( "%" end_markup_phrase )) ;
  cite = "["? "??" >X mtext >A %T :> "??" "]"? ;
  ignore = "["? "==" >X %A mtext %T :> "==" "]"? ;
  snip = "["? "```" >X %A mtext %T :> "```" "]"? ;
  
  # quotes
  quote1 = "'" >X %A mtext %T :> "'" ;
  non_quote_chars_or_link = (chars -- '"') | link_noquotes_noactions ;
  mtext_inside_quotes = ( non_quote_chars_or_link (mspace non_quote_chars_or_link)* ) ;
  html_tag_up_to_attribute_quote = "<" Name space+ NameAttr space* "=" space* ;
  quote2 = ('"' >X %A ( mtext_inside_quotes - (mtext_inside_quotes html_tag_up_to_attribute_quote ) ) %T :> '"' ) ;
  multi_paragraph_quote = (('"' when starts_line) >X  %A ( chars -- '"' ) %T );
  
  # html
  start_tag = ( "<" Name space+ AttrSet* (AttrEnd)? ">" | "<" Name ">" ) >X >A %T ;
  empty_tag = ( "<" Name space+ AttrSet* (AttrEnd)? "/>" | "<" Name "/>" ) >X >A %T ;
  end_tag = ( "</" Name space* ">" ) >X >A %T ;
  html_comment = ("<!--" (default+) :>> "-->") >X >A %T;

  # glyphs
  ellipsis = ( " "? >A %T "..." ) >X ;
  emdash = "--" ;
  arrow = "->" ;
  endash = " - " ;
  acronym = ( [A-Z] >A [A-Z0-9]{2,} %T "(" default+ >A %{ STORE("title"); } :> ")" ) >X ;
  caps_noactions = upper{3,} ;
  caps = ( caps_noactions >A %*T ) >X ;
  dim_digit = [0-9.]+ ;
  prime = ("'" | '"')?;
  dim_noactions = dim_digit prime (("x" | " x ") dim_digit prime) %T (("x" | " x ") dim_digit prime)? ;
  dim = dim_noactions >X >A %T ;
  tm = [Tt] [Mm] ;
  trademark = " "? ( "[" tm "]" | "(" tm ")" ) ;
  reg = [Rr] ;
  registered = " "? ( "[" reg "]" | "(" reg ")" ) ;
  cee = [Cc] ;
  copyright = ( "[" cee "]" | "(" cee ")" ) ;
  entity = ( "&" %A ( '#' digit+ | ( alpha ( alpha | digit )+ ) ) %T ';' ) >X ;
  
  # info
  redcloth_version = "[RedCloth::VERSION]" ;

  other_phrase = phrase -- dim_noactions;

  code_tag := |*
    code_tag_end { CAT(block); fgoto main; };
    default => esc_pre;
  *|;

  main := |*
    
    image { INLINE(block, "image"); };
    
    link { PARSE_LINK_ATTR("link_text"); PASS(block, "name", "link"); };
    bracketed_link { PARSE_LINK_ATTR("link_text"); PASS(block, "name", "link"); };
    
    code { PARSE_ATTR("text"); PASS_CODE(block, "text", "code", opts); };
    code_tag_start { CAT(block); fgoto code_tag; };
    notextile { INLINE(block, "notextile"); };
    strong { PARSE_ATTR("text"); PASS(block, "text", "strong"); };
    b { PARSE_ATTR("text"); PASS(block, "text", "b"); };
    em { PARSE_ATTR("text"); PASS(block, "text", "em"); };
    i { PARSE_ATTR("text"); PASS(block, "text", "i"); };
    del { PASS(block, "text", "del"); };
    del_phrase { PASS(block, "text", "del_phrase"); };
    ins { PARSE_ATTR("text"); PASS(block, "text", "ins"); };
    sup { PARSE_ATTR("text"); PASS(block, "text", "sup"); };
    sup_phrase { PARSE_ATTR("text"); PASS(block, "text", "sup_phrase"); };
    sub { PARSE_ATTR("text"); PASS(block, "text", "sub"); };
    sub_phrase { PARSE_ATTR("text"); PASS(block, "text", "sub_phrase"); };
    span { PARSE_ATTR("text"); PASS(block, "text", "span"); };
    span_phrase { PARSE_ATTR("text"); PASS(block, "text", "span_phrase"); };
    cite { PARSE_ATTR("text"); PASS(block, "text", "cite"); };
    ignore => ignore;
    snip { PASS(block, "text", "snip"); };
    quote1 { PASS(block, "text", "quote1"); };
    quote2 { PASS(block, "text", "quote2"); };
    multi_paragraph_quote { PASS(block, "text", "multi_paragraph_quote"); };
    
    ellipsis { INLINE(block, "ellipsis"); };
    emdash { INLINE(block, "emdash"); };
    endash { INLINE(block, "endash"); };
    arrow { INLINE(block, "arrow"); };
    caps { System.err.println("MATCHED caps"); INLINE(block, "caps"); };
    acronym { INLINE(block, "acronym"); };
    dim { INLINE(block, "dim"); };
    trademark { INLINE(block, "trademark"); };
    registered { INLINE(block, "registered"); };
    copyright { INLINE(block, "copyright"); };
    footno { PASS(block, "text", "footno"); };
    entity { INLINE(block, "entity"); };
    
    script_tag { INLINE(block, "inline_html"); };
    start_tag { INLINE(block, "inline_html"); };
    end_tag { INLINE(block, "inline_html"); };
    empty_tag { INLINE(block, "inline_html"); };
    html_comment { INLINE(block, "inline_html"); };
    
    redcloth_version { INLINE(block, "inline_redcloth_version"); };
    
    other_phrase => esc;
    PUNCT => esc;
    space => esc;
    
    EOF;
    
  *|;

}%%

%% write data nofinal;

  public IRubyObject red_pass_code(IRubyObject self, IRubyObject regs, IRubyObject ref, String meth) {
    IRubyObject txt = ((RubyHash)regs).aref(ref);
    if(!txt.isNil()) {
      IRubyObject txt2 = RubyString.newEmptyString(runtime);
      strCatEscapedForPreformatted(self, txt2, ((RubyString)txt).getByteList().bytes, ((RubyString)txt).getByteList().begin, ((RubyString)txt).getByteList().begin + ((RubyString)txt).getByteList().realSize);
      ((RubyHash)regs).aset(ref, txt2);
    }
    return self.callMethod(runtime.getCurrentContext(), meth, regs);
  }

  public IRubyObject red_parse_attr(IRubyObject self, IRubyObject regs, IRubyObject ref) {
    IRubyObject txt = ((RubyHash)regs).aref(ref);
    IRubyObject new_regs = RedclothAttributes.attributes(self, txt);
    return regs.callMethod(runtime.getCurrentContext(), "update", new_regs);
  }

  public IRubyObject red_parse_link_attr(IRubyObject self, IRubyObject regs, IRubyObject ref) {
    IRubyObject txt = ((RubyHash)regs).aref(ref);
    IRubyObject new_regs = RedclothAttributes.link_attributes(self, txt);
    return regs.callMethod(runtime.getCurrentContext(), "update", new_regs);
  }

  public void PASS_CODE(IRubyObject H, String A, String T, int O) {
  System.err.println("PASS_CODE");
    ((RubyString)H).append(red_pass_code(self, regs, runtime.newSymbol(A), T));
  }

  public void PARSE_ATTR(String A) {
  System.err.println("PARSE_ATTR");
    red_parse_attr(self, regs, runtime.newSymbol(A));
  }

  public void PARSE_LINK_ATTR(String A) {
  System.err.println("PARSE_LINK_ATTR");
    red_parse_link_attr(self, regs, runtime.newSymbol(A));
  }

  private int opts;
  private IRubyObject buf;

  public RedclothInline(IRubyObject self, byte[] data, int p, int pe, IRubyObject refs) {
  System.err.println("RedclothInline(data.len: " + data.length + ", p: " + p + ", pe: " + pe + ")");
    this.runtime = self.getRuntime();
    this.self = self;
    
    // This is GROSS but necessary for EOF matching
    this.data = new byte[pe+1];
    System.arraycopy(data, p, this.data, 0, pe);
    this.data[pe] = 0;

    this.p = 0;
    this.pe = pe+1;
    this.eof = this.pe;
    this.orig_p = 0;
    this.orig_pe = this.pe;
    this.refs = refs;
    this.block = RubyString.newEmptyString(runtime);
    this.regs = runtime.getNil();
    this.opts = 0;
    this.buf = runtime.getNil();
  }


  public IRubyObject inline() {
    %% write init;
    %% write exec;
      System.err.println("gah: p: " + p + " pe: " + pe + " regs: " + regs + " refs: " + refs);
      System.err.println(" reg: " + reg);
    return block;
  }

  public static IRubyObject inline2(IRubyObject self, IRubyObject str, IRubyObject refs) {
    ByteList bl = str.convertToString().getByteList();
    return new RedclothInline(self, bl.bytes, bl.begin, bl.realSize, refs).inline();
  }
}
