/*
 * redcloth_scan.java.rl
 *
 * Copyright (C) 2009 Jason Garber
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
import org.jruby.runtime.Arity;
import org.jruby.runtime.Block;
import org.jruby.runtime.CallbackFactory;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.load.BasicLibraryService;
import org.jruby.util.ByteList;

public class RedclothScanService implements BasicLibraryService {

  public static class Base {

    public void CLEAR_LIST() {
      list_layout = runtime.newArray();
    }
    
   public void LIST_ITEM() {
     int aint = 0;
     IRubyObject aval = ((RubyArray)list_index).entry(nest-1);
     if(!aval.isNil()) { aint = RubyNumeric.fix2int(aval); }
     if(list_type.equals("ol")) { 
       ((RubyArray)list_index).store(nest-1, runtime.newFixnum(aint + 1));
     }

     if(nest > ((RubyArray)list_layout).getLength()) {
       listm = list_type + "_open";       
       if(list_continue == 1) {
         list_continue = 0;
         ((RubyHash)regs).aset(runtime.newSymbol("start"), ((RubyArray)list_index).entry(nest-1));
       } else {
         IRubyObject start = ((RubyHash)regs).aref(runtime.newSymbol("start"));
         if(start.isNil()) {
           ((RubyArray)list_index).store(nest-1, runtime.newFixnum(1));
         } else {
           IRubyObject start_num = start.callMethod(runtime.getCurrentContext(), "to_i");
           ((RubyArray)list_index).store(nest-1, start_num);
         }          
       }
       ((RubyHash)regs).aset(runtime.newSymbol("nest"), runtime.newFixnum(nest));
       ((RubyString)html).append(self.callMethod(runtime.getCurrentContext(), listm, regs));
       ((RubyArray)list_layout).store(nest-1, runtime.newString(list_type));
       regs = RubyHash.newHash(runtime);
       ASET("first", "true");
     }
     LIST_CLOSE();
     ((RubyHash)regs).aset(runtime.newSymbol("nest"), ((RubyArray)list_layout).length());
     ASET("type", "li_open");
   }

   public void LIST_CLOSE() {
     while(nest < ((RubyArray)list_layout).getLength()) {
       ((RubyHash)regs).aset(runtime.newSymbol("nest"), ((RubyArray)list_layout).length());
       IRubyObject end_list = ((RubyArray)list_layout).pop(runtime.getCurrentContext());
       if(!end_list.isNil()) {
         String s = end_list.convertToString().toString();
         listm = s + "_close";
         ((RubyString)html).append(self.callMethod(runtime.getCurrentContext(), listm, regs));
       }
     }
   }

   public void TRANSFORM(String T) {
     if(p > reg && reg >= ts) {
       IRubyObject str = RedclothScanService.transform(self, data, reg, p-reg, refs);
       ((RubyHash)regs).aset(runtime.newSymbol(T), str);
     } else {
       ((RubyHash)regs).aset(runtime.newSymbol(T), runtime.getNil());
     } 
   }

    public IRubyObject red_pass(IRubyObject self, IRubyObject regs, IRubyObject ref, String meth, IRubyObject refs) {
      IRubyObject txt = ((RubyHash)regs).aref(ref);
      if(!txt.isNil()) {
        ((RubyHash)regs).aset(ref, inline2(self, txt, refs));
      }
      return self.callMethod(self.getRuntime().getCurrentContext(), meth, regs);
    }

   
    public void PASS(IRubyObject H, String A, String T) {
      ((RubyString)H).append(red_pass(self, regs, runtime.newSymbol(A), T, refs));
    }   

    
    public void STORE_LINK_ALIAS() {
      ((RubyHash)refs_found).aset(((RubyHash)regs).aref(runtime.newSymbol("text")), ((RubyHash)regs).aref(runtime.newSymbol("href")));
    }

    public void STORE_URL(String T) {
      if(p > reg && reg >= ts) {
        boolean punct = true;
        while(p > reg && punct) {
          switch(data[p - 1]) {
            case ')':
              int tempP = p - 1;
              int level = -1;
              while(tempP > reg) {
                switch(data[tempP - 1]) {
                  case '(': ++level; break;
                  case ')': --level; break;
                }
                --tempP;
              }
              if (level == 0) { punct = false; } else { --p; }
              break;
            case '!': case '"': case '#': case '$': case '%': case ']': case '[': case '&': case '\'':
            case '*': case '+': case ',': case '-': case '.': case '(': case ':':
            case ';': case '=': case '?': case '@': case '\\': case '^': case '_':
            case '`': case '|': case '~': p--; break;
            default: punct = false;
          }
        }
        te = p;
      }

      STORE(T);

      if(!refs.isNil() && refs.callMethod(runtime.getCurrentContext(), "has_key?", ((RubyHash)regs).aref(runtime.newSymbol(T))).isTrue()) {
        ((RubyHash)regs).aset(runtime.newSymbol(T), ((RubyHash)refs).aref(((RubyHash)regs).aref(runtime.newSymbol(T))));
      }
    }

    public void red_inc(IRubyObject regs, IRubyObject ref) {
      int aint = 0;
      IRubyObject aval = ((RubyHash)regs).aref(ref);
      if(!aval.isNil()) {
        aint = RubyNumeric.fix2int(aval);
      }
      ((RubyHash)regs).aset(ref, regs.getRuntime().newFixnum(aint+1));
    }

    public IRubyObject red_blockcode(IRubyObject self, IRubyObject regs, IRubyObject block) {
      Ruby runtime = self.getRuntime();
      IRubyObject btype = ((RubyHash)regs).aref(runtime.newSymbol("type"));
      if(((RubyString)block).getByteList().realSize > 0) {
        ((RubyHash)regs).aset(runtime.newSymbol("text"), block);
        block = self.callMethod(runtime.getCurrentContext(), btype.asJavaString(), regs);
      }
      return block;
    }

    public IRubyObject red_block(IRubyObject self, IRubyObject regs, IRubyObject block, IRubyObject refs) {
      Ruby runtime = self.getRuntime();
      RubySymbol method;
      IRubyObject sym_text = runtime.newSymbol("text");
      IRubyObject btype = ((RubyHash)regs).aref(runtime.newSymbol("type"));
      block = block.callMethod(runtime.getCurrentContext(), "strip");

      if(!block.isNil() && !btype.isNil()) {
        method = btype.convertToString().intern();

        if(method == runtime.newSymbol("notextile")) {
          ((RubyHash)regs).aset(sym_text, block);
        } else {
          ((RubyHash)regs).aset(sym_text, inline2(self, block, refs));
        }

        IRubyObject formatterMethods = ((RubyObject)self).callMethod(runtime.getCurrentContext(), "formatter_methods");
        if( ((RubyArray)formatterMethods).includes(runtime.getCurrentContext(), method) ) {
          block = self.callMethod(runtime.getCurrentContext(), method.asJavaString(), regs);
        } else {
          IRubyObject fallback = ((RubyHash)regs).aref(runtime.newSymbol("fallback"));
          if(!fallback.isNil()) {
            ((RubyString)fallback).append(((RubyHash)regs).aref(sym_text));
            regs = RubyHash.newHash(runtime);
            ((RubyHash)regs).aset(sym_text, fallback);
          }
          block = self.callMethod(runtime.getCurrentContext(), "p", regs);
        }
      }

      return block;
    }

    public void strCatEscaped(IRubyObject self, IRubyObject str, byte[] data, int ts, int te) {
      IRubyObject sourceStr = RubyString.newString(self.getRuntime(), data, ts, te-ts);
      IRubyObject escapedStr = self.callMethod(self.getRuntime().getCurrentContext(), "escape", sourceStr);
      ((RubyString)str).concat(escapedStr);
    }

    public void strCatEscapedForPreformatted(IRubyObject self, IRubyObject str, byte[] data, int ts, int te) { 
      IRubyObject sourceStr = RubyString.newString(self.getRuntime(), data, ts, te-ts);
      IRubyObject escapedStr = self.callMethod(self.getRuntime().getCurrentContext(), "escape_pre", sourceStr);
      ((RubyString)str).concat(escapedStr);
    }

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

    public void RESET_REG() {
      reg = -1;
    }

    public void CAT(IRubyObject H) {
      ((RubyString)H).cat(data, ts, te-ts);
    }

    public void SET_PLAIN_BLOCK(String T) {
      plain_block = runtime.newString(T);
    }

    public void RESET_TYPE() {
      ((RubyHash)regs).aset(runtime.newSymbol("type"), plain_block);
    }

    public void INLINE(IRubyObject H, String T) {
      ((RubyString)H).append(self.callMethod(runtime.getCurrentContext(), T, regs));
    }

    public void RSTRIP_BANG(IRubyObject H) {
      ((RubyString)H).callMethod(runtime.getCurrentContext(), "rstrip!");
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

    public boolean IS_NOT_EXTENDED() {
      return extend.isNil();
    }

    public void ASET(String T, String V) {
      ((RubyHash)regs).aset(runtime.newSymbol(T), runtime.newString(V));
    }

    public void STORE(String T) {
      if(p > reg && reg >= ts) {
      
        IRubyObject str = RubyString.newString(runtime, data, reg, p-reg);
        ((RubyHash)regs).aset(runtime.newSymbol(T), str);
      } else {
        ((RubyHash)regs).aset(runtime.newSymbol(T), runtime.getNil());
      }
    }

    public void STORE_B(String T) {
      if(p > bck && bck >= ts) {
        IRubyObject str = RubyString.newString(runtime, data, bck, p-bck);
        ((RubyHash)regs).aset(runtime.newSymbol(T), str);
      } else {
        ((RubyHash)regs).aset(runtime.newSymbol(T), runtime.getNil());
      }
    }

    public IRubyObject self;
    public byte[] data;
    public int p, pe;
    public IRubyObject refs;

    public Ruby runtime;
    public int orig_p, orig_pe;
    public int cs, act, nest;
    public int ts = -1;
    public int te = -1;
    public int reg = -1;
    public int bck = -1;
    public int eof = -1;

    public IRubyObject html;
    public IRubyObject table;
    public IRubyObject block;
    public IRubyObject regs;

    public IRubyObject list_layout;
    public String list_type = null;
    public IRubyObject list_index;
    public int list_continue = 0;
    public IRubyObject plain_block;
    public IRubyObject extend;
    public String listm = "";
    public IRubyObject refs_found;
  }

  private static class Transformer extends Base {
%%{

  machine redcloth_scan;
  include redcloth_common "redcloth_common.java.rl";

  action extend { extend = ((RubyHash)regs).aref(runtime.newSymbol("type")); }

  include redcloth_scan "redcloth_scan.rl";

}%%

%% write data nofinal;

    public Transformer(IRubyObject self, byte[] data, int p, int pe, IRubyObject refs) {
      if(p+pe > data.length) {
        throw new RuntimeException("BLAHAHA");
      }
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
      
      runtime = self.getRuntime();

      html = RubyString.newEmptyString(runtime);
      table = RubyString.newEmptyString(runtime);
      block = RubyString.newEmptyString(runtime);
      CLEAR_REGS();

      list_layout = runtime.getNil();
      list_index = runtime.newArray();
      SET_PLAIN_BLOCK("p");
      extend = runtime.getNil();
      refs_found = RubyHash.newHash(runtime);
    }

    public IRubyObject transform() {
      %% write init;

      %% write exec;

      if(((RubyString)block).getByteList().realSize > 0) {
        ADD_BLOCK();
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
  
  public static IRubyObject inline2(IRubyObject workingCopy, IRubyObject self, IRubyObject refs) {
    return RedclothInline.inline2(workingCopy, self, refs);
  }

  public static IRubyObject transform2(IRubyObject self, IRubyObject str) {
    RubyString ss = str.convertToString();
    self.callMethod(self.getRuntime().getCurrentContext(), "before_transform", ss);
    return transform(self, ss.getByteList().bytes(), ss.getByteList().begin, ss.getByteList().realSize, self.getRuntime().getNil());
  }

  @JRubyMethod
  public static IRubyObject to(IRubyObject self, IRubyObject formatter) {
    Ruby runtime = self.getRuntime();
    self.callMethod(runtime.getCurrentContext(), "delete!", runtime.newString("\r"));
    IRubyObject workingCopy = self.rbClone();

    ((RubyObject)workingCopy).extend(new IRubyObject[]{formatter});
    
    IRubyObject workingCopyMethods = workingCopy.callMethod(runtime.getCurrentContext(), "methods");
    IRubyObject classInstanceMethods = workingCopy.getType().callMethod(runtime.getCurrentContext(), "instance_methods");
    IRubyObject customTags = workingCopyMethods.callMethod(runtime.getCurrentContext(), "-", classInstanceMethods);
    ((RubyObject)workingCopy).setInstanceVariable("@custom_tags", customTags);
    
    if(workingCopy.callMethod(runtime.getCurrentContext(), "lite_mode").isTrue()) { 
      return inline2(workingCopy, self, RubyHash.newHash(runtime));
    } else {
      return transform2(workingCopy, self);
    }
  }

  @JRubyMethod(rest=true)
  public static IRubyObject html_esc(IRubyObject self, IRubyObject[] args) {
    Ruby runtime = self.getRuntime();
    IRubyObject str = runtime.getNil(), 
                level = runtime.getNil();
    if(Arity.checkArgumentCount(runtime, args, 1, 2) == 2) {
      level = args[1];
    }
    str = args[0];

    IRubyObject new_str = RubyString.newEmptyString(runtime);
    if(str.isNil()) {
      return new_str;
    }

    ByteList bl = str.convertToString().getByteList();

    if(bl.realSize == 0) {
      return new_str;
    }

    byte[] bytes = bl.bytes;
    int ts = bl.begin;
    int te = ts + bl.realSize;
    int t = ts, t2 = ts;
    String ch = null;

    if(te <= ts) {
      return new_str;
    }
  
    while(t2 < te) {
      ch = null;
      // normal + pre
      switch(bytes[t2]) {
        case '&':  ch = "amp";    break;
        case '>':  ch = "gt";     break;
        case '<':  ch = "lt";     break;
      }

      // normal (non-pre)
      if(level != runtime.newSymbol("html_escape_preformatted")) {
        switch(bytes[t2]) {
          case '\n': ch = "br";     break;
          case '"' : ch = "quot";   break;
          case '\'': 
            ch = (level == runtime.newSymbol("html_escape_attributes")) ? "apos" : "squot";
          break;
        }
      }

      if(ch != null) {
        if(t2 > t) {
          ((RubyString)new_str).cat(bytes, t, t2-t);
        }
        ((RubyString)new_str).concat(self.callMethod(runtime.getCurrentContext(), ch, RubyHash.newHash(runtime)));
        t = t2 + 1;
      }

      t2++;
    }


    if(t2 > t) {
      ((RubyString)new_str).cat(bytes, t, t2-t);
    }
  
    return new_str;
  }

  @JRubyMethod
  public static IRubyObject latex_esc(IRubyObject self, IRubyObject str) {
    Ruby runtime = self.getRuntime();
    IRubyObject new_str = RubyString.newEmptyString(runtime);
    
    if(str.isNil()) {
      return new_str;
    }

    ByteList bl = str.convertToString().getByteList();
    
    if(bl.realSize == 0) {
      return new_str;
    }
  
    byte[] bytes = bl.bytes;
    int ts = bl.begin;
    int te = ts + bl.realSize;
    int t = ts;
    int t2 = ts;
    String ch = null;

    while(t2 < te) {
      ch = null;

      switch(bytes[t2]) {
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

      if(ch != null) {
        if(t2 > t) {
          ((RubyString)new_str).cat(bytes, t, t2-t);
        }
        IRubyObject opts = RubyHash.newHash(runtime);
        ((RubyHash)opts).aset(runtime.newSymbol("text"), runtime.newString(ch));
        ((RubyString)new_str).concat(self.callMethod(runtime.getCurrentContext(), "entity", opts));
        t = t2 + 1;
      }

      t2++;
    }

    if(t2 > t) {
      ((RubyString)new_str).cat(bytes, t, t2-t);
    }

    return new_str;
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
