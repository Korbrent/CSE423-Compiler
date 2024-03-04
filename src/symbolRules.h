/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: symbolRules.h
 * @brief: Declarations of the rules and enums for the symbols
 * 
 * @version: 0.4.6
*/
#ifndef SYMBOLRULES_H_
#define SYMBOLRULES_H_

typedef enum {
    GLOBAL,
    LOCAL,
    PARAM,
    FUNCTION,
    UNKNOWN
} symbol_t;

typedef enum {
    EXPLICIT,
    IMPLICIT,
} declaration_t;

typedef enum {
    INT_8,
    INT_16,
    INT_32,
    INT_64,
    INT_128,
    U_INT_8,
    U_INT_16,
    U_INT_32,
    U_INT_64,
    U_INT_128,
    FLOAT,
    DOUBLE,
    BOOL,
    CHAR,
    STRING,
    VOID,
    UNKNOWN_TYPE
} type_t;

#endif