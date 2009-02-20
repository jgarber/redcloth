/*
 * redcloth_attributes.rl
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
import org.jruby.runtime.Block;
import org.jruby.runtime.CallbackFactory;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.load.BasicLibraryService;

import org.jruby.util.ByteList;

public class RedclothAttributes extends RedclothScanService.Base {

%%{

  machine redcloth_attributes;
  include redcloth_common "redcloth_common.java.rl";
  include redcloth_attributes "redcloth_attributes.rl";

}%%

%% write data nofinal;

  public void SET_ATTRIBUTES() {
    SET_ATTRIBUTE("class_buf", "class");
    SET_ATTRIBUTE("id_buf", "id");
    SET_ATTRIBUTE("lang_buf", "lang");
    SET_ATTRIBUTE("style_buf", "style");
  }

  public void SET_ATTRIBUTE(String B, String A) {
    if(!((RubyHash)regs).aref(runtime.newSymbol(B)).isNil()) {
      ((RubyHash)regs).aset(runtime.newSymbol(A), ((RubyHash)regs).aref(runtime.newSymbol(B)));
    }
  }
 
  private int machine;
   
  public RedclothAttributes(int machine, IRubyObject self, byte[] data, int p, int pe) {
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

    this.regs = RubyHash.newHash(runtime);
    this.machine = machine;
  }

  public IRubyObject parse() {
    %% write init;
  
    cs = machine;

    %% write exec;

    return regs;
  }

  public static IRubyObject attributes(IRubyObject self, IRubyObject str) {
    ByteList bl = str.convertToString().getByteList();
    int cs = redcloth_attributes_en_inline;
    return new RedclothAttributes(cs, self, bl.bytes, bl.begin, bl.realSize).parse();
  }

  public static IRubyObject link_attributes(IRubyObject self, IRubyObject str) {
    Ruby runtime = self.getRuntime();

    ByteList bl = str.convertToString().getByteList();
    int cs = redcloth_attributes_en_link_says;
    return new RedclothAttributes(cs, self, bl.bytes, bl.begin, bl.realSize).parse();
  }
}
