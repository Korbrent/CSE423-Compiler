/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: semanticAnalyzer.c
 * @brief: Implementations of the functions for semantic analysis
 * 
 * @version: 0.4.6
*/

#include "semanticAnalyzer.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int __yyerror(char *s, int yystate);
#define error(s) __yyerror(s, 3)

void build_symbol_tables (struct tree *t)
{
    /*
     * Oh my god this is a monsterous task. I spent HOURS in Cramer 233
     * drawing out a recursion tree for this function.
     * I have everything planned out and written on paper now. But it still needs
     * to be implemented.
     */
    if (scope_level() == -1) {
        // Create the global scope
        scope_enter();
    }
    for(int i = 0; i < t->nkids; i++) {
        // Scan through every child of the current node
        struct tree *kid = t->kids[i];
        if(kid != NULL) {
            switch(kid->production_rule) {
                case ITEM_FN_R:
                    // This subtree is a function declaration
                    function_declaration(kid);
                case ITEM_UNSAFE_FN_R:
                    error("Unsafe functions are not allowed in Irony");
                    break;
                
                default:
                    break;
            }
        }
    }
}

void function_declaration (struct tree *t)
{
    // Anything passed to this should be a subtree of ITEM_FN_R or ITEM_UNSAFE_FN_R
    char *fn_name = NULL;
    symbol_t fn_symbol = FUNCTION;
    declaration_t fn_decl = EXPLICIT;
    type_t fn_type = UNKNOWN;
    SymbolTableEntry fn = NULL;

    for (int i = 0; i < t->nkids; i++) {
        while (t->kids[i++] == NULL) {
            // Skip over any NULL nodes
        }
        switch (t->kids[i]->production_rule) {
            case FN:
                // Next node should be an identifier for the function name
                // do nothing
                break;

            case IDENTIFIER:
                // This is the function name
                fn_name = t->kids[i]->leaf->text;
                break;

            case FN_DECL_R:
                // This is the function declaration
                struct tree *fn_decl = t->kids[i];
                struct tree *fn_params = fn_decl->kids[0];
                // First and last element of fn_params should be LEFT_PAREN and RIGHT_PAREN
                
                struct tree *ret_ty = fn_decl->kids[1];
                // Get the return type of the function
                if (ret_ty == NULL) {
                    fn_type = VOID;
                } else {
                    // Get the type of the return type
                    for (int i = 0; i < ret_ty->nkids; i++) {
                        struct tree *kid = ret_ty->kids[i];
                        switch (kid->production_rule)
                        {
                        case ARROW:
                            // This is the arrow declaring return type. Skip over it
                            break;
                        case BANG:
                            // Used in Rust to declare that the function never returns. 
                            // This can be compared to void in C... Loosely ig
                            fn_type = VOID;
                            break;
                        case TY_R:
                            // This is either a complex type or an empty parenthesis
                            if (kid->nkids == 2) {
                                // This is an empty parenthesis
                                fn_type = VOID;
                            } else {
                                // This is a complex type
                                // TODO: Throw Not In Irony error code 3
                                error("Complex types are not allowed in Irony");
                            }
                        case TY_CLOSURE_R:
                            // This is a closure type
                            // TODO: Throw Not In Irony error code 3
                            error("Closures are not allowed in Irony");
                            break;
                        case IDENTIFIER:
                            // This is a simple type
                            fn_type = getTypeFromIdentifier(kid->leaf->text);
                            break;
                        default:
                            break;
                        }
                    }
                }

                break;
            case INNER_ATTRS_AND_BLOCK_R:
                // This is the function body
                fn = create_symbol(fn_symbol, fn_decl, fn_type, fn_name);
                if (fn_name == NULL) {
                    // TODO: Throw error code 3
                    error("Function name not found");
                }
                insert_symbol(fn);
                scope_enter();
                build_symbol_tables(t->kids[i]);
                scope_exit();
                break;
            default:
                break;
        }
    }
}

type_t getTypeFromIdentifier (char *ident)
{
    // Static types are considered identifiers by the parser
    // This function should return the type of the identifier
    // If the identifier is not found, it should return UNKNOWN

    // Default for ints is i32, floats is f64
    char *types[] = {"i8", "i16", "i32", "i64", "i128",
                      "u8", "u16", "u32", "u64", "u128",
                      "f32", "f64",
                      "bool", "char", "String"};
    int i = 0;
    while (strcmp(ident, types[i]) != 0 && i < sizeof(types)/sizeof(types[0]))
    {
        i++;
    }
    switch (i)
    {
    case 0:
        return INT_8;
    case 1:
        return INT_16;
    case 2:
        // This is the default type for integers
        // And default int size in Rust and C
        return INT_32;
    case 3:
        return INT_64;
    case 4:
        return INT_128;
    case 5:
        return U_INT_8;
    case 6:
        return U_INT_16;
    case 7:
        return U_INT_32;
    case 8:
        return U_INT_64;
    case 9:
        return U_INT_128;
    case 10:
        return FLOAT;
    case 11:
        // This is the default type for floats in Rust
        return DOUBLE;
    case 12:
        return BOOL;
    case 13:
        return CHAR;
    case 14:
        return STRING;
    default:
        // TODO: Throw Not In Irony error code 3
        return UNKNOWN;
    }
}