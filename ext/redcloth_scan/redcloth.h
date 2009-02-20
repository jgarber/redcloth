#ifndef redcloth_h
#define redcloth_h

#ifndef RARRAY_LEN
#define RARRAY_LEN(arr)  RARRAY(arr)->len
#define RSTRING_LEN(str) RSTRING(str)->len
#define RSTRING_PTR(str) RSTRING(str)->ptr
#endif


// Different string conversions for ruby 1.8 and ruby 1.9. For 1.9, 
// we need to set the encoding of the string.

// For Ruby 1.9
#ifdef HAVE_RUBY_ENCODING_H
#include "ruby/encoding.h"
#define STR_NEW(p,n) rb_enc_str_new((p),(n),rb_utf8_encoding())
#define STR_NEW2(p) rb_enc_str_new((p),strlen(p),rb_utf8_encoding())

// For Ruby 1.8
#else
#define STR_NEW(p,n) rb_str_new((p),(n))
#define STR_NEW2(p) rb_str_new2((p))

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
VALUE red_parse_title(VALUE, VALUE);
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
#define CLEAR(H)       H = STR_NEW2("")
#define RSTRIP_BANG(H)      rb_funcall(H, rb_intern("rstrip!"), 0)
#define SET_PLAIN_BLOCK(T) plain_block = STR_NEW2(T)
#define RESET_TYPE(T)  rb_hash_aset(regs, ID2SYM(rb_intern("type")), plain_block)
#define INLINE(H, T)   rb_str_append(H, rb_funcall(self, rb_intern(T), 1, regs))
#define DONE(H)        rb_str_append(html, H); CLEAR(H); CLEAR_REGS()
#define PASS(H, A, T)  rb_str_append(H, red_pass(self, regs, ID2SYM(rb_intern(A)), rb_intern(T), refs))
#define PARSE_ATTR(A)  red_parse_attr(self, regs, ID2SYM(rb_intern(A)))
#define PARSE_LINK_ATTR(A)  red_parse_link_attr(self, regs, ID2SYM(rb_intern(A)))
#define PARSE_IMAGE_ATTR(A)  red_parse_image_attr(self, regs, ID2SYM(rb_intern(A)))
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
#define ASET(T, V)     rb_hash_aset(regs, ID2SYM(rb_intern(T)), STR_NEW2(V));
#define AINC(T)        red_inc(regs, ID2SYM(rb_intern(T)));
#define SET_ATTRIBUTES() \
  SET_ATTRIBUTE("class_buf", "class"); \
  SET_ATTRIBUTE("id_buf", "id"); \
  SET_ATTRIBUTE("lang_buf", "lang"); \
  SET_ATTRIBUTE("style_buf", "style");
#define SET_ATTRIBUTE(B, A) \
  if (rb_hash_aref(regs, ID2SYM(rb_intern(B))) != Qnil) rb_hash_aset(regs, ID2SYM(rb_intern(A)), rb_hash_aref(regs, ID2SYM(rb_intern(B))));
#define TRANSFORM(T) \
  if (p > reg && reg >= ts) { \
    VALUE str = redcloth_transform(self, reg, p, refs); \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), str); \
    /*printf("TRANSFORM(" T ") '%s' (p:'%s' reg:'%s')\n", RSTRING_PTR(str), p, reg);*/  \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), Qnil); \
  }
#define STORE(T)  \
  if (p > reg && reg >= ts) { \
    VALUE str = STR_NEW(reg, p-reg); \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), str); \
    /*printf("STORE(" T ") '%s' (p:'%s' reg:'%s')\n", RSTRING_PTR(str), p, reg);*/  \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), Qnil); \
  }
#define STORE_B(T)  \
  if (p > bck && bck >= ts) { \
    VALUE str = STR_NEW(bck, p-bck); \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), str); \
    /*printf("STORE_B(" T ") '%s' (p:'%s' reg:'%s')\n", RSTRING_PTR(str), p, reg);*/  \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(T)), Qnil); \
  }
#define STORE_URL(T) \
  if (p > reg && reg >= ts) { \
    char punct = 1; \
    while (p > reg && punct == 1) { \
      switch (*(p - 1)) { \
        case ')': \
          { /*needed to keep inside chars scoped for less memory usage*/\
            char *temp_p = p - 1; \
            char level = -1; \
            while (temp_p > reg) { \
              switch(*(temp_p - 1)) { \
                case '(': ++level; break; \
                case ')': --level; break; \
              } \
              --temp_p; \
            } \
            if (level == 0) { punct = 0; } else { --p; } \
          } \
          break;  \
        case '!': case '"': case '#': case '$': case '%': case ']': case '[': case '&': case '\'': \
        case '*': case '+': case ',': case '-': case '.': case '(':  case ':':  \
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
    if (nest > RARRAY_LEN(list_layout)) \
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
      rb_ary_store(list_layout, nest-1, STR_NEW2(list_type)); \
      CLEAR_REGS(); \
      ASET("first", "true"); \
    } \
    LIST_CLOSE(); \
    rb_hash_aset(regs, ID2SYM(rb_intern("nest")), INT2NUM(RARRAY_LEN(list_layout))); \
    ASET("type", "li_open")
#define LIST_CLOSE() \
    while (nest < RARRAY_LEN(list_layout)) \
    { \
      rb_hash_aset(regs, ID2SYM(rb_intern("nest")), INT2NUM(RARRAY_LEN(list_layout))); \
      VALUE end_list = rb_ary_pop(list_layout); \
      if (!NIL_P(end_list)) \
      { \
        StringValue(end_list); \
        sprintf(listm, "%s_close", RSTRING_PTR(end_list)); \
        rb_str_append(html, rb_funcall(self, rb_intern(listm), 1, regs)); \
      } \
    }

#endif
