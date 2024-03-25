/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: semanticAnalyzer.c
 * @brief: Implementations of the functions for semantic analysis
 * 
 * @version: 0.4.6
*/

/** 
 * Okay, I know Homework 4 was over a week late, but I actually started this
 * during the symbol table building. I figured I would need it sooner.
 * And then for HW4, I wanted to implement type-checking as well, which I didnt
 * realize would be part of the next lab... And I also didnt realize HW5 was its own thing.
 * 
 * I kinda just started doing HW4, lab7 and HW5 all in one big ugly mess.
 * Long before we were ever provided a type struct in class.
 * 
 * I have worked so many hours on this and gotten so lost along the way.
 */

#include "semanticAnalyzer.h"
#include "tree.h"
#include "symtab.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int __yyerror(char *s, int yystate);
#define error(s) __yyerror(s, 3)


void function_declaration (struct tree *t);
type_t getTypeFromIdentifier (char *ident);
void recursiveParseParams(SymbolTableEntry *params, struct tree *t, int len);
SymbolTableEntry *parseParams(struct tree *t);
void recursive_pats_or(struct tree *t);
void recursive_match_clauses(struct tree *t);
void block_expr (struct tree *t);
type_t const_declaration (struct tree *t);
type_t let_declaration (struct tree *t);
void recursive_parse_token_trees(struct tree *t, int index, List params);
type_t expr_typechecker (struct tree *t);
type_t get_type_from_literal (struct tree *t);


void semantic_analyzer (struct tree *t){
    // This function should call the build_symbol_tables function
    printf("Semantic_Analyzer called.\n");
    build_symbol_tables(t);
}

void build_symbol_tables (struct tree *t)
{
    // This function should build the symbol tables for the given tree
    printf("Build_Symbol_tables called (scope %d).\t %s [%d] \n", scope_level(), t->symbolname, t->production_rule);

    if (scope_level() == -1) {
        printf("From within the if statement: %d \n", scope_level());
        if(!(t->production_rule == CRATE_R)){
            error("The root of the tree must be a crate type.");
        }
        // Create the global scope
        scope_enter();
    }

    for(int i = 0; i < t->nkids; i++) {
        // Scan through every child of the current node
        struct tree *kid = t->kids[i]; // for kid in kids
        if(kid == NULL)
            continue;

        switch(kid->production_rule) {
            case INNER_ATTR_R:
            case INNER_ATTRS_R:
                // We dont have these right now. Do nothing, just print to let the author know.
                printf("Inner attrs are not in the irony language. They will be simply ignored for now.");
                break;

            case MOD_ITEMS_R:
                // This subtree is a list of MOD_ITEMs
            case MOD_ITEM_R:
                // This subtree is a specific item in a module
                build_symbol_tables(kid);
                break;
            case ATTRS_AND_VIS_R:
                // This subtree is a list of attributes and visibility
                // We dont need to worry about this for irony. 
                // It is used in Rust to declare the visibility of a module
                // Maybe later we can go back and add support for this or throw an error
                break;
            
            // Stmt items
            case ITEM_MACRO_R:
                error("Item macros are not valid in Irony.");
                break;
            case ITEM_STATIC_R:
                // This subtree is a static variable declaration
                // According to the RustDocs its similar to a const, the only difference is statics point to a static memory.
                // I think thats similar enough to just treat it the same as a const.
                if (kid->nkids == 8) {
                    // This is a mutable static. Thats kinda dumb imo
                    error("Sorry, mutable statics aren't allowed. Why would you even want to do that?");
                }
                // Fall through
            case ITEM_CONST_R:
                // This subtree is a constant variable declaration
                // Formatted as STATIC/CONST, ident, ':', ty, '=', expr, ';'

                // This is a lot like a let declaration.
                const_declaration(kid);
                break;
            case ITEM_TYPE_R:
                // This subtree is a type declaration
                error("Type declarations are not supported in Irony.");
                break;
            case VIEW_ITEM_R:
                case EXTERN_FN_ITEM_R:  // These are also view items
                case USE_ITEM_R:        // These are also view items
                // This subtree is a view item or an external function declaration
                error("Views are not supported in Irony.");
                break;

            // Block items
            case ITEM_FN_R:
                // This subtree is a function declaration
                function_declaration(kid);
                break;
            case ITEM_UNSAFE_FN_R:
                error("Unsafe functions are not allowed in Irony");
                break;
            case ITEM_MOD_R:
            case ITEM_FOREIGN_MOD_R:
                // This subtree is a module declaration
                error("Modules are not allowed in Irony");
                break;
            case ITEM_STRUCT_R:
                error("Structs are not allowed in Irony");
                break;
            case ITEM_ENUM_R:
                error("Enums are not allowed in Irony");
                break;
            case ITEM_UNION_R:
                error("Unions are not allowed in Irony");
                break;
            case ITEM_TRAIT_R:
                error("Traits are not allowed in Irony");
                break;
            case ITEM_IMPL_R:
                error("Impls are not allowed in Irony");
                break;

            // Statements
            case MAYBE_STMTS_R:
                case STMTS_R:
                case STMT_R:
                // Recurse into this.
                build_symbol_tables(kid);
                break;
            case LET_R:
                // This subtree is a let declaration
                let_declaration(kid);
                break;

            case BLOCK_R:
                // First child is '{' and last is '}'
                // Middle is a list of statements
                // Recurse into this.
                scope_enter();
                build_symbol_tables(kid->kids[1]);
                scope_exit();
                break;

            // Expressions
            case BLOCK_EXPR_R:
                // This subtree is a block expression
                // if the first kid is UNSAFE then throw an error

                if(kid->kids[0]->production_rule == UNSAFE){
                    error("Unsafe blocks are not allowed in Irony");
                }
                // if the second kid a BANG then throw an error
                if(kid->kids[1]->production_rule == BANG){
                    error("Path expression blocks are not allowed in Irony");
                }
                // fall through
                case EXPR_MATCH_R:
                case EXPR_IF_R:
                case EXPR_WHILE_R:
                case EXPR_LOOP_R:
                case EXPR_FOR_R:
                case EXPR_IF_LET_R:
                case EXPR_WHILE_LET_R:
                block_expr(kid);
                break;

            case EXPR_R:
                case MACRO_EXPR_R:
                case EXPR_NOSTRUCT_R:
                case NONBLOCK_EXPR_R:
                // This subtree is an expression
                expr_typechecker(kid);
                break;

            case BLOCK_EXPR_DOT_R:
                // This subtree is a block expression with a dot
                error("Dot expressions are not allowed in Irony");
                break;


            case OUTER_ATTRS_R:
            case OUTER_ATTR_R:
                printf("Outer attrs are not in the irony language. They will be simply ignored for now.");
                break;

            case PATH_EXPR_R:
                case PATH_GENERIC_ARGS_WITH_COLONS_R:
                case SUPER:
                error("Path expressions are not in the irony language.");
                break;

            case PUB:
                // This is a public declaration
                error("Public declarations are not allowed in Irony");
                break;

            case SEMICOLON:
                // This is a semicolon
                break;

            case IDENTIFIER:
                // This is an identifier
                // Look it up and make sure it exists in the symbol table

                // Tbh this should never get called so I am gonna add a printline here to check if ever does.
                printf("build_symbol_tables - case IDENTIFIER\n");
                // type_t type = getTypeFromIdentifier(kid->leaf->text);
                // if(type != UNKNOWN_TYPE)
                //     break;
                // if (kid->leaf == NULL) 
                //     error("NULL leaf at identifier");
                // if (kid->leaf->text == NULL)
                //     error("NULL text at identifier");
                if (scope_lookup(kid->leaf->text) == NULL){
                    print_table();
                    error("Identifier not found in symbol table");
                }
                // Identifier was previously declared. Seems like we're good.
                break;
            default:
                break;
        }
    }   

    if(scope_level() == 0 && t->production_rule == CRATE_R){\
        printf("From within the if statement: %d \n", scope_level());
        // We are at the end of the global scope
        // if(!(t->production_rule == CRATE_R)){
        //     error("The root of the tree must be a crate type.");
        // }
        scope_exit();
        printf("Global scope exited.\n");
    }
    printf("Build_Symbol_tables done.\n");
}

void function_declaration (struct tree *t)
{
    printf("Function Declaration called.\t %s [%d] \n", t->symbolname, t->production_rule);
    // Anything passed to this should be a subtree of ITEM_FN_R or ITEM_UNSAFE_FN_R
    char *fn_name = NULL;
    symbol_t fn_symbol = FUNCTION;
    declaration_t fn_decl_t = EXPLICIT;
    type_t fn_type = UNKNOWN_TYPE;
    SymbolTableEntry fn = NULL;
    SymbolTableEntry *params = NULL;

    for (int i = 0; i < t->nkids; i++) {
        if (t->kids[i] == NULL) {
            // Skip over any NULL nodes
            continue;
        }
        switch (t->kids[i]->production_rule) {
            case FN:
                // Next node should be an identifier for the function name
                // do nothing
                break;

            case IDENTIFIER:
                // This is the function name
                fn_name = t->kids[i]->leaf->text;
                printf("Function name: %s\n", fn_name);
                break;

            case FN_DECL_R:
                // This is the function declaration
                printf("Function declaration\n");
                struct tree *fn_decl = t->kids[i];

                struct tree *fn_params = fn_decl->kids[0];
                // First and last element of fn_params should be LEFT_PAREN and RIGHT_PAREN
                // Middle param is either NULL, PARAM_R, or PARAMS_R
                if(fn_params == NULL)
                    error("Expected a parameter list");
                if (fn_params->nkids != 3)
                    error("Incorrect number of kids in parameter list");
                if (fn_params->kids[0]->production_rule != LEFT_PAREN)
                    error("Expected a left parenthesis");
                if (fn_params->kids[fn_params->nkids - 1]->production_rule != RIGHT_PAREN)
                    error("Expected a right parenthesis");

                // Now we can start parsing the parameters
                fn_params = fn_params->kids[1];
                printf("Function parameters\n");
                params = parseParams(fn_params);


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
                                error("Complex types are not allowed in Irony");
                            }
                            break;
                        case TY_CLOSURE_R:
                            // This is a closure type
                            error("Closures are not allowed in Irony");
                            break;
                        case TY_PRIM_R:
                            // This is a primitive type
                            // TODO: Fix this for array support
                            error("Primitive types are not allowed in Irony");
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
                printf("Function body\n");
                if (fn_name == NULL) {
                    error("Function name not found");
                }
                fn = create_symbol(fn_symbol, fn_decl_t, fn_type, fn_name);

                insert_symbol(fn);
                scope_enter(); //(Will be done for FUNCTION in create_symbol)
                // Add the parameters to the symbol table
                int j = 0;
                printf("Adding params\n");  
                if(params != NULL){
                    while(params[j] != NULL){
                        insert_symbol(params[j]);
                        j++;
                    }
                }
                printf("Params added\n");
                build_symbol_tables(t->kids[i]);
                printf("Function body done\n");
                fn->fn_table = scope_exit();
                break;
            default:
                break;
        }
    }
    printf("Function Declaration done.\n");
    fprintf(stderr, "Function %s type %d", fn_name, fn_type);
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
    fprintf(stderr,"Get type from identifier: %s\n", ident);
    if(ident == NULL){
        error("NULL IDENTIFIER\n");
        return UNKNOWN_TYPE;
    }
    printf("%d\n", (int)(sizeof(types)/sizeof(types[0])));
    while (i < (int)(sizeof(types)/sizeof(types[0])))
    {
        if(strcmp(ident, types[i]) == 0)
            break;
        i++;
    }
    printf("b\n");
    switch (i)
    {
    case 0:
        error("i8 is not allowed in Irony");
        break;
    case 1:
        error("i16 is not allowed in Irony");
        break;
    case 2:
        // This is the default type for integers
        // And default int size in Rust and C
        // But for the sake of compatibility, lets just return INT_64
        return INT_64;
    case 3:
        return INT_64;
    case 4:
        error("i128 is not allowed in Irony");
        break;
    case 5:
        error("u8 is not allowed in Irony");
        break;
    case 6:
        error("u16 is not allowed in Irony");
        break;
    case 7:
        return U_INT_64;
    case 8:
        return U_INT_64;
    case 9:
        error("u128 is not allowed in Irony");
        break;
    case 10:
        // Convert floats to doubles
        return DOUBLE;
    case 11:
        // This is the default type for floats in Rust
        return DOUBLE;
    case 12:
        return BOOL;
    case 13:
        return CHAR;
    case 14:
        return STRING;
    }
    return UNKNOWN_TYPE;
}

void recursiveParseParams(SymbolTableEntry *params, struct tree *t, int len)
{
    // This function should parse the parameter list and return an array of SymbolTableEntry
    // The array should be NULL terminated
    switch (t->production_rule)
    {
    case PARAMS_R:
        // This is a list of parametersset size of malloc array in c
        for (int i = 0; i < t->nkids; i++) {
            struct tree *kid = t->kids[i];
            if (kid != NULL) {
                switch (kid->production_rule)
                {
                case COMMA:     // This is a comma separating parameters
                    break;
                case PARAM_R:   // This is a single parameter
                case PARAMS_R:  // This is a list of parameters
                    recursiveParseParams(params, kid, len);
                    break;
                default:
                    error("Unexpected production rule in parameter list");
                    break;
                }
            }
        }
        break;
    case PARAM_R: //BASE CASE
        // This is a single parameter
        // The first kid is the ident, second is COLON, third is the type
        struct tree *param_ident = t->kids[0];
        struct tree *param_type = t->kids[2];

        if(param_ident == NULL || param_type == NULL)
            error("NULL argument in parameter list where argument is expected");

        if(!(param_ident->production_rule == IDENTIFIER))
            error("Expected an identifier in parameter list");
        if(!(param_type->production_rule == IDENTIFIER))
            error("Expected a type in parameter list");

        if(param_ident->leaf == NULL || param_type->leaf == NULL)
            error("NULL argument in parameter list where argument is expected");
        
        char *param_name = param_ident->leaf->text;
        type_t param_t = getTypeFromIdentifier(param_type->leaf->text);
        if (param_t == UNKNOWN_TYPE)
        {
            error("Unknown type in parameter list");
        }
        

        SymbolTableEntry param = create_symbol(PARAM, EXPLICIT, param_t, param_name);
        for (int i = 0; i < len; i++) {
            if (params[i] == NULL) {
                params[i] = param;
                break;
            }
        }
        break;
    default:
        error("Unexpected production rule in parameter list");
        break;
    }
}

SymbolTableEntry *parseParams(struct tree *t)
{
    if(t == NULL)
        return NULL;
    printf("ParseParams called.\t %s [%d] \n", t->symbolname, t->production_rule);
    // This function should parse the parameter list and return an array of SymbolTableEntry
    // The array should be NULL terminated
    int param_count = 0;
    struct tree *temp = t;
    while(temp->production_rule == PARAMS_R){
        temp = temp->kids[0];
        param_count++;
    }
    param_count++;
    SymbolTableEntry *params = malloc(sizeof(SymbolTableEntry) * param_count + 1);
    for (int i = 0; i < param_count; i++) {
        params[i] = NULL;
    }
    recursiveParseParams(params, t, param_count);
    return params;
}

void recursive_pats_or(struct tree *t)
{
    // pats_or '|' pats
    for(int i = 0; i < t->nkids; i++){
        struct tree *kid = t->kids[i];
        if(kid == NULL)
            continue;
        switch (kid->production_rule)
        {
        case PATS_OR_R:
            // This is a list of pats_or
            recursive_pats_or(kid);
            break;
        case PAT_R:
            // This is a single pat
            // TODO: Fix this if we want arrays
            error("Pattern matching is not implemented in Irony");
            break;
        case PIPE:
            // This is a pipe separating pats_or
            break;
        case UNDERSCORE:
            // This is a wildcard pattern
            break;
        case IDENTIFIER:
            if (getTypeFromIdentifier(kid->leaf->text) != UNKNOWN_TYPE)
                break;
            if (scope_lookup(kid->leaf->text) == NULL)
                error("Identifier not found in symbol table");
            break;
        }
    }
}

void recursive_match_clauses(struct tree *t){
    // This function should parse the match clauses and add the symbols to the symbol table
    // Types of match clauses are MATCH_CLAUSE, MATCH_CLAUSES, NONBLOCK_MATCH_CLAUSE
    switch (t->production_rule)
    {
    case MATCH_CLAUSE_R:
        // This is a single match clause
        // The first kid is either a block_match_clause or a nonblock_match_clause, the second is a COMMA
        recursive_match_clauses(t->kids[0]);
        break;
    case MATCH_CLAUSES_R:
        // This is a right leaning tree of match clauses
        // the first is match_clauses, the second is match_clause
        recursive_match_clauses(t->kids[0]);
        recursive_match_clauses(t->kids[1]);
        break;

    case BLOCK_MATCH_CLAUSE_R:
    case NONBLOCK_MATCH_CLAUSE_R:
        // This is a single match clause
        // Order goes maybe_outer_attrs pats_or maybe_guard => [block_expr_dot or nonblock_expr]
        // The first kid is either a block_match_clause or a nonblock_match_clause, the second is a COMMA
        if (t->kids[0] != NULL)
            printf("Outer attrs are not in the irony language. They will be simply ignored for now.");
        struct tree *pats_or = t->kids[1];
        if (pats_or == NULL)
            error("Expected a pattern in match clause");
        recursive_pats_or(pats_or);

        struct tree *maybe_guard = t->kids[2];
        if (maybe_guard != NULL)
            build_symbol_tables(maybe_guard);
        
        struct tree *block = t->kids[3];
        if (block == NULL)
            break;
        if (block->production_rule == BLOCK_EXPR_DOT_R) {
            error("Dot expressions are not allowed in Irony");
        } else if (block->production_rule == BLOCK_EXPR_R) {
            error("Block expressions are not allowed in Irony");
        } else if (block->production_rule == BLOCK_R) {
            // Middle is a list of statements
            scope_enter();
            if(block->kids[1] != NULL)
                build_symbol_tables(block->kids[1]);
            scope_exit();
        }
        else
            build_symbol_tables(block);
        break;
    default:
        build_symbol_tables(t);
        break;
    }
}

void block_expr (struct tree *t)
{
    // This function should parse the block expression and add the symbols to the symbol table
    // Types of block expr are MATCH, IF, IF_LET, WHILE, WHILE_LET, LOOP, FOR

    switch (t->production_rule)
    {
    case BLOCK_EXPR_R:
        error("BLOCK_EXPR_R rules should not be in irony.");
        break;
    case EXPR_MATCH_R:
        // This is like a switch statement. I dont wanna cut off support for these yet.
        // switch statements are useful (as we can see from this file lol)

        // MATCH expr_nostruct '{' match_arm* '}'

        // If it has 4 kids, we dont need to deal with it. 
        // The first 3 kids are MATCH, expr_nostruct, '{', and the last is '}'
        // -2 because index starts at 0 and we want to ignore the last kid

        // Sorry for excessive comments, these are more for myself than they are for the reader.
        // I'm just trying to keep track of where I am in the tree.

        // For type checking, we will need to ensure that the expr_nostruct is of the same type as the match arms

        // Shoot, I see the difficulty of this. I guess it would be better use of my time to cut my losses and give up on this
        error("Match expressions are not implemented in Irony");
        break;

    case EXPR_IF_R:
        // IF expr_nostruct block
        // IF expr_nostruct block ELSE block_or_if

        type_t if_type = expr_typechecker(t->kids[1]);
        fprintf(stderr, "If kid: %s\n", t->kids[1]->symbolname);
        fprintf(stderr, "If type: %d\n", if_type);
        if(if_type != BOOL)
            error("Expected a boolean expression in if statement");
        scope_enter();
        build_symbol_tables(t->kids[2]);
        scope_exit();
        if (t->nkids == 5) {
            if (t->kids[4] != NULL 
                    && !(t->kids[4]->production_rule == EXPR_IF_R || t->kids[4]->production_rule == EXPR_IF_LET_R)){
                scope_enter();
                build_symbol_tables(t->kids[4]);
                scope_exit();
            } else {
                block_expr(t->kids[4]);
            }
        }
        break;

    case EXPR_IF_LET_R:
        // IF LET pat '=' expr_nostruct block
        // IF LET pat '=' expr_nostruct block ELSE block_or_if

        error("If let statements are not implemented in Irony. They just dont seem practical, sorry.");
        // // build a tree just of the LET section
        // struct tree *if_let_stmt = treealloc(LET_R, 
        //                             "if_let",
        //                             5,
        //                             t->kids[1],
        //                             t->kids[2],
        //                             t->kids[3],
        //                             t->kids[4],
        //                             NULL );

        // // parse the let statement and add to symtab
        // type_t if_let_type = let_declaration(if_let_stmt);
        // free(if_let_stmt); // Dont free sub-tokens. Just the tree itself.

        // scope_enter();
        // build_symbol_tables(t->kids[5]);
        // scope_exit();

        // if (t->nkids == 8) {
        //     if (t->kids[7] != NULL 
        //             && !(t->kids[7]->production_rule == EXPR_IF_R || t->kids[7]->production_rule == EXPR_IF_LET_R)){
        //         scope_enter();
        //         build_symbol_tables(t->kids[7]);
        //         scope_exit();
        //     } else {
        //         block_expr(t->kids[7]);
        //     }
        // }
        break;

    case EXPR_WHILE_R:
        // maybe_label WHILE expr_nostruct block
        if (t->kids[0] != NULL) {
            error("Labeled loops are not supported by Irony");
        }
        type_t while_type = expr_typechecker(t->kids[2]);
        if(while_type != BOOL)
            error("Expected a boolean expression in while statement");
        scope_enter();
        build_symbol_tables(t->kids[3]);
        scope_exit();
        break;

    case EXPR_WHILE_LET_R:
        // maybe_label WHILE LET pat '=' expr_nostruct block
        if (t->kids[0] != NULL) {
            error("Labeled loops are not supported by Irony");
        }
        // build a tree just of the LET section
        struct tree *while_let_stmt = treealloc(LET_R, 
                                    "while_let",
                                    5,
                                    t->kids[2],
                                    t->kids[3],
                                    t->kids[4],
                                    t->kids[5],
                                    NULL );
        type_t while_let_type = let_declaration(while_let_stmt);
        free(while_let_stmt); // Dont free sub-tokens. Just the tree itself.
        if (while_let_type != BOOL)
            error("Expected a boolean expression in while statement");
        scope_enter();
        build_symbol_tables(t->kids[6]);
        scope_exit();
        break;

    case EXPR_LOOP_R:
        error("Loop statements are not implemented in Irony, use a While statement instead.");
        break;
    case EXPR_FOR_R:
        // maybe_label FOR pat IN expr_nostruct block
        if (t->kids[0] != NULL)
            error("Labeled For-loops are not supported by Irony");

        char *for_name = NULL;
        if (t->kids[2] != NULL && t->kids[2]->production_rule != IDENTIFIER)
            error("Expected an identifier in for loop");
        for_name = t->kids[2]->leaf->text;

        type_t for_type = expr_typechecker(t->kids[4]);
        if(for_type != UNKNOWN_TYPE)
            error("Expected an iterator in for loop");
        scope_enter();
        insert_symbol(create_symbol(LOCAL, IMPLICIT, for_type, for_name));
        build_symbol_tables(t->kids[5]);
        scope_exit();

    default:
        break;
    }    

}

type_t const_declaration (struct tree *t)
{
    // STATIC/CONST ident ':' ty '=' expr ';'
    char *const_name = NULL;
    symbol_t const_symbol = GLOBAL;

    declaration_t const_decl = EXPLICIT;
    type_t const_type = UNKNOWN_TYPE;
    SymbolTableEntry const_sym = NULL;

    if(t->kids[1] == NULL)
        error("Expected an identifier in const declaration");
    const_name = t->kids[1]->leaf->text;

    struct tree *ty_tree = t->kids[3];
    switch (ty_tree->production_rule){
        case TY_R:
            // This is a complex type
            if (ty_tree->kids[0] != NULL && ty_tree->kids[0]->production_rule == LEFT_PAREN){
                error("Tuples are not allowed in Irony");
            }
            error("Complex types are not allowed in Irony");
            break;
        case TY_CLOSURE_R:
            // This is a closure type
            error("Closures are not allowed in Irony");
            break;
        case TY_PRIM_R:
            // This is a primitive type
            // TODO: Fix this for array compatibility
            error("Primitive types are not allowed in Irony");
            break;
        case IDENTIFIER:
            // This is a simple type
            const_type = getTypeFromIdentifier(ty_tree->leaf->text);
            break;
    }
    type_t expr_type = expr_typechecker(t->kids[5]);
    if (expr_type != const_type) {
        if(expr_type == DOUBLE && const_type == INT_64)
            error("Declared as an integer, but the expression is a float");
        else if (!(expr_type == INT_64 && const_type == DOUBLE))
            error("Type mismatch in const declaration");
    }
    const_sym = create_symbol(const_symbol, const_decl, const_type, const_name);
    insert_global_symbol(const_sym);
    return const_type;
}

type_t let_declaration (struct tree *t)
{
    printf("Let Declaration called.\t %s [%d] \n", t->symbolname, t->production_rule);
    // This function should parse the let declaration and add the symbols to the symbol table
    char *var_name = NULL;
    symbol_t var_symbol = getCurrentSymbolType();

    
    declaration_t var_decl = IMPLICIT;
    type_t var_type = UNKNOWN_TYPE;
    SymbolTableEntry var = NULL;
    int is_mutable = 0;

    // LET_R is formulated: LET pat maybe_ty_acription maybe_init_expr ';'
    if (t->production_rule != LET_R)
        error("Expected a let declaration");
    
    if (t->nkids != 5)
        error("Incorrect number of kids in let declaration");
    if (t->kids[0]->production_rule != LET)
        error("Expected a let keyword");

    struct tree *pat = t->kids[1];
    if(pat == NULL)
        error("Expected a pattern in let declaration");
    switch (pat->production_rule)
    {
        case UNDERSCORE:
            // This is a wildcard pattern
            break;
        case IDENTIFIER: /* reached from PAT_R->PATH_GENERIC_ARGS_WITH_COLONS->ident */
            // This is an identifier pattern, should be the variable name.
            var_name = pat->leaf->text;
            break;

        case LIT_OR_PATH_R:
            case PATH_EXPR_R:
            case PATH_GENERIC_ARGS_WITH_COLONS_R:
            
            error("Path expressions are not in the irony language.");
            break;
            
            case LIT_BYTE:
            case CHAR_LITERAL:
            case INTEGER_LITERAL:
            case FLOAT_LITERAL:
            case TRUE:
            case FALSE:
            case STRING_LITERAL:
            case STRING_LITERAL_RAW:
            case LIT_BYTE_STR:
            case LIT_BYTE_STR_RAW:
            // These are literals
            
            error("Kinda confused on let declaration with literals as match pattern. This is not in the irony language unless told otherwise.");
            break;
        case PAT_R:
            // This is a complex pattern
            struct tree *first_kid = pat->kids[0];
            switch (first_kid->production_rule)
            {
                case AMPERSAND:
                    // This is a reference pattern
                    error("Reference patterns are not allowed in Irony");
                    break;
                case DOUBLE_AMPERSAND:
                    error("Double ampersand let statements are not allowed in Irony");
                    break;

                case LIT_OR_PATH_R:
                    case PATH_EXPR_R:
                    case PATH_GENERIC_ARGS_WITH_COLONS_R:
                    
                    error("Path expressions are not in the irony language.");
                    break;
                    
                    case LIT_BYTE:
                    case CHAR_LITERAL:
                    case INTEGER_LITERAL:
                    case FLOAT_LITERAL:
                    case TRUE:
                    case FALSE:
                    case STRING_LITERAL:
                    case STRING_LITERAL_RAW:
                    case LIT_BYTE_STR:
                    case LIT_BYTE_STR_RAW:
                    // These are literals
                    
                    error("Kinda confused on let declaration with literals as match pattern. This is not in the irony language unless told otherwise.");
                    break;
                
                case BINDING_MODE_R:
                    // This is a binding mode pattern
                    case REF:
                    error("Reference patterns are not allowed in Irony");
                    break;
                case MUT:
                    is_mutable = 1;
                    // check by number of kids
                    if(pat->nkids == 2){
                        // MUT ident
                        var_name = pat->kids[1]->leaf->text;
                    } else {
                        // MUT ident AT pat
                        error("AT patterns are not allowed in Irony");
                    }
                    break;
                case IDENTIFIER:
                    // This is ident AT pat
                    error("AT patterns are not allowed in Irony");
                    break;
                case BOX:
                    error("Boxes are not allowed in Irony");
                    break;
                case LESS_THAN:
                case DOUBLE_LESS_THAN:
                    // using let <> = ... or let <<>> = ...
                    error("Generic patterns are not allowed in Irony");
                    break;
                
                case LEFT_PAREN:
                case LEFT_BRACKET:
                    // This something idk because tuple and array patterns are handled later in the MAYBE_TY_ASCRIPTION_R
                    error("Tuple and array patterns are not allowed in Irony");
                default:
                    break;
            }
            break;
        default:
            break;
    }

    printf("Variable name: %s\n", var_name);
    struct tree *ty_tree = t->kids[2];
    if(ty_tree != NULL){
        var_decl = EXPLICIT;
        // This is a type ascription
        // format is ':' ty_sum
        switch (ty_tree->kids[1]->production_rule)
        {
            // ty or lifetime
            case TY_SUM_R:
                // This is a type sum
                error("Type sums are not allowed in Irony");
                break;
            case TY_R:
                if (ty_tree->kids[1]->nkids == 2) {
                    // This is an empty parenthesis
                    var_type = VOID;
                } else {
                    // This is a complex type
                    error("Complex types are not allowed in Irony");
                }
                break;
            case TY_CLOSURE_R:
                // This is a closure type
                error("Closures are not allowed in Irony");
                break;
            case PATH_GENERIC_ARGS_WITHOUT_COLONS_R:
                // This is a path generic args without colons
                error("Paths are not allowed in Irony");
                break;
            case TY_PRIM_R:
                // This is a primitive type
                // TODO: this
                error("Primitive types are not allowed in Irony");
                break;
            case UNDERSCORE:
                // This is a wildcard type
                var_type = UNKNOWN_TYPE;
                break;
            case TY_BARE_FN_R:
                // This is a bare function type
                error("Bare function types are not allowed in Irony... And I cant even find much documentation about them in general. Does anyone even use these? I guess you do if you triggered this error.");
                break;
            case FOR_IN_TYPE_R:
                // This is a for in type
                error("For in types are not allowed in Irony");
                break;
            case IDENTIFIER:
                // This is a simple type
                var_type = getTypeFromIdentifier(ty_tree->kids[1]->leaf->text);
                break;
            default:
                break;
        }
    }

    printf("Variable type: %d\n", var_type);
    struct tree *init_expr = t->kids[3];
    if (init_expr != NULL) {
        printf("Init expr: %s\n", init_expr->symbolname);
        // This is an initialization expression
        // format is '=' expr
        printf("a\n");
        struct tree *expr = init_expr->kids[1];
        if (expr == NULL)
            error("Expected an expression in let declaration");
        printf("b\n");
        // If it has 3 kids and uses the keyword AS, it is a cast expression, which is not allowed in Irony
        if(expr->nkids == 3 && (expr->kids[1] != NULL && expr->kids[1]->production_rule == AS)){
            error("Cast expressions are not allowed in Irony");
        }
        printf("c\n");
        // If the first child is BOX, it is a box expression, which is not allowed in Irony
        if(expr->kids[0] != NULL && expr->kids[0]->production_rule == BOX){
            error("Box expressions are not allowed in Irony");
        }
        printf("d\n");
        // Recurse into this.
        printf("Building symbol tables for init_expr\n");
        build_symbol_tables(expr);
    }
    printf("e\n");
    if(var_name == NULL)
        error("Variable name not found");
    var = create_symbol(var_symbol, var_decl, var_type, var_name);
    var->is_mutable = is_mutable;
    insert_symbol(var);
    return var_type;
}

void recursive_parse_token_trees(struct tree *t, int index, List params){
    SymbolTableEntry param;
    switch (t->production_rule)
    {
        case TOKEN_TREES_R:
            int i = 0;
            if (t->kids[0] != NULL) {
                recursive_parse_token_trees(t->kids[0], index + i, params);
                i++;
            }
            recursive_parse_token_trees(t->kids[1], index + i, params);
            break;
        case TOKEN_TREE_R: // Ghost case
            case DELIMITED_TOKEN_TREES_R: // Ghost case
                case PARENS_DELIMITED_TOKEN_TREES_R:
                case BRACES_DELIMITED_TOKEN_TREES_R:
                case BRACKETS_DELIMITED_TOKEN_TREES_R:

            error("Delimited token trees are not allowed in Irony");
            break;
        case IDENTIFIER:
            if (getTypeFromIdentifier(t->leaf->text) != UNKNOWN_TYPE) // This is a static type
                break;
            SymbolTableEntry id = scope_lookup(t->leaf->text);
            if (id == NULL)
                error("Identifier not found in symbol table");
            param = ll_get(params, index);
            if(param == NULL)
                error("Parameter not found in list");
            if(param->type_t != id->type_t)
                // If one type is float and the other is int, it can pass
                if (param->type_t == INT_64 && id->type_t == DOUBLE)
                    break;
                if (param->type_t == DOUBLE && id->type_t == INT_64)
                    break;
                error("Type does not match expected parameter type");
            break;

        case LIT_BYTE:
        case CHAR_LITERAL:
        case INTEGER_LITERAL:
        case FLOAT_LITERAL:
        case TRUE:
        case FALSE:
        case STRING_LITERAL:
        case STRING_LITERAL_RAW:
        case LIT_BYTE_STR:
        case LIT_BYTE_STR_RAW:
            // These are literals
            type_t type = get_type_from_literal(t);
            param = ll_get(params, index);
            if(param == NULL)
                error("Parameter not found in list");
            if(param->type_t != type)
                error("Type does not match expected parameter type");
            break;
    }
}

type_t expr_typechecker(struct tree *t)
{
    // TODO: This could use optimizing
    // This rule should only be called on expr or nonblock_expr
    type_t return_type = UNKNOWN_TYPE;
    switch (t->production_rule)
    {
    case EXPR_NOSTRUCT_R:
    case EXPR_R:
    case NONBLOCK_EXPR_R:
        // This is an expression
        if (t->kids[0]->production_rule == NONBLOCK_PREFIX_EXPR_NOSTRUCT_R || t->kids[0]->production_rule == NONBLOCK_PREFIX_EXPR_R){
            // if length is 1 it is a lamda expression. Not allowed in Irony
            if(t->nkids == 1 || t->kids[0]->production_rule == MOVE){
                error("Lambda expressions are not allowed in Irony");
            }

            if (t->kids[0] != NULL)
                switch (t->kids[0]->production_rule)
                {
                case YIELD:
                    error("Yield expressions are not allowed in Irony");
                    break;
                case SELF:
                    error("Self expressions are not allowed in Irony");
                    break;
                case SUPER:
                    error("Super expressions are not allowed in Irony");
                    break;
                default:
                    break;
                }

            if(t->nkids == 2){
                return_type = expr_typechecker(t->kids[1]);
            }
            // Last two possibilities start with '&' and '&&'
            if(t->kids[0]->production_rule == AMPERSAND || t->kids[0]->production_rule == DOUBLE_AMPERSAND){
                // This is a reference expression
                error("Reference expressions are not allowed in Irony");
            }
            break;
        }

        if (t->nkids == 2){
            if (t->kids[0] != NULL && t->kids[0]->production_rule == BOX){
                // This is a box expression
                error("Box expressions are not allowed in Irony");
            }
            // Eh this doesnt need to be type checked I dont think
            return_type = UNKNOWN_TYPE;
            break;
        }

        if (t->nkids == 3) {
            if (t->kids[0] != NULL && t->kids[0]->production_rule == LEFT_PAREN) {
                // Parenthesis wrapped expression. 
                return_type = expr_typechecker(t->kids[1]);
            }
            if (t->kids[0] != NULL && t->kids[0]->production_rule == LEFT_BRACKET) {
                // This is an array expression
                // TODO: Add support for arrays
                error("Array expressions are not allowed in Irony... For now. I will add them soon I hope. I am kinda rushing to get this project done rn");
            }
            type_t left;
            type_t right;
            switch (t->kids[1]->production_rule){
                case DOT:
                    fprintf(stderr, "Dot expression: %s\n", t->kids[0]->symbolname);
                    error("Dot expressions are not allowed in Irony");
                    break;
                case DOUBLE_PIPE:
                case DOUBLE_AMPERSAND:
                case DOUBLE_EQUAL:
                case NOT_EQUAL:
                case LESS_THAN:
                case GREATER_THAN:
                case LESS_THAN_EQUAL:
                case GREATER_THAN_EQUAL:
                    left = expr_typechecker(t->kids[0]);
                    right = expr_typechecker(t->kids[2]);
                    return_type = BOOL;
                    //TODO: Ensure left and right can be booled together
                    break;
                case EQUAL:
                case DOUBLE_LESS_THAN_EQUAL:
                case DOUBLE_GREATER_THAN_EQUAL:
                case MINUS_EQUAL:
                case AMPERSAND_EQUAL:
                case PIPE_EQUAL:
                case PLUS_EQUAL:
                case STAR_EQUAL:
                case SLASH_EQUAL:
                case CARET_EQUAL:
                case PERCENT_EQUAL:
                case PIPE:
                case CARET:
                case AMPERSAND:
                case DOUBLE_LESS_THAN:
                case DOUBLE_GREATER_THAN:
                case PLUS:
                case MINUS:
                case STAR:
                case SLASH:
                case PERCENT:
                    // This is a good boi expression
                    left = expr_typechecker(t->kids[0]);
                    right = expr_typechecker(t->kids[2]);
                    if (left == UNKNOWN_TYPE && right == UNKNOWN_TYPE)
                        return_type = UNKNOWN_TYPE;
                    if (left == UNKNOWN_TYPE)
                        return_type = right;
                    if (right == UNKNOWN_TYPE)
                        return_type = left;
                    if (left != right) {
                        // If one type is float and the other is int, it can pass
                        if (left == INT_64 && right == DOUBLE)
                            return_type = right;
                        if (left == DOUBLE && right == INT_64)
                            return_type = left;
                        error("Type mismatch in expression");
                    }
                    return_type = left;
                    break;
                case AS:
                    // This is a cast expression
                    error("Cast expressions are not allowed in Irony");
                    break;
                case COLON:
                    // This is a type ascription
                    error("Type ascriptions are not allowed in Irony");
                    break;
                case DOUBLE_DOT:
                    // This is a range expression
                    error("Range expressions are not allowed in Irony");
                    break;
                default:
                    break;
            }
        }

        if (t->nkids == 4){
            // TODO: this
            if (t->kids[1] != NULL)
            switch (t->kids[1]->production_rule){
                case LEFT_PAREN:
                    // This is a function
                    // First kid is function name.
                    // 3rd is the maybe_exprs.
                    if(t->kids[0] == NULL || t->kids[0]->leaf == NULL)
                        error("Expected a function name in function call");
                    SymbolTableEntry search = scope_lookup(t->kids[0]->leaf->text);
                    if (search == NULL)
                        error("Function not found in symbol table");
                    if (search->symbol_t != FUNCTION)
                        error("Expected a function in function call");
                    return_type = search->type_t;
                    break;

                case DEFAULT:
                    error("This is a 4 kid expression. I dont know what to do with this");
                    error("No.");
            }
            
        }

        // Otherwise its a 1-kid expression
        switch (t->kids[0]->production_rule)
        {
        case LIT_BYTE:
        case CHAR_LITERAL:
        case INTEGER_LITERAL:
        case FLOAT_LITERAL:
        case TRUE:
        case FALSE:
        case STRING_LITERAL:
        case STRING_LITERAL_RAW:
        case LIT_BYTE_STR:
        case LIT_BYTE_STR_RAW:
            return get_type_from_literal(t->kids[0]);
            break;
        case PATH_EXPR_R:
            case PATH_GENERIC_ARGS_WITH_COLONS_R:
            error("Path expressions are not allowed in Irony");
            break;
        case MACRO_EXPR_R:
            return expr_typechecker(t->kids[0]);
        case EXPR_QUALIFIED_PATH_R:
            error("Qualified path expressions are not allowed in Irony");
            break;
        
        case BLOCK_EXPR_R:
            if (t->kids[0]->production_rule == UNSAFE){
                error("Unsafe blocks are not allowed in Irony");
            }
            if (t->kids[1]->production_rule == BANG){
                error("Path expression blocks are not allowed in Irony");
            }
            // fall through
        case EXPR_MATCH_R:
        case EXPR_IF_R:
        case EXPR_WHILE_R:
        case EXPR_LOOP_R:
        case EXPR_FOR_R:
            // This is a block expression
            block_expr(t->kids[0]);
            // TODO: Get return type
            break;
        
        case BLOCK_R:
            // This is a list of statements
            scope_enter();
            if(t->kids[1] != NULL)
                build_symbol_tables(t->kids[1]);
            scope_exit();
            // TODO: Get return type
            break;
        default:
            break;
        }

        break;

    case MACRO_EXPR_R:
        // This is a macro expression
        // First item is either an ident or a path
        // Second item is a '!'
        // And third is list of tokens
        SymbolTableEntry search;
        if(t->kids[0]->production_rule == IDENTIFIER){
            // This is an identifier
            // Look it up and make sure it exists in the symbol table
            search = scope_lookup(t->kids[0]->leaf->text);
            if (search == NULL)
                error("Macro expression identifier not found in symbol table.");
        } else if(t->kids[0]->production_rule == PATH_EXPR_R){
            // This is a path expression
            error("Path expressions are not allowed in Irony");
        } else {
            error("Unexpected production rule in macro expression");
        }
        if (t->kids[2] != NULL) {
            // This is a maybe_ident. Idk what to do with this
            error("Ident after a '!' in a macro expression is not allowed in Irony");
        }
        if (t->kids[3] == NULL) {
            // This is a list of tokens
            error("Expected a list of tokens in macro expression");
        }
        switch (t->kids[3]->production_rule)
        {
        case BRACKETS_DELIMITED_TOKEN_TREES_R:
            error("Macro expressions with bracket surrounded token trees are not allowed in Irony");
            break;
        case PARENS_DELIMITED_TOKEN_TREES_R:
            // Expected case. Handled outside the brackets
            break;
        default:
            break;
        }

        struct tree *tokens = t->kids[3];
        tokens = tokens->kids[1];
        if (tokens != NULL){
            SymbolTable fn_table = search->fn_table;
            if(fn_table == NULL)
                error("Function table not found in symbol table entry");

            // Check the params
            List params = fn_table->params;
            if(params == NULL)
                error("Params list not found in function table");
            struct tree *tmp = tokens;
            recursive_parse_token_trees(tmp, 0, params);
        }
        // If we get here, we're good
        return_type = search->type_t;
        break;

    default:
        break;
    }

    return return_type;
    // This function should return the type of the expression
    // If the expression is not valid, it should return UNKNOWN_TYPE
    // We expect everything to be sent to this to have come from expr or nonblock_expr
}

type_t get_type_from_literal(struct tree *t){
    if (t == NULL)
        error("NULL tree in get_type_from_literal");
    
    switch (t->production_rule) {
        case LIT_BYTE:
            return CHAR;
        case CHAR_LITERAL:
            return CHAR;
        case INTEGER_LITERAL:
            return INT_64;
        case FLOAT_LITERAL:
            return DOUBLE;
        case TRUE:
            return BOOL;
        case FALSE:
            return BOOL;
        case STRING_LITERAL:
            return STRING;
        case STRING_LITERAL_RAW:
            return STRING;
        case LIT_BYTE_STR:
            return STRING;
        case LIT_BYTE_STR_RAW:
            return STRING;
        default:
            error("Unexpected production rule in get_type_from_literal");
            return UNKNOWN_TYPE;
    }
}