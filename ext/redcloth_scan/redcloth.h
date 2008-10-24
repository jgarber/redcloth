#ifndef redcloth_h
#define redcloth_h

/* Backward compatibility with Ruby < 1.8.6 */
#ifndef RSTRING_LEN
#define RSTRING_LEN(x) (RSTRING(x)->len)
#endif
#ifndef RSTRING_PTR
#define RSTRING_PTR(x) (RSTRING(x)->ptr)
#endif

/* variable defs */
#ifndef redcloth_scan_c
extern VALUE super_ParseError, mRedCloth, super_RedCloth;
extern int SYM_escape_preformatted;
#endif

/* function defs */
void rb_str_cat_escaped(VALUE self, VALUE str, char *ts, char *te);
void rb_str_cat_escaped_for_preformatted(VALUE self, VALUE str, char *ts, char *te);
VALUE redcloth_inline(VALUE, char *, char *, VALUE);
VALUE redcloth_inline2(VALUE, VALUE, VALUE);
VALUE redcloth_attribute_parser(int, VALUE, char *, char *);
VALUE redcloth_attributes(VALUE, VALUE);
VALUE redcloth_link_attributes(VALUE, VALUE);
VALUE redcloth_transform(VALUE, char *, char *, VALUE);
VALUE redcloth_transform2(VALUE, VALUE);
void red_inc(VALUE, VALUE);
VALUE red_block(VALUE, VALUE, VALUE, VALUE);
VALUE red_blockcode(VALUE, VALUE, VALUE);
VALUE red_pass(VALUE, VALUE, VALUE, ID, VALUE);
VALUE red_pass_code(VALUE, VALUE, VALUE, ID);

/* parser macros */
#define CLEAR_REGS()   regs = rb_hash_new();
#define RESET_REG()    reg = NULL
#define CAT(H)         rb_str_cat(H, ts, te-ts)
#define CLEAR(H)       H = rb_str_new2("")
#define SET_PLAIN_BLOCK(T) plain_block = rb_str_new2(T)
#define RESET_TYPE(T)  rb_hash_aset(regs, ID2SYM(rb_intern("type")), plain_block)
#define INLINE(H, T)   rb_str_append(H, rb_funcall(self, rb_intern(T), 1, regs))
#define DONE(H)        rb_str_append(html, H); CLEAR(H); CLEAR_REGS()
#define PASS(H, A, T)  rb_str_append(H, red_pass(self, regs, ID2SYM(rb_intern(A)), rb_intern(T), refs))
#define PARSE_ATTR(A)  red_parse_attr(self, regs, ID2SYM(rb_intern(A)))
#define PARSE_LINK_ATTR(A)  red_parse_link_attr(self, regs, ID2SYM(rb_intern(A)))
#define PASS_CODE(H, A, T, O) rb_str_append(H, red_pass_code(self, regs, ID2SYM(rb_intern(A)), rb_intern(T)))
#define ADD_BLOCK() \
  rb_str_append(html, red_block(self, regs, block, refs)); \
  extend = Qnil; \
  CLEAR(block); \
  CLEAR_REGS()
#define ADD_EXTENDED_BLOCK()    rb_str_append(html, red_block(self, regs, block, refs)); CLEAR(block);
#define END_EXTENDED()     extend = Qnil; CLEAR_REGS();
#define IS_NOT_EXTENDED()     NIL_P(extend)
#define ADD_BLOCKCODE()    rb_str_append(html, red_blockcode(self, regs, block)); CLEAR(block); CLEAR_REGS()
#define ADD_EXTENDED_BLOCKCODE()    rb_str_append(html, red_blockcode(self, regs, block)); CLEAR(block);
#define ASET(T, V)     rb_hash_aset(regs, ID2SYM(rb_intern(T)), rb_str_new2(V));
#define AINC(T)        red_inc(regs, ID2SYM(rb_intern(T)));
#define SET_ATTRIBUTES() \
  VALUE buf = Qnil; \
  SET_ATTRIBUTE("class_buf", "class"); \
  SET_ATTRIBUTE("id_buf", "id"); \
  SET_ATTRIBUTE("lang_buf", "lang"); \
  SET_ATTRIBUTE("style_buf", "style");
#define SET_ATTRIBUTE(B, A) \
  buf = rb_hash_aref(regs, ID2SYM(rb_intern(B))); \
  if (buf != Qnil) rb_hash_aset(regs, ID2SYM(rb_intern(A)), buf);
#define TRANSFORM(T) \
  if (p > reg && reg >= ts) { \
    VALUE str = redcloth_transform(self, reg, p, refs); \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), str); \
  /*  printf("TRANSFORM(" T ") '%s' (p:'%d' reg:'%d')\n", RSTRING(str)->ptr, p, reg);*/  \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), Qnil); \
  }
#define STORE(T)  \
  if (p > reg && reg >= ts) { \
    VALUE str = rb_str_new(reg, p-reg); \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), str); \
  /*  printf("STORE(" T ") '%s' (p:'%d' reg:'%d')\n", RSTRING(str)->ptr, p, reg);*/  \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), Qnil); \
  }
#define STORE_B(T)  \
  if (p > bck && bck >= ts) { \
    VALUE str = rb_str_new(bck, p-bck); \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), str); \
  /*  printf("STORE_B(" T ") '%s' (p:'%d' reg:'%d')\n", RSTRING(str)->ptr, p, reg);*/  \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), Qnil); \
  }
#define STORE_URL(T) \
  if (p > reg && reg >= ts) { \
    char punct = 1; \
    while (p > reg && punct == 1) { \
      switch (*(p - 1)) { \
        case '!': case '"': case '#': case '$': case '%': case ']': case '[': case '&': case '\'': \
        case '*': case '+': case ',': case '-': case '.': case ')': case '(': case ':':  \
        case ';': case '=': case '?': case '@': case '\\': case '^': case '_': \
        case '`': case '|': case '~': p--; break; \
        default: punct = 0; \
      } \
    } \
    te = p; \
  } \
  STORE(T); \
  if ( !NIL_P(refs) && rb_funcall(refs, rb_intern("has_key?"), 1, rb_hash_aref(regs, ID2SYM(rb_intern(T)))) ) { \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), rb_hash_aref(refs, rb_hash_aref(regs, ID2SYM(rb_intern(T))))); \
  }
#define STORE_LINK_ALIAS() \
  rb_hash_aset(refs_found, rb_hash_aref(regs, ID2SYM(rb_intern("text"))), rb_hash_aref(regs, ID2SYM(rb_intern("href"))))
#define CLEAR_LIST() list_layout = rb_ary_new()
#define LIST_ITEM() \
    int aint = 0; \
    VALUE aval = rb_ary_entry(list_index, nest-1); \
    if (aval != Qnil) aint = NUM2INT(aval); \
    if (strcmp(list_type, "ol") == 0) \
    { \
      rb_ary_store(list_index, nest-1, INT2NUM(aint + 1)); \
    } \
    if (nest > RARRAY(list_layout)->len) \
    { \
      sprintf(listm, "%s_open", list_type); \
      if (list_continue == 1) \
      { \
        list_continue = 0; \
        rb_hash_aset(regs, ID2SYM(rb_intern("start")), rb_ary_entry(list_index, nest-1)); \
      } \
      else \
      { \
        VALUE start = rb_hash_aref(regs, ID2SYM(rb_intern("start"))); \
        if (NIL_P(start) ) \
        { \
          rb_ary_store(list_index, nest-1, INT2NUM(1)); \
        } \
        else \
        { \
          VALUE start_num = rb_funcall(start,rb_intern("to_i"),0); \
          rb_ary_store(list_index, nest-1, start_num); \
        } \
      } \
      rb_hash_aset(regs, ID2SYM(rb_intern("nest")), INT2NUM(nest)); \
      rb_str_append(html, rb_funcall(self, rb_intern(listm), 1, regs)); \
      rb_ary_store(list_layout, nest-1, rb_str_new2(list_type)); \
      CLEAR_REGS(); \
      ASET("first", "true"); \
    } \
    LIST_CLOSE(); \
    rb_hash_aset(regs, ID2SYM(rb_intern("nest")), INT2NUM(RARRAY(list_layout)->len)); \
    ASET("type", "li_open")
#define LIST_CLOSE() \
    while (nest < RARRAY(list_layout)->len) \
    { \
      rb_hash_aset(regs, ID2SYM(rb_intern("nest")), INT2NUM(RARRAY(list_layout)->len)); \
      VALUE end_list = rb_ary_pop(list_layout); \
      if (!NIL_P(end_list)) \
      { \
        StringValue(end_list); \
        sprintf(listm, "%s_close", RSTRING_PTR(end_list)); \
        rb_str_append(html, rb_funcall(self, rb_intern(listm), 1, regs)); \
      } \
    }

#endif
