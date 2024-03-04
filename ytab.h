/**
 * @file ytab.h 
 * @author Korbin Shelley
 * @brief type table header for the lexical analyzer
 * @version lab1
 * @date 2024-01-26
 * 
 */
#ifndef YTAB_H
#define YTAB_H

// Error tokens
#define UNUSED_KEYWORD 401
#define UNUSED_SYMBOL 402
#define UNCAUGHT_TOKEN 404

// Identifier token
#define IDENTIFIER 257

// Keywords
#define AS 258
#define BREAK 259
#define CONST 260
#define CONTINUE 261
#define CRATE 262
#define ELSE 263
#define ENUM 264
#define EXTERN 265
#define FALSE 266
#define FN 267
#define FOR 268
#define IF 269
#define IMPL 270
#define IN 271
#define LET 272
#define LOOP 273
#define MATCH 274
#define MOD 275
#define MOVE 276
#define MUT 277
#define PUB 278
#define REF 279
#define RETURN 280
#define SELF 281
#define SELF_CAP 282
#define STATIC 283
#define STRUCT 284
#define SUPER 285
#define TRAIT 286
#define TRUE 287
#define TYPE 288
#define UNSAFE 289
#define USE 290
#define WHERE 291
#define WHILE 292

// Unused keywords
#define ASYNC UNUSED_KEYWORD
#define AWAIT UNUSED_KEYWORD
#define DYN UNUSED_KEYWORD

#define ABSTRACT UNUSED_KEYWORD
#define BECOME UNUSED_KEYWORD
#define BOX UNUSED_KEYWORD
#define DO UNUSED_KEYWORD
#define FINAL UNUSED_KEYWORD
#define MACRO UNUSED_KEYWORD
#define OVERRIDE UNUSED_KEYWORD
#define PRIV UNUSED_KEYWORD
#define TRY UNUSED_KEYWORD
#define TYPEOF UNUSED_KEYWORD
#define UNSIZED UNUSED_KEYWORD
#define VIRTUAL UNUSED_KEYWORD
#define YIELD UNUSED_KEYWORD

// Symbols
#define EQUAL 310
#define DOUBLE_EQUAL 311
#define BANG 312
#define NOT_EQUAL 313
#define LESS_THAN 314
#define LESS_THAN_EQUAL 315
#define DOUBLE_LESS_THAN UNUSED_SYMBOL
#define DOUBLE_LESS_THAN_EQUAL UNUSED_SYMBOL
#define GREATER_THAN 318
#define GREATER_THAN_EQUAL 319
#define DOUBLE_GREATER_THAN UNUSED_SYMBOL
#define DOUBLE_GREATER_THAN_EQUAL UNUSED_SYMBOL
#define AMPERSAND UNUSED_SYMBOL
#define AMPERSAND_EQUAL UNUSED_SYMBOL
#define DOUBLE_AMPERSAND 324
#define PIPE UNUSED_SYMBOL
#define PIPE_EQUAL UNUSED_SYMBOL
#define DOUBLE_PIPE 327
#define CARET UNUSED_SYMBOL
#define CARET_EQUAL UNUSED_SYMBOL

#define PLUS 330
#define PLUS_EQUAL 331
#define MINUS 332
#define MINUS_EQUAL 333
#define STAR 334
#define STAR_EQUAL 335
#define SLASH 336
#define SLASH_EQUAL 337
#define PERCENT 338
#define PERCENT_EQUAL 339

#define ARROW 340
#define FAT_ARROW 341
#define COMMA 342
#define SEMICOLON 343
#define COLON 344
#define DOUBLE_COLON 345
#define DOT 346
#define DOUBLE_DOT 347
#define DOUBLE_DOT_EQUALS 348
#define QUESTION 349
#define AT 350
#define UNDERSCORE 351
#define LEFT_PAREN 352
#define RIGHT_PAREN 353
#define LEFT_BRACKET 354
#define RIGHT_BRACKET 355
#define LEFT_BRACE 356
#define RIGHT_BRACE 357

#define STRING_LITERAL 360
#define INTEGER_LITERAL 361
#define FLOAT_LITERAL 362
#endif

