#ifndef superredcloth_h
#define superredcloth_h

/* variable defs */
VALUE super_ParseError, super_RedCloth;

/* function defs */
void rb_str_cat_escaped(VALUE str, char *tokstart, char *tokend);
VALUE superredcloth_inline(char *p, char *pe);
VALUE superredcloth_inline2(VALUE str);
VALUE superredcloth_transform(char *p, char *pe);
VALUE superredcloth_transform2(VALUE str);

/* parser macros */
#define INLINE(T)    rb_str_append(block, rb_funcall(super_RedCloth, rb_intern(#T), 1, regs))
#define BLOCK(T) \
  { \
    VALUE sblock = rb_funcall(block, rb_intern("strip"), 0); \
    if (RSTRING(sblock)->len > 0) \
    { \
      rb_str_append(html, rb_funcall(super_RedCloth, rb_intern(#T), 1, superredcloth_inline2(sblock))); \
    } \
    block = rb_str_new2(""); \
  }
#define FORMAT(A, T) \
  { \
    rb_hash_aset(regs, ID2SYM(rb_intern(#A)), superredcloth_inline2(rb_hash_aref(regs, ID2SYM(rb_intern(#A))))); \
    rb_str_append(block, rb_funcall(super_RedCloth, rb_intern(#T), 1, regs)); \
  }
#define FORMAT_BLOCK(A, T) \
  { \
    /* rb_p(regs); */ \
    VALUE btype = rb_hash_aref(regs, ID2SYM(rb_intern(#T))); \
    rb_hash_aset(regs, ID2SYM(rb_intern(#A)), superredcloth_inline2(rb_hash_aref(regs, ID2SYM(rb_intern(#A))))); \
    StringValue(btype); \
    rb_str_append(html, rb_funcall(super_RedCloth, rb_intern(RSTRING(btype)->ptr), 1, regs)); \
    block = rb_str_new2(""); \
  }
#define ASET(T, V)  \
  rb_hash_aset(regs, ID2SYM(rb_intern(#T)), ID2SYM(rb_intern(#V)));
#define AINC(T)  \
  { \
    int aint = 0; \
    VALUE aval = rb_hash_aref(regs, ID2SYM(rb_intern(#T))); \
    if (aval != Qnil) aint = NUM2INT(aval); \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), INT2NUM(aint + 1)); \
  }
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
