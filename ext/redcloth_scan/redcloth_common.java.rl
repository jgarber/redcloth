%%{

  machine redcloth_common;

  action esc { strCatEscaped(self, block, data, ts, te); }
  action esc_pre { strCatEscapedForPreformatted(self, block, data, ts, te); }
  action ignore { ((RubyString)block).append(self.callMethod(runtime.getCurrentContext(), "ignore", regs)); }
  
  # conditionals
  action starts_line {
    p == orig_p || data[(p-1)] == '\r' || data[(p-1)] == '\n' || data[(p-1)] == '\f'
  }
  action starts_phrase {
    p == orig_p || data[(p-1)] == '\r' || data[(p-1)] == '\n' || data[(p-1)] == '\f' || data[(p-1)] == ' '
  }
  action extended { !extend.isNil() }
  action not_extended { extend.isNil() }
  action following_hash_is_ol_not_id { 
    (data[(p+1)] == '#') ? (data[(p+2)] == '#' || data[(p+2)] == '*' || data[(p+2)] == ' ') : true
  }
  
  
  include redcloth_common "redcloth_common.rl";

}%%;
