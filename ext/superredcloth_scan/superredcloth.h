#ifndef superredcloth_h
#define superredcloth_h

/* variable defs */
#ifndef superredcloth_scan_c
extern VALUE super_ParseError, super_RedCloth;
#endif

/* function defs */
void rb_str_cat_escaped(VALUE str, char *tokstart, char *tokend);
VALUE superredcloth_inline(char *p, char *pe);
VALUE superredcloth_inline2(VALUE str);
VALUE superredcloth_transform(char *p, char *pe);
VALUE superredcloth_transform2(VALUE str);
void red_inc(VALUE regs, VALUE ref);
VALUE red_block(VALUE block, ID meth);
VALUE red_pass2(VALUE regs, VALUE ref, VALUE btype);
VALUE red_pass(VALUE regs, VALUE ref, ID meth);

/* parser macros */
#define CLEAR(H)       H = rb_str_new2("")
#define INLINE(H, T)   rb_str_append(H, rb_funcall(super_RedCloth, rb_intern(#T), 1, regs))
#define DONE(H)        rb_str_append(html, H); CLEAR(H)
#define PASS(H, A, T)  rb_str_append(H, red_pass(regs, ID2SYM(rb_intern(#A)), rb_intern(#T)))
#define PASS2(H, A, T) rb_str_append(H, red_pass2(regs, ID2SYM(rb_intern(#A)), ID2SYM(rb_intern(#T))))
#define BLOCK(T)       block = red_block(block, rb_intern(#T)); DONE(block)
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
  STORE(T)

#endif
