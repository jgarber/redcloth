%%{

  machine redcloth_common;
  include redcloth_common "redcloth_common.rl";

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

}%%;
