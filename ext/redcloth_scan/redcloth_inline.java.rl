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
  include redcloth_inline "redcloth_inline.rl";

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
    ((RubyString)H).append(red_pass_code(self, regs, runtime.newSymbol(A), T));
  }

  public void PARSE_ATTR(String A) {
    red_parse_attr(self, regs, runtime.newSymbol(A));
  }

  public void PARSE_LINK_ATTR(String A) {
    red_parse_link_attr(self, regs, runtime.newSymbol(A));
  }

  private int opts;
  private IRubyObject buf;

  public RedclothInline(IRubyObject self, byte[] data, int p, int pe, IRubyObject refs) {
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

    return block;
  }

  public static IRubyObject inline2(IRubyObject self, IRubyObject str, IRubyObject refs) {
    ByteList bl = str.convertToString().getByteList();
    return new RedclothInline(self, bl.bytes, bl.begin, bl.realSize, refs).inline();
  }
}
