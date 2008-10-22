/*
 * redcloth_scan.java.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.CallbackFactory;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.load.BasicLibraryService;

public class RedclothScanService implements BasicLibraryService {

  private static class Transformer {
%%{

  machine redcloth_scan;
  include redcloth_common "redcloth_common.java.rl";

  action extend { extend = ((RubyHash)regs).fastARef(runtime.newSymbol("type")); }

  # blocks
  notextile_tag_start = "<notextile>" ;
  notextile_tag_end = "</notextile>" LF? ;
  noparagraph_line_start = " "+ ;
  notextile_block_start = ( "notextile" >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) " "+ ) ;
  pre_tag_start = "<pre" [^>]* ">" (space* "<code>")? ;
  pre_tag_end = ("</code>" space*)? "</pre>" LF? ;
  pre_block_start = ( "pre" >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) " "+ ) ;
  bc_start = ( "bc" >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) " "+ ) ;
  bq_start = ( "bq" >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) ( ":" %A uri %{ STORE("cite"); } )? " "+ ) ;
  non_ac_btype = ( "bq" | "bc" | "pre" | "notextile" );
  btype = (alpha alnum*) -- (non_ac_btype | "fn" digit+);
  block_start = ( btype >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) " "+ ) >B %{ STORE_B("fallback"); };
  all_btypes = btype | non_ac_btype;
  next_block_start = ( all_btypes A_noactions C_noactions :> "."+ " " ) >A @{ p = reg - 1; } ;
  double_return = LF{2,} ;
  block_end = ( double_return | EOF );
  ftype = ( "fn" >A %{ STORE("type"); } digit+ >A %{ STORE("id"); } ) ;
  footnote_start = ( ftype A C :> dotspace ) ;
  ul = "*" %{nest++; list_type = "ul";};
  ol = "#" %{nest++; list_type = "ol";};
  ul_start  = ( ul | ol )* ul A C :> " "+   ;
  ol_start  = ( ul | ol )* ol N A C :> " "+ ;
  list_start  = ( ul_start | ol_start ) >{nest = 0;} ;
  dt_start = "-" . " "+ ;
  dd_start = ":=" ;
  long_dd  = dd_start " "* LF %{ ADD_BLOCK(); ASET("type", "dd"); } any+ >A %{ TRANSFORM("text"); } :>> "=:" ;
  dl_start = (dt_start mtext (LF dt_start mtext)* " "* dd_start)  ;
  blank_line = LF;
  link_alias = ( "[" >{ ASET("type", "ignore"); } %A chars %T "]" %A uri %{ STORE_URL("href"); } ) ;
  
  # image lookahead
  IMG_A_LEFT = "<" %{ ASET("float", "left"); } ;
  IMG_A_RIGHT = ">" %{ ASET("float", "right"); } ;
  aligned_image = ( "["? "!" (IMG_A_LEFT | IMG_A_RIGHT) ) >A @{ p = reg - 1; } ;
  
  # html blocks
  BlockTagName = Name - ("pre" | "notextile" | "a" | "applet" | "basefont" | "bdo" | "br" | "font" | "iframe" | "img" | "map" | "object" | "param" | "q" | "script" | "span" | "sub" | "sup" | "abbr" | "acronym" | "cite" | "code" | "del" | "dfn" | "em" | "ins" | "kbd" | "samp" | "strong" | "var" | "b" | "big" | "i" | "s" | "small" | "strike" | "tt" | "u");
  block_start_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? ">" | "<" BlockTagName ">";
  block_empty_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? "/>" | "<" BlockTagName "/>" ;
  block_end_tag = "</" BlockTagName space* ">" ;
  html_start = indent >B %{STORE_B("indent_before_start");} block_start_tag >B %{STORE_B("start_tag");}  indent >B %{STORE_B("indent_after_start");} ;
  html_end = indent >B %{STORE_B("indent_before_end");} block_end_tag >B %{STORE_B("end_tag");} (indent LF?) >B %{STORE_B("indent_after_end");} ;
  standalone_html = indent (block_start_tag | block_empty_tag | block_end_tag) indent LF+;
  html_end_terminating_block = ( LF indent block_end_tag ) >A @{ p = reg - 1; } ;

  # tables
  para = ( default+ ) -- LF ;
  btext = para ( LF{2} )? ;
  tddef = ( D? S A C :> dotspace ) ;
  td = ( tddef? btext >A %T :> "|" >{PASS(table, "text", "td");} ) >X ;
  trdef = ( A C :> dotspace ) ;
  tr = ( trdef? "|" %{INLINE(table, "tr_open");} td+ ) >X %{INLINE(table, "tr_close");} ;
  trows = ( tr (LF >X tr)* ) ;
  tdef = ( "table" >X A C :> dotspace LF ) ;
  table = ( tdef? trows >{table = RubyString.newEmptyString(runtime); INLINE(table, "table_open");} ) >{ reg = -1; } ;

  # info
  redcloth_version = ("RedCloth" >A ("::" | " " ) "VERSION"i ":"? " ")? %{STORE("prefix");} "RedCloth::VERSION" (LF* EOF | double_return) ;

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
      if (extend.isNil()) { 
        ADD_BLOCKCODE(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
      } 
    };
    double_return next_block_start { 
      if (extend.isNil()) { 
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
    script_tag_end   { CAT(block); ASET("type", "ignore"); ADD_BLOCK(); fgoto main; };
    EOF              { ASET("type", "ignore"); ADD_BLOCK(); fgoto main; };
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
      if (extend.isNil()) {
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
      if (extend.isNil()) {
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
      INLINE(html, "bc_close"); 
      plain_block = runtime.newString("p");
      fgoto main;
    };
    double_return { 
      if (extend.isNil()) { 
        ADD_BLOCKCODE(); 
        INLINE(html, "bc_close"); 
        plain_block = runtime.newString("p");
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        CAT(html); 
      } 
    };
    double_return next_block_start { 
      if (extend.isNil()) { 
        ADD_BLOCKCODE(); 
        INLINE(html, "bc_close"); 
        plain_block = runtime.newString("p");
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        CAT(html); 
        INLINE(html, "bc_close"); 
        plain_block = runtime.newString("p");
        END_EXTENDED(); 
        fgoto main; 
      } 
    };
    default => esc_pre;
  *|;

  bq := |*
    EOF { 
      ADD_BLOCK(); 
      INLINE(html, "bq_close"); 
      fgoto main; 
    };
    double_return { 
      if (extend.isNil()) { 
        ADD_BLOCK(); 
        INLINE(html, "bq_close"); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
      } 
    };
    double_return next_block_start { 
      if (extend.isNil()) { 
        ADD_BLOCK(); 
        INLINE(html, "bq_close"); 
        fgoto main; 
      } else {
        ADD_EXTENDED_BLOCK(); 
        INLINE(html, "bq_close"); 
        END_EXTENDED(); 
        fgoto main; 
      }
    };
    html_end_terminating_block { 
        if (extend.isNil()) { 
          ADD_BLOCK(); 
          INLINE(html, "bq_close"); 
          fgoto main; 
        } else {
          ADD_EXTENDED_BLOCK(); 
          INLINE(html, "bq_close"); 
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
      if (extend.isNil()) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
      } 
    };
    double_return next_block_start { 
      if (extend.isNil()) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
        END_EXTENDED(); 
        fgoto main; 
      }      
    };
    html_end_terminating_block { 
      if (extend.isNil()) { 
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
      list_layout = runtime.newArray();
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
    LF dt_start     { ADD_BLOCK(); ASET("type", "dt"); };
    dd_start        { ADD_BLOCK(); ASET("type", "dd"); };
    long_dd         { INLINE(html, "dd"); CLEAR_REGS(); };
    block_end       { ADD_BLOCK(); INLINE(html, "dl_close");  fgoto main; };
    default => cat;
  *|;

  main := |*
    noparagraph_line_start  { ASET("type", "ignored_line"); fgoto noparagraph_line; };
    notextile_tag_start { ASET("type", "notextile"); fgoto notextile_tag; };
    notextile_block_start { ASET("type", "notextile"); fgoto notextile_block; };
    script_tag_start { CAT(block); fgoto script_tag; };
    pre_tag_start       { ASET("type", "notextile"); CAT(block); fgoto pre_tag; };
    pre_block_start { fgoto pre_block; };
    standalone_html { ASET("type", "html"); CAT(block); ADD_BLOCK(); };
    html_start      { ASET("type", "html_block"); fgoto html; };
    bc_start        { INLINE(html, "bc_open"); ASET("type", "code"); plain_block = runtime.newString("code"); fgoto bc; };
    bq_start        { INLINE(html, "bq_open"); ASET("type", "p"); fgoto bq; };
    block_start     { fgoto block; };
    footnote_start  { fgoto footnote; };
    list_start      { list_layout = runtime.newArray(); LIST_ITEM(); fgoto list; };
    dl_start        { p = ts; INLINE(html, "dl_open"); ASET("type", "dt"); fgoto dl; };
    table           { INLINE(table, "table_close"); DONE(table); fgoto block; };
    link_alias      { ((RubyHash)refs_found).fastASet(((RubyHash)regs).fastARef(runtime.newSymbol("text")), ((RubyHash)regs).fastARef(runtime.newSymbol("href"))); DONE(block); };
    aligned_image   { ((RubyHash)regs).fastASet(runtime.newSymbol("type"), plain_block); fgoto block; };
    redcloth_version { INLINE(html, "redcloth_version"); };
    blank_line => cat;
    default
    { 
      CLEAR_REGS();
      ((RubyHash)regs).fastASet(runtime.newSymbol("type"), plain_block);
      CAT(block);
      fgoto block;
    };
    EOF;
  *|;

}%%

%% write data nofinal;
    public void CLEAR(IRubyObject obj) {
      if(block == obj) {
        block = RubyString.newEmptyString(runtime);
      } else if(html == obj) { 
        html = RubyString.newEmptyString(runtime);
      } else if(table == obj) {
        table = RubyString.newEmptyString(runtime);
      }
    }

    public void ADD_BLOCK() {
      ((RubyString)html).append(red_block(self, regs, block, refs));
      extend = runtime.getNil();
      CLEAR(block);
      CLEAR_REGS();      
    }

    public void CLEAR_REGS() {
      regs = RubyHash.newHash(runtime);
    }

    public void CAT(IRubyObject H) {
      ((RubyString)H).cat(data, ts, te-ts);
    }

    public void INLINE(IRubyObject H, String T) {
      ((RubyString)H).append(self.callMethod(runtime.getCurrentContext(), T, regs));
    }

    public void DONE(IRubyObject H) {
      ((RubyString)html).append(H);
      CLEAR(H);
      CLEAR_REGS();
    }

    public void ADD_EXTENDED_BLOCK() {
      ((RubyString)html).append(red_block(self, regs, block, refs));
      CLEAR(block);
    }

    public void ADD_BLOCKCODE() {
      ((RubyString)html).append(red_blockcode(self, regs, block));
      CLEAR(block);
      CLEAR_REGS();
    }

    public void ADD_EXTENDED_BLOCKCODE() {
      ((RubyString)html).append(red_blockcode(self, regs, block));
      CLEAR(block);
    }

    public void AINC(String T) {
      red_inc(regs, runtime.newSymbol(T));
    }

    public void END_EXTENDED() {
      extend = runtime.getNil();
      CLEAR_REGS();
    }

    public void ASET(String T, String V) {
      ((RubyHash)regs).fastASet(runtime.newSymbol(T), runtime.newString(V));
    }

    public void STORE(String T) {
      if(p > reg && reg >= ts) {
        IRubyObject str = RubyString.newString(runtime, data, reg, p-reg);
        ((RubyHash)regs).fastASet(runtime.newSymbol(T), str);
      } else {
        ((RubyHash)regs).fastASet(runtime.newSymbol(T), runtime.getNil());
      }
    }

    public void STORE_B(String T) {
      if(p > bck && bck >= ts) {
        IRubyObject str = RubyString.newString(runtime, data, bck, p-bck);
        ((RubyHash)regs).fastASet(runtime.newSymbol(T), str);
      } else {
        ((RubyHash)regs).fastASet(runtime.newSymbol(T), runtime.getNil());
      }
    }

    private IRubyObject self;
    private byte[] data;
    private int p, pe;
    private IRubyObject refs;

    private Ruby runtime;
    private int orig_p, orig_pe;
    private int cs, act, nest;
    private int ts = -1;
    private int te = -1;
    private int reg = -1;
    private int bck = -1;
    private int eof = -1;

    private IRubyObject html;
    private IRubyObject table;
    private IRubyObject block;
    private IRubyObject regs;

    private IRubyObject list_layout;
    private String list_type = null;
    private IRubyObject list_index;
    private int list_continue = 0;
    private IRubyObject plain_block;
    private IRubyObject extend;
    private IRubyObject refs_found;

    public Transformer(IRubyObject self, byte[] data, int p, int pe, IRubyObject refs) {
      this.self = self;
      this.data = data;
      this.p = p;
      this.pe = pe;
      this.refs = refs;

      runtime = self.getRuntime();
      orig_p = p;
      orig_pe = pe;

      html = RubyString.newEmptyString(runtime);
      table = RubyString.newEmptyString(runtime);
      block = RubyString.newEmptyString(runtime);
      CLEAR_REGS();

      list_layout = runtime.getNil();
      list_index = runtime.newArray();
      plain_block = runtime.newString("p");
      extend = runtime.getNil();
      refs_found = RubyHash.newHash(runtime);
    }

    public IRubyObject transform() {
      %% write init;

      %% write exec;
      if(((RubyString)block).getByteList().realSize > 0) {
//      ADD_BLOCK();
      }

      if(refs.isNil() && !refs_found.callMethod(runtime.getCurrentContext(), "empty?").isTrue()) {
        return RedclothScanService.transform(self, data, orig_p, orig_pe, refs_found);
      } else {
        self.callMethod(self.getRuntime().getCurrentContext(), "after_transform", html);
        return html;
      }
    }
  }

  public static IRubyObject transform(IRubyObject self, byte[] data, int p, int pe, IRubyObject refs) {
    return new Transformer(self, data, p, pe, refs).transform();
  }
  
  public static IRubyObject inline2(IRubyObject workingCopy, IRubyObject self, RubyHash hash) {
    return workingCopy.getRuntime().getNil();
  }

  public static IRubyObject transform2(IRubyObject self, IRubyObject str) {
    RubyString ss = str.convertToString();
    ss.cat((byte)'\n');
    self.callMethod(self.getRuntime().getCurrentContext(), "before_transform", ss);
    return transform(self, ss.getByteList().bytes(), ss.getByteList().begin, ss.getByteList().realSize, self.getRuntime().getNil());
  }

  @JRubyMethod
  public static IRubyObject to(IRubyObject self, IRubyObject formatter) {
    Ruby runtime = self.getRuntime();
    self.callMethod(runtime.getCurrentContext(), "delete!", runtime.newString("\r"));
    IRubyObject workingCopy = self.rbClone();

    ((RubyObject)workingCopy).extend(new IRubyObject[]{formatter});
    
    if(workingCopy.callMethod(runtime.getCurrentContext(), "lite_mode").isTrue()) { 
      return inline2(workingCopy, self, RubyHash.newHash(runtime));
    } else {
      return transform2(workingCopy, self);
    }
  }

  @JRubyMethod(rest=true)
  public static IRubyObject html_esc(IRubyObject self, IRubyObject[] args) {
    return self.getRuntime().getNil();
  }

  @JRubyMethod
  public static IRubyObject latex_esc(IRubyObject self, IRubyObject str) {
    return self.getRuntime().getNil();
  }

  public boolean basicLoad(final Ruby runtime) throws IOException {
    Init_redcloth_scan(runtime);
    return true;
  }

  public static void Init_redcloth_scan(Ruby runtime) {
    RubyModule mRedCloth = runtime.defineModule("RedCloth");
    RubyClass super_RedCloth = mRedCloth.defineClassUnder("TextileDoc", runtime.getString(), runtime.getString().getAllocator());
    super_RedCloth.defineAnnotatedMethods(RedclothScanService.class);
    super_RedCloth.defineClassUnder("ParseError",runtime.getClass("Exception"),runtime.getClass("Exception").getAllocator());
  }
}
