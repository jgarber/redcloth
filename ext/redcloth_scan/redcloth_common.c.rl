%%{
  
  machine redcloth_common;
  include redcloth_common "redcloth_common.rl";
  
  action esc { rb_str_cat_escaped(self, block, ts, te); }
  action esc_pre { rb_str_cat_escaped_for_preformatted(self, block, ts, te); }
  action ignore { rb_str_append(block, rb_funcall(self, rb_intern("ignore"), 1, regs)); }
  
  # conditionals
  action starts_line {
    p == orig_p || *(p-1) == '\r' || *(p-1) == '\n' || *(p-1) == '\f'
  }
  action starts_phrase {
    p == orig_p || *(p-1) == '\r' || *(p-1) == '\n' || *(p-1) == '\f' || *(p-1) == ' '
  }
  
}%%;