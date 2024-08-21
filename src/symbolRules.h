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
    INT_8,          // not implemented
    INT_16,         // not implemented
    INT_32,         // converted to INT_64
    INT_64,
    INT_128,        // not implemented
    U_INT_8,        // not implemented
    U_INT_16,       // not implemented
    U_INT_32,       // converted to U_INT_64
    U_INT_64,
    U_INT_128,      // not implemented
    FLOAT,          // converted to DOUBLE
    DOUBLE,
    BOOL,
    CHAR,
    STRING,
    VOID,
    UNKNOWN_TYPE,
    ARRAY,
} type_t;

#endif