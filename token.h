/**
 * @file token.h 
 * @author Korbin Shelley
 * @brief type table header for the lexical analyzer
 * @version lab1
 * @date 2024-01-26
 * 
 */
#ifndef TOKEN_H
#define TOKEN_H
#endif

struct token {
    int category;   /* int code returned by yylex() */
    char *text;     /* text of the token */
    int lineno;     /* line number where token occurs */
    char *filename; /* file where token occurs */
    int ival;       /* integer value of token */
    double dval;    /* double value of token */
    char *sval;     /* string value of token */
};
