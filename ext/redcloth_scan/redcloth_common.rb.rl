%%{
  
  machine redcloth_common;
  
  action esc { rb_str_cat_escaped(@block, @ts, @te); }
  action esc_pre { rb_str_cat_escaped_for_preformatted(@block, STR_NEW(@ts, @te-@ts)); }
  action ignore { @block << @textile_doc.ignore(@regs); }
  
  # conditionals
  action starts_line {
    @p == 0 || @data[(@p-1), 1] == "\r" || @data[(@p-1), 1] == "\n" || @data[(@p-1), 1] == "\f"
  }
  action starts_phrase {
    @p == 0 || @data[(@p-1), 1] == "\r" || @data[(@p-1), 1] == "\n" || @data[(@p-1), 1] == "\f" || @data[(@p-1), 1] == " "
  }
  action extended { !@extend.nil? }
  action not_extended { @extend.nil? }
  action following_hash_is_ol_not_id { 
    @data[(@p+1), 1] == "#" ? (@data[(@p+2), 1] == "#" || @data[(@p+2), 1] == "*" || @data[(@p+2), 1] == " ") : true
  }
  
  
  include redcloth_common "redcloth_common.rl";
  
}%%;