#ifndef redcloth_h
#define redcloth_h

/* variable defs */
#ifndef redcloth_scan_c
extern VALUE super_ParseError, super_RedCloth;
extern int SYM_html_escape_entities;
#endif

/* function defs */
void rb_str_cat_escaped(VALUE str, char *ts, char *te, unsigned int opts);
void rb_str_cat_escaped_for_preformatted(VALUE str, char *ts, char *te, unsigned int opts);
VALUE redcloth_inline(VALUE, char *, char *, VALUE);
VALUE redcloth_inline2(VALUE, VALUE, VALUE);
VALUE redcloth_transform(VALUE, char *, char *, VALUE);
VALUE redcloth_transform2(VALUE, VALUE);
void red_inc(VALUE, VALUE);
VALUE red_block(VALUE, VALUE, ID, VALUE);
VALUE red_blockcode(VALUE, VALUE, VALUE);
VALUE red_pass2(VALUE, VALUE, VALUE, VALUE, VALUE);
VALUE red_pass(VALUE, VALUE, VALUE, ID, VALUE);
VALUE red_pass_code(VALUE, VALUE, VALUE, ID, unsigned int opts);

/* parsing options */
#define SR_HTML_ESCAPE_ENTITIES 2

/* parser macros */
#define CAT(H)         rb_str_cat(H, ts, te-ts)
#define CLEAR(H)       H = rb_str_new2("")
#define INLINE(H, T)   rb_str_append(H, rb_funcall(rb_formatter, rb_intern(#T), 1, regs))
#define DONE(H)        rb_str_append(html, H); CLEAR(H); regs = rb_hash_new()
#define PASS(H, A, T)  rb_str_append(H, red_pass(rb_formatter, regs, ID2SYM(rb_intern(#A)), rb_intern(#T), refs))
#define PASS2(H, A, T) rb_str_append(H, red_pass2(rb_formatter, regs, ID2SYM(rb_intern(#A)), ID2SYM(rb_intern(#T)), refs))
#define PASS_CODE(H, A, T, O) rb_str_append(H, red_pass_code(rb_formatter, regs, ID2SYM(rb_intern(#A)), rb_intern(#T), O))
#define ADD_BLOCK() \
  rb_str_append(html, red_block(rb_formatter, regs, block, refs)); \
  extend = Qnil; \
  CLEAR(block); \
  regs = rb_hash_new()
#define ADD_EXTENDED_BLOCK()    rb_str_append(html, red_block(rb_formatter, regs, block, refs)); CLEAR(block);
#define END_EXTENDED()     extend = Qnil; regs = rb_hash_new();
#define ADD_BLOCKCODE()    rb_str_append(html, red_blockcode(rb_formatter, regs, block)); CLEAR(block); regs = rb_hash_new()
#define ADD_EXTENDED_BLOCKCODE()    rb_str_append(html, red_blockcode(rb_formatter, regs, block)); CLEAR(block);
#define ASET(T, V)     rb_hash_aset(regs, ID2SYM(rb_intern(#T)), rb_str_new2(#V));
#define AINC(T)        red_inc(regs, ID2SYM(rb_intern(#T)));
#define TRANSFORM(T) \
  if (p > reg && reg >= ts) { \
    while (reg < p && ( *reg == '\r' || *reg == '\n' ) ) { reg++; } \
    while (p > reg && ( *(p - 1) == '\r' || *(p - 1) == '\n' ) ) { p--; } \
  } \
  if (p > reg && reg >= ts) { \
    VALUE str = redcloth_transform(rb_formatter, reg, p, refs); \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), str); \
  /*  printf("TRANSFORM(" #T ") '%s' (p:'%d' reg:'%d')\n", RSTRING(str)->ptr, p, reg);*/  \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), Qnil); \
  }
#define STORE(T)  \
  if (p > reg && reg >= ts) { \
    while (reg < p && ( *reg == '\r' || *reg == '\n' ) ) { reg++; } \
    while (p > reg && ( *(p - 1) == '\r' || *(p - 1) == '\n' ) ) { p--; } \
  } \
  if (p > reg && reg >= ts) { \
    VALUE str = rb_str_new(reg, p-reg); \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), str); \
  /*  printf("STORE(" #T ") '%s' (p:'%d' reg:'%d')\n", RSTRING(str)->ptr, p, reg);*/  \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), Qnil); \
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
  if ( !NIL_P(refs) && rb_funcall(refs, rb_intern("has_key?"), 1, rb_hash_aref(regs, ID2SYM(rb_intern(#T)))) ) { \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), rb_hash_aref(refs, rb_hash_aref(regs, ID2SYM(rb_intern(#T))))); \
  }
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
      rb_str_append(html, rb_funcall(rb_formatter, rb_intern(listm), 1, regs)); \
      rb_ary_store(list_layout, nest-1, rb_str_new2(list_type)); \
      regs = rb_hash_new(); \
      ASET(first, true); \
    } \
    LIST_CLOSE(); \
    rb_hash_aset(regs, ID2SYM(rb_intern("nest")), INT2NUM(RARRAY(list_layout)->len)); \
    ASET(type, li_open)
#define LIST_CLOSE() \
    while (nest < RARRAY(list_layout)->len) \
    { \
      rb_hash_aset(regs, ID2SYM(rb_intern("nest")), INT2NUM(RARRAY(list_layout)->len)); \
      VALUE end_list = rb_ary_pop(list_layout); \
      if (!NIL_P(end_list)) \
      { \
        StringValue(end_list); \
        sprintf(listm, "%s_close", RSTRING(end_list)->ptr); \
        rb_str_append(html, rb_funcall(rb_formatter, rb_intern(listm), 1, regs)); \
      } \
    }

#endif
