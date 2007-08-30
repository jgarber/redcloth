#ifndef superredcloth_h
#define superredcloth_h

/* variable defs */
#ifndef superredcloth_scan_c
extern VALUE super_ParseError, super_RedCloth;
#endif

/* function defs */
void rb_str_cat_escaped(VALUE str, char *tokstart, char *tokend);
VALUE superredcloth_inline(VALUE, char *, char *);
VALUE superredcloth_inline2(VALUE, VALUE);
VALUE superredcloth_transform(VALUE, char *, char *);
VALUE superredcloth_transform2(VALUE, VALUE);
void red_inc(VALUE, VALUE);
VALUE red_block(VALUE, VALUE, ID);
VALUE red_pass2(VALUE, VALUE, VALUE, VALUE);
VALUE red_pass(VALUE, VALUE, VALUE, ID);

/* parser macros */
#define CAT(H)         rb_str_cat(H, tokstart, tokend-tokstart)
#define CLEAR(H)       H = rb_str_new2("")
#define INLINE(H, T)   rb_str_append(H, rb_funcall(rb_formatter, rb_intern(#T), 1, regs))
#define DONE(H)        rb_str_append(html, H); CLEAR(H); regs = rb_hash_new()
#define PASS(H, A, T)  rb_str_append(H, red_pass(rb_formatter, regs, ID2SYM(rb_intern(#A)), rb_intern(#T)))
#define PASS2(H, A, T) rb_str_append(H, red_pass2(rb_formatter, regs, ID2SYM(rb_intern(#A)), ID2SYM(rb_intern(#T))))
#define ADD_BLOCK()    rb_str_append(html, red_block(rb_formatter, regs, block)); CLEAR(block); regs = rb_hash_new()
#define ASET(T, V)     rb_hash_aset(regs, ID2SYM(rb_intern(#T)), rb_str_new2(#V));
#define AINC(T)        red_inc(regs, ID2SYM(rb_intern(#T)));
#define STORE(T)  \
  if (p > reg && reg >= tokstart) { \
    while (reg < p && ( *reg == '\r' || *reg == '\n' ) ) { reg++; } \
    while (p > reg && ( *(p - 1) == '\r' || *(p - 1) == '\n' ) ) { p--; } \
  } \
  if (p > reg && reg >= tokstart) { \
    VALUE str = rb_str_new(reg, p-reg); \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), str); \
    /* printf("STORE(" #T ") %s\n", RSTRING(str)->ptr); */ \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), Qnil); \
  }
#define STORE_URL(T) \
  if (p > reg && reg >= tokstart) { \
    p++; \
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
    tokend = p; \
  } \
  STORE(T); \
  p--;
#define LIST_ITEM() \
    char listm[10] = ""; \
    if (nest > RARRAY(list_layout)->len) \
    { \
      sprintf(listm, "%s_open", list_type); \
      rb_str_append(html, rb_funcall(rb_formatter, rb_intern(listm), 1, regs)); \
      rb_ary_store(list_layout, nest-1, rb_str_new2(list_type)); \
      regs = rb_hash_new(); \
      ASET(first, true); \
    } \
    while (nest < RARRAY(list_layout)->len) \
    { \
      VALUE end_list = rb_ary_pop(list_layout); \
      if (!NIL_P(end_list)) \
      { \
        StringValue(end_list); \
        sprintf(listm, "%s_close", RSTRING(end_list)->ptr); \
        rb_str_append(html, rb_funcall(rb_formatter, rb_intern(listm), 1, regs)); \
      } \
    } \
    ASET(type, li_open)

#endif
