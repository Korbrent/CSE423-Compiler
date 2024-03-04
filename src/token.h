/**
 * @file token.h 
 * @author Korbin Shelley
 * @brief This file contains the token structure and function prototypes for token.c
 * @version hw3
 * @date Feb 19, 2024
 * 
 */
#ifndef TOKEN_H
#define TOKEN_H
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Struct containing token information
struct token {
    int category;   /* int code returned by yylex() */
    char *text;     /* text of the token */
    int lineno;     /* line number where token occurs */
    char *filename; /* file where token occurs */
    int ival;       /* integer value of token */
    double dval;    /* double value of token */
    char *sval;     /* string value of token */
};

struct token *buildToken(int type, char *text, int lineno, char *filename);
void string_literal_parser(char *input, char *output);
int char_literal_parser(char *input);

void tokenfree(struct token *t);

#endif