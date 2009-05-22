# 
# redcloth_scan.rb.rl
# 
# Copyright (C) 2009 Jason Garber
# 


%%{

  machine redcloth_scan;
  include redcloth_common "redcloth_common.rb.rl";

  action extend { @extend = @regs[:type] }

  include redcloth_scan "redcloth_scan.rl";

}%%

module RedCloth
  EXTENSION_LANGUAGE = "Ruby"
  
  class TextileDoc < String
    def to(formatter)
      self.delete!("\r")
      working_copy = self.clone
      working_copy.extend(formatter)
      
      if (working_copy.lite_mode)
        return working_copy.redcloth_inline2(self, {})
      else
        return working_copy.redcloth_transform2(self)
      end
    end
    
    class ParseError < Exception; end
    
    def redcloth_transform2(textile_doc)
      before_transform(textile_doc)
      return RedCloth::RedclothScan.transform(self, textile_doc, nil)
    end
    
    def redcloth_inline2(textile_doc, refs)
      return RedCloth::RedclothInline.redcloth_inline2(self, textile_doc, refs)
    end
    
    def html_esc(input, level=nil)
      return "" if input.nil? || input.empty?

      str = input.dup
      str.gsub!('&') { amp({}) }
      str.gsub!('>') { gt({}) }
      str.gsub!('<') { lt({}) }
      if (level != :html_escape_preformatted)
        str.gsub!("\n") { br({}) }
        str.gsub!('"') { quot({}) }
        str.gsub!("'") { level == :html_escape_attributes ? apos({}) : squot({}) }
      end
      return str;
    end
    
    LATEX_ESCAPE_CHARACTERS = {
      '{' => "#123",
      '}' => "#125",
      '\\' => "#92",
      '#' => "#35",
      '$' => "#36",
      '%' => "#37",
      '&' => "amp",
      '_' => "#95",
      '^' => "circ",
      '~' => "tilde",
      '<' => "lt",
      '>' => "gt",
      '\n'=> "#10"
    }    
    def latex_esc(str)
      return "" if str.nil? || str.empty?
      
      ch_regex = Regexp.new(LATEX_ESCAPE_CHARACTERS.keys.map {|ch| Regexp.escape(ch) }.join("|"))
      str.gsub(ch_regex) {|ch| entity({:text => LATEX_ESCAPE_CHARACTERS[ch]}) }
    end
  end

  class BaseScanner
    attr_accessor :p, :pe, :refs
    attr_reader :data
    attr_accessor :orig_data, :cs, :act, :ts, :te, :reg, :bck, :eof,
      :html, :table, :block, :regs, :attr_regs
    attr_accessor :list_layout, :list_type, :list_index, :list_continue, :listm, 
      :refs_found, :plain_block

    def STR_NEW(p,n)
      @data[p, n]
    end
    def MARK()
      @reg = @p
    end
    def MARK_B()
      @bck = @p
    end
    def MARK_ATTR()
      @attr_reg = @p
    end
    def CLEAR_REGS()
      @regs = {}
      @attr_regs = {}
    end
    def RESET_REG()
      @reg = nil
    end
    def CAT(h)
      h << @data[@ts, @te - @ts]
    end
    def CLEAR(h)
      h.replace("")
    end
    def RSTRIP_BANG(h)
      h.rstrip!
    end
    def SET_PLAIN_BLOCK(t) 
      @plain_block = t
    end
    def RESET_TYPE()
      @regs[:type] = @plain_block
    end
    def INLINE(h, t)
      h << @textile_doc.send(t, @regs)
    end
    def DONE(h)
      @html << h
      CLEAR(h)
      CLEAR_REGS()
    end
    def PASS(h, a, t)
      h << red_pass(@regs, a.to_sym, t, @refs)
    end
    def PARSE_ATTR(a)
      red_parse_attr(@regs, a)
    end
    def PARSE_LINK_ATTR(a)
      red_parse_link_attr(@regs, a)
    end
    def PARSE_IMAGE_ATTR(a)
      red_parse_image_attr(@regs, a)
    end
    def PASS_CODE(h, a, t)
      h << red_pass_code(@regs, a, t)
    end
    def ADD_BLOCK()
      @html << red_block(@regs, @block, @refs)
      @extend = nil
      CLEAR(@block)
      CLEAR_REGS()
    end
    def ADD_EXTENDED_BLOCK()
      @html << red_block(@regs, @block, @refs)
      CLEAR(@block)
    end
    def END_EXTENDED()
      @extend = nil
      CLEAR_REGS()
    end
    def ADD_BLOCKCODE()
      @html << red_blockcode(@regs, @block)
      CLEAR(@block)
      CLEAR_REGS()
    end
    def ADD_EXTENDED_BLOCKCODE()
      @html << red_blockcode(@regs, @block)
      CLEAR(@block)
    end
    def ASET(t, v)
      @regs[t.to_sym] = v
    end
    def ATTR_SET(t, v)
      @attr_regs[t.to_sym] = v
    end
    def ATTR_INC(t)
      red_inc(@attr_regs, t.to_sym)
    end
    def SET_ATTRIBUTES()
      SET_ATTRIBUTE("class_buf", "class")
      SET_ATTRIBUTE("id_buf", "id")
      SET_ATTRIBUTE("lang_buf", "lang")
      SET_ATTRIBUTE("style_buf", "style")
      @regs.merge!(@attr_regs)
    end
    def SET_ATTRIBUTE(b, a)
      @regs[a.to_sym] = @regs[b.to_sym] unless @regs[b.to_sym].nil?
    end
    def TRANSFORM(t)
      if (@reg && @p > @reg && @reg >= @ts)
        str = self.class.transform(@textile_doc, STR_NEW(reg, p-reg), @refs)
        @regs[t.to_sym] = str
        # /*printf("TRANSFORM(" T ") '%s' (p:'%s' reg:'%s')\n", RSTRING_PTR(str), p, reg);*/  \
      else
        @regs[t.to_sym] = nil
      end
    end
    def STORE(t)
      if (@reg && @p > @reg && @reg >= @ts)
        str = @data[@reg, @p - @reg]
        @regs[t.to_sym] = str
        # /*printf("STORE(" T ") '%s' (p:'%s' reg:'%s')\n", RSTRING_PTR(str), p, reg);*/  \
      else
        @regs[t.to_sym] = nil
      end
    end
    def STORE_B(t)
      if (@bck && @p > @bck && @bck >= @ts)
        str = @data[@bck, @p - @bck]
        @regs[t.to_sym] = str
        # /*printf("STORE_B(" T ") '%s' (p:'%s' reg:'%s')\n", RSTRING_PTR(str), p, reg);*/  \
      else
        @regs[t.to_sym] = nil
      end
    end
    def STORE_ATTR(t)
      if (@attr_reg && @p > @attr_reg && (@attr_reg >= (@ts || 0)))
        str = @data[@attr_reg, @p - @attr_reg]
        @attr_regs[t.to_sym] = str
        # /*printf("STORE_B(" T ") '%s' (p:'%s' reg:'%s')\n", RSTRING_PTR(str), p, reg);*/  \
      else
        @attr_regs[t.to_sym] = nil
      end
    end
    def STORE_URL(t)
      if (@reg && @p > @reg && @reg >= @ts)
        punct = true
        while (@p > @reg && punct)
          case @data[@p - 1, 1]
          when ')'
            temp_p = @p - 1
            level = -1
            while (temp_p > @reg)
              case @data[temp_p - 1, 1]
                when '('; level += 1
                when ')'; level -= 1
              end
              temp_p -= 1
            end
            if (level == 0) 
              punct = false
            else
              @p -= 1
            end
          when '!', '"', '#', '$', '%', ']', '[', '&', '\'',
            '*', '+', ',', '-', '.', '(', ':', ';', '=', 
            '?', '@', '\\', '^', '_', '`', '|', '~'
              @p -= 1
          else
            punct = false
          end
        end
        @te = @p
      end
      STORE(t)
      if ( ! @refs.nil? && @refs.has_key?(@regs[t.to_sym]) )
        @regs[t.to_sym] = @refs[@regs[t.to_sym]]
      end
    end
    def STORE_LINK_ALIAS()
      @refs_found[@regs[:text]] = @regs[:href]
    end
    def CLEAR_LIST()
      @list_layout = []
    end
    def SET_LIST_TYPE(t)
      @list_type = t
    end
    def NEST()
      @nest += 1
    end
    def RESET_NEST()
      @nest = 0
    end
    def LIST_LAYOUT()
      aint = 0
      aval = @list_index[@nest-1]
      aint = aval.to_i unless aval.nil?
      if (@list_type == "ol" && @nest > 0)
        @list_index[@nest-1] = aint + 1
      end
      if (@nest > @list_layout.length)
        SET_ATTRIBUTES();
        listm = sprintf("%s_open", @list_type)
        if (@regs[:list_continue])
          @regs[:list_continue] = nil
          @regs[:start] = @list_index[@nest-1]
        else
          start = @regs[:start]
          if (start.nil?)
            @list_index[@nest-1] = 1
          else
            start_num = start.to_i
            @list_index[@nest-1] = start_num
          end
        end
        @regs[:nest] = @nest
        @html << @textile_doc.send(listm, @regs)
        @list_layout[@nest-1] = @list_type
        CLEAR_REGS()
        ASET("first", true)
      end
      LIST_CLOSE()
      LIST_ITEM_CLOSE() unless @nest == 0
      CLEAR_REGS()
      @regs[:nest] = @list_layout.length
      ASET("type", "li_open")
    end
    def LIST_ITEM_CLOSE()
      @html << @textile_doc.send("li_close", @regs) unless @regs[:first]
    end
    def LIST_CLOSE()
      while (@nest < @list_layout.length)
        @regs[:nest] = @list_layout.length
        end_list = @list_layout.pop
        if (!end_list.nil?)
          listm = sprintf("%s_close", end_list)
          LIST_ITEM_CLOSE()
          @html << @textile_doc.send(listm, @regs)
        end
      end
    end

    def red_pass(regs, ref, meth, refs)
      txt = regs[ref]
      regs[ref] = RedCloth::RedclothInline.redcloth_inline2(@textile_doc, txt, refs) if (!txt.nil?)
      return @textile_doc.send(meth, regs)
    end

    def red_inc(regs, ref)
      aint = 0
      aval = regs[ref]
      aint = aval.to_i if (!aval.nil?)
      regs[ref] = aint + 1
    end

    def red_block(regs, block, refs)
      sym_text = :text
      btype = @regs[:type]
      block = block.strip
      if (!block.nil? && !btype.nil?)
        method = btype.intern
        if (method == :notextile)
          @regs[sym_text] = block
        else
          @regs[sym_text] = RedCloth::RedclothInline.redcloth_inline2(@textile_doc, block, refs)
        end
        if (@textile_doc.send(:formatter_methods).include? method) #FIXME: This is a hack to get around private method.
          block = @textile_doc.send(method, @regs)
        else
          fallback = @regs[:fallback]
          if (!fallback.nil?)
            fallback << @regs[sym_text]
            CLEAR_REGS()
            @regs[sym_text] = fallback
          end
          block = @textile_doc.p(@regs);
        end
      end
      return block
    end

    def red_blockcode(regs, block)
      btype = regs[:type]
      if (block.length > 0)
        regs[:text] = block
        block = @textile_doc.send(btype, regs)
      end
      return block
    end

    def rb_str_cat_escaped(str, ts, te)
      source_str = STR_NEW(ts, te-ts);
      escaped_str = @textile_doc.send(:escape, source_str) #FIXME: This is a hack to get around private method.
      str << escaped_str
    end

    def rb_str_cat_escaped_for_preformatted(str, text)
      escaped_str = @textile_doc.send(:escape_pre, text) #FIXME: This is a hack to get around private method.
      str << escaped_str
    end
  end
  
  class RedclothScan < BaseScanner
    def self.transform(textile_doc, data, refs)
      self.new.transform(textile_doc, data, refs)
    end
    
    def transform(textile_doc, data, refs)
      @textile_doc = textile_doc
      @data = data + "\0"
      @refs = refs
      @p = 0
      @pe = @data.length
      @orig_data = data.dup
      @html = ""
      @table = ""
      @block = ""
      CLEAR_REGS()
    
      @list_layout = nil
      @list_index = [];
      SET_PLAIN_BLOCK("p")
      @extend = nil
      @listm = []
      @refs_found = {}
    
      %% write init;
      %% write exec;

      ADD_BLOCK() if (block.length > 0)

      if ( refs.nil? && !refs_found.empty? )
        return transform(@textile_doc, orig_data, refs_found)
      else
        @textile_doc.send(:after_transform, html)
        return html
      end
    end
    
    def initialize
      %%{
        variable data  @data;
        variable p     @p;
        variable pe    @pe;
        variable cs    @cs;
        variable ts    @ts;
        variable te    @te;

        write data nofinal;
      }%%
    end
  end
end