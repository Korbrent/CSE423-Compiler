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

void __yyerror(char *s, int errorCode, int lineno, int returnType);
#define error(s, l) __yyerror(s, 3, l, 3)

type_t g_ret_val = -1; // Used for fn type checking. I tried finding better ways to deal with this but here we are...

int search_for_line_number(struct tree *t);
type_t function_declaration (struct tree *t);
type_t getTypeFromIdentifier (char *ident, int l);
void recursiveParseParams(SymbolTableEntry *params, struct tree *t, int len);
SymbolTableEntry *parseParams(struct tree *t);
void recursive_pats_or(struct tree *t);
type_t block_expr (struct tree *t);
type_t const_declaration (struct tree *t);
type_t let_declaration (struct tree *t);
void recursive_parse_token_trees(struct tree *t, int index, List params);
type_t expr_typechecker (struct tree *t);
type_t get_type_from_literal (struct tree *t);
int array_sizechecker (struct tree *t);
type_t array_typechecker (struct tree *t);

/**
 * Find the line number of the first leaf in the tree.
 * Used for error messages.
 * @param t The tree to search
 * @return The line number of the first leaf in the tree
 */
int search_for_line_number(struct tree *t){
    if (t == NULL)
        return -1;

    if (t->leaf != NULL)
        return t->leaf->lineno;

    for (int i = 0; i < t->nkids; i++){
        if (t->kids[i] == NULL)
            continue;
        int r = search_for_line_number(t->kids[i]);
        if (r != -1)
            return r;
    }
    return -1;
}

/**
 * Build the default functions for the symbol table
 * This includes println() and read()
 */
void build_default_functions () {
    symbol_t sym = FUNCTION;
    declaration_t decl = EXPLICIT;
    // Format: println(param: String) -> Void
    type_t type = VOID;
    SymbolTableEntry println = create_symbol(sym, decl, type, "println");
    insert_symbol(println);
    scope_enter();
    SymbolTableEntry param = create_symbol(PARAM, EXPLICIT, STRING, "param");
    insert_symbol(param);
    println->fn_table = scope_exit();

    // Format: read(void) -> String
    type = STRING;
    SymbolTableEntry readln = create_symbol(sym, decl, type, "read");
    insert_symbol(readln);
    scope_enter();
    readln->fn_table = scope_exit();
}

/**
 * Build the symbol tables for the given tree
 * @param t The tree to build the symbol tables for
 * @return The type of the last statement in the tree
*/
type_t build_symbol_tables (struct tree *t)
{
    // This function should build the symbol tables for the given tree
    
    type_t return_val = VOID; // Blocks need to return last statement. I think just constantly updating the return_val should work.
    
    if (scope_level() == -1) {
        if(!(t->production_rule == CRATE_R)){
            error("The root of the tree must be a crate type.", search_for_line_number(t));
        }
        // Create the global scope
        scope_enter();
        build_default_functions();
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
            fprintf(stderr, "Inner attrs are not in the irony language. They will be simply ignored for now.");
            break;

        case MOD_ITEMS_R:
            // This subtree is a list of MOD_ITEMs
        case MOD_ITEM_R:
            // This subtree is a specific item in a module
            return_val = build_symbol_tables(kid);
            break;
        case ATTRS_AND_VIS_R:
            // This subtree is a list of attributes and visibility
            // We dont need to worry about this for irony. 
            // It is used in Rust to declare the visibility of a module
            // Maybe later we can go back and add support for this or throw an error
            break;
        
        // Stmt items
        case ITEM_MACRO_R:
            error("Item macros are not valid in Irony.", search_for_line_number(t));
            break;
        case ITEM_STATIC_R:
            // This subtree is a static variable declaration
            // According to the RustDocs its similar to a const, the only difference is statics point to a static memory.
            // I think thats similar enough to just treat it the same as a const.
            if (kid->nkids == 8) {
                // This is a mutable static. Thats kinda dumb imo
                error("Sorry, mutable statics aren't allowed. Why would you even want to do that?", search_for_line_number(t));
            }
            // Fall through
        case ITEM_CONST_R:
            // This subtree is a constant variable declaration
            // Formatted as STATIC/CONST, ident, ':', ty, '=', expr, ';'

            // This is a lot like a let declaration.
            return_val = const_declaration(kid);
            break;
        case ITEM_TYPE_R:
            // This subtree is a type declaration
            error("Type declarations are not supported in Irony.", search_for_line_number(t));
            break;
        case VIEW_ITEM_R:
            case EXTERN_FN_ITEM_R:  // These are also view items
            case USE_ITEM_R:        // These are also view items
            // This subtree is a view item or an external function declaration
            error("Views are not supported in Irony.", search_for_line_number(t));
            break;

        // Block items
        case ITEM_FN_R:
            // This subtree is a function declaration
            return_val = function_declaration(kid);
            break;
        case ITEM_UNSAFE_FN_R:
            error("Unsafe functions are not allowed in Irony", search_for_line_number(t));
            break;
        case ITEM_MOD_R:
        case ITEM_FOREIGN_MOD_R:
            // This subtree is a module declaration
            error("Modules are not allowed in Irony", search_for_line_number(t));
            break;
        case ITEM_STRUCT_R:
            error("Structs are not allowed in Irony", search_for_line_number(t));
            break;
        case ITEM_ENUM_R:
            error("Enums are not allowed in Irony", search_for_line_number(t));
            break;
        case ITEM_UNION_R:
            error("Unions are not allowed in Irony", search_for_line_number(t));
            break;
        case ITEM_TRAIT_R:
            error("Traits are not allowed in Irony", search_for_line_number(t));
            break;
        case ITEM_IMPL_R:
            error("Impls are not allowed in Irony", search_for_line_number(t));
            break;

        // Statements
        case MAYBE_STMTS_R:
            case STMTS_R:
            case STMT_R:
            // Statements have semicolons at the end, and thus should return VOID by default unless they are a return statement
            return_val = build_symbol_tables(kid);
            break;
        case LET_R:
            // This subtree is a let declaration
            return_val = let_declaration(kid);
            // Having this saved is causing problems,
            // so I'm just going to reset it to void
            return_val = VOID;
            break;
        case SEMICOLON:
            // This is a semicolon. Scrub return value
            struct tree *temp = t->kids[i-1]; // Check if the previous token contains RETURN in the first kid
            if (temp->production_rule == RETURN ||
                (temp->nkids > 0 && temp->kids[0] != NULL && temp->kids[0]->production_rule == RETURN)){
                // This is a return statement
                break;
            }
            return_val = VOID;
            break;

        case BLOCK_R:
            // First child is '{' and last is '}'
            // Middle is a list of statements
            // Recurse into this.
            scope_enter();
            return_val = build_symbol_tables(kid->kids[1]);
            scope_exit();
            break;

        // Expressions
        case BLOCK_EXPR_R:
            // This subtree is a block expression
            // if the first kid is UNSAFE then throw an error

            if(kid->kids[0]->production_rule == UNSAFE){
                error("Unsafe blocks are not allowed in Irony", search_for_line_number(t));
            }
            // if the second kid a BANG then throw an error
            if(kid->kids[1]->production_rule == BANG){
                error("Path expression blocks are not allowed in Irony", search_for_line_number(t));
            }
            // fall through
            case EXPR_MATCH_R:
            case EXPR_IF_R:
            case EXPR_WHILE_R:
            case EXPR_LOOP_R:
            case EXPR_FOR_R:
            case EXPR_IF_LET_R:
            case EXPR_WHILE_LET_R:
            return_val = block_expr(kid);
            break;

        case EXPR_R:
            case MACRO_EXPR_R:
            case EXPR_NOSTRUCT_R:
            case NONBLOCK_EXPR_R:
            // This subtree is an expression
            return_val = expr_typechecker(kid);
            break;

        case BLOCK_EXPR_DOT_R:
            // This subtree is a block expression with a dot
            error("Dot expressions are not allowed in Irony", search_for_line_number(t));
            break;


        case OUTER_ATTRS_R:
        case OUTER_ATTR_R:
            fprintf(stderr, "Outer attrs are not in the irony language. They will be simply ignored for now.");
            break;

        case PATH_EXPR_R:
            case PATH_GENERIC_ARGS_WITH_COLONS_R:
            case SUPER:
            error("Path expressions are not in the irony language.", search_for_line_number(t));
            break;

        case PUB:
            // This is a public declaration
            error("Public declarations are not allowed in Irony", search_for_line_number(t));
            break;

        case IDENTIFIER:
            // This is an identifier
            // Look it up and make sure it exists in the symbol table
            SymbolTableEntry id = scope_lookup(kid->leaf->text);
            if (id == NULL){
                print_table();
                error("Identifier not found in symbol table", search_for_line_number(t));
            }
            // Identifier was previously declared. Seems like we're good.
            return_val = id->type_t;
            break;
        default:
            break;
        }
    }   

    if(scope_level() == 0 && t->production_rule == CRATE_R){
        scope_exit();   
    }

    return return_val;
}

/**
 * Declare a function and add it to the symbol table
 * @param t The tree to declare the function from
 * @return The return type of the function
*/
type_t function_declaration (struct tree *t)
{
    // Anything passed to this should be a subtree of ITEM_FN_R or ITEM_UNSAFE_FN_R
    char *fn_name = NULL;
    symbol_t fn_symbol = FUNCTION;
    declaration_t fn_decl_t = EXPLICIT;
    type_t fn_type = UNKNOWN_TYPE;
    SymbolTableEntry fn = NULL;
    SymbolTableEntry *params = NULL;
    int array_size = -1;

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
            if(fn_name != NULL)
                error("Function name already declared", search_for_line_number(t));
            if(t->kids[i]->leaf == NULL)
                error("NULL argument in function name", search_for_line_number(t));
            fn_name = t->kids[i]->leaf->text;
            break;

        case FN_DECL_R:
            // This is the function declaration
            struct tree *fn_decl = t->kids[i];

            struct tree *fn_params = fn_decl->kids[0];
            // First and last element of fn_params should be LEFT_PAREN and RIGHT_PAREN
            // Middle param is either NULL, PARAM_R, or PARAMS_R
            if(fn_params == NULL)
                error("Expected a parameter list", search_for_line_number(t));
            if (fn_params->nkids != 3)
                error("Incorrect number of kids in parameter list", search_for_line_number(t));
            if (fn_params->kids[0]->production_rule != LEFT_PAREN)
                error("Expected a left parenthesis", search_for_line_number(t));
            if (fn_params->kids[fn_params->nkids - 1]->production_rule != RIGHT_PAREN)
                error("Expected a right parenthesis", search_for_line_number(t));

            // Now we can start parsing the parameters
            fn_params = fn_params->kids[1];
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
                            error("Complex types are not allowed in Irony", search_for_line_number(t));
                        }
                        break;
                    case TY_CLOSURE_R:
                        // This is a closure type
                        error("Closures are not allowed in Irony", search_for_line_number(t));
                        break;
                    case TY_PRIM_R:
                        // This is a primitive type
                        struct tree *prim_ty = kid;
                        if (prim_ty->kids[0] != NULL && prim_ty->kids[0]->production_rule == LEFT_BRACKET){
                            // This is an array
                            if(prim_ty->kids[1] == NULL)
                                error("Expected a type in let declaration", search_for_line_number(t));
                            switch (prim_ty->nkids)
                            {
                            case 3:
                                // '[' ty ']'
                                // Check if second kid is IDENTIFIER
                                if (prim_ty->kids[1]->production_rule == IDENTIFIER){
                                    fn_type = getTypeFromIdentifier(prim_ty->kids[1]->leaf->text, prim_ty->kids[1]->leaf->lineno);
                                    array_size = -2; // This is a dynamic array
                                } else {
                                    error("Expected an identifier in let declaration", search_for_line_number(t));
                                }
                                break;
                            case 5:
                                // '[' ty ';' expr ']'
                                // Check if second kid is IDENTIFIER
                                if (prim_ty->kids[1]->production_rule == IDENTIFIER){
                                    fn_type = getTypeFromIdentifier(prim_ty->kids[1]->leaf->text, prim_ty->kids[1]->leaf->lineno);
                                    array_size = atoi(prim_ty->kids[3]->leaf->text);
                                    if(array_size <= 0)
                                        error("Array size must be greater than 0", search_for_line_number(t));
                                } else {
                                    error("Expected an identifier in let declaration", search_for_line_number(t));
                                }
                                break;
                            case 6:
                                // '[' ty ',' '..' expr ']'
                                error("Range arrays are not allowed in Irony", search_for_line_number(t));
                                break;
                            }
                            break;
                        }
                        if (prim_ty->kids[0] != NULL && prim_ty->kids[0]->production_rule == LEFT_PAREN){
                            error("Tuples are not allowed in Irony", search_for_line_number(t));
                        }
                        error("Primitive types are not allowed in Irony", search_for_line_number(t));
                        break;
                    case IDENTIFIER:
                        // This is a simple type
                        fn_type = getTypeFromIdentifier(kid->leaf->text, kid->leaf->lineno);
                        break;
                    default:
                        break;
                    }
                }
            }

            break;
        case INNER_ATTRS_AND_BLOCK_R:
            // This is the function body
            if (fn_name == NULL) {
                error("Function name not found", search_for_line_number(t));
            }
            fn = create_symbol(fn_symbol, fn_decl_t, fn_type, fn_name);

            insert_symbol(fn);
            scope_enter(); //(Originally done for FUNCTION in create_symbol)
            // Add the parameters to the symbol table
            int j = 0;
            if(params != NULL){
                while(params[j] != NULL){
                    insert_symbol(params[j]);
                    j++;
                }
            }
            type_t ret_type = build_symbol_tables(t->kids[i]);

            if (array_size != -1) {
                if (!(ret_type == ARRAY))
                    error("Function return type array declared, but return type is not an array", search_for_line_number(t));
                
                if (array_size == -2){
                    array_size = array_sizechecker(t->kids[i]);
                } else if (array_size != array_sizechecker(t->kids[i])){
                    error("Array size mismatch in function declaration", search_for_line_number(t));
                }
                ret_type = array_typechecker(t->kids[i]);
            }

            if (ret_type != fn_type) {
                if(ret_type == DOUBLE && (fn_type == INT_64 || fn_type == U_INT_64))
                    error("Function declared as an integer, but the return type is a float", search_for_line_number(t));
                if ((ret_type == U_INT_64 || ret_type == INT_64)
                        && (fn_type == INT_64 || fn_type == U_INT_64 || fn_type == DOUBLE))
                    ret_type = fn_type;

                if (fn_type == STRING) // Allow implicit conversion to string from any type
                    ret_type = STRING;
                
                if (!(ret_type == fn_type)){
                    fprintf(stderr, "Function name: %s\n", fn_name);
                    fprintf(stderr, "Function declaration type: %d\n", fn_type);
                    fprintf(stderr, "Function returned type: %d\n", ret_type);
                    error("Type mismatch in function declaration", search_for_line_number(t));
                }
            }
            fn->fn_table = scope_exit();
            fn->array_size = array_size;
            break;
        default:
            break;
        }
    }
    return fn_type;
}

/**
 * Get the type_t value from an identifier
 * @param ident The identifier to get the type from
 * @param l The line number of the identifier (for error messages)
 * @return The type of the identifier
*/
type_t getTypeFromIdentifier (char *ident, int l)
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
    if(ident == NULL){
        error("NULL IDENTIFIER\n", l);
        return UNKNOWN_TYPE;
    }
    while (i < (int)(sizeof(types)/sizeof(types[0])))
    {
        if(strcmp(ident, types[i]) == 0)
            break;
        i++;
    }
    switch (i)
    {
    case 0:
        error("i8 is not allowed in Irony", l);
        break;
    case 1:
        error("i16 is not allowed in Irony", l);
        break;
    case 2:
        // This is the default type for integers
        // And default int size in Rust and C
        // But for the sake of compatibility, lets just return INT_64
        // fall through
    case 3:
        return INT_64;
    case 4:
        error("i128 is not allowed in Irony", l);
        break;
    case 5:
        error("u8 is not allowed in Irony", l);
        break;
    case 6:
        error("u16 is not allowed in Irony", l);
        break;
    case 7:
        // fall through
    case 8:
        return U_INT_64;
    case 9:
        error("u128 is not allowed in Irony", l);
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

/** 
 * Recursively parse the parameters in a function declaration
 * called by parseParams
 * @param params The array of parameters to add to
 * @param t The tree to parse
 * @param len The length of the params array
*/
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
                    error("Unexpected production rule in parameter list", search_for_line_number(t));
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
            error("NULL argument in parameter list where argument is expected", search_for_line_number(t));

        if(!(param_ident->production_rule == IDENTIFIER))
            error("Expected an identifier in parameter list", search_for_line_number(t));
        if(!(param_type->production_rule == IDENTIFIER))
            error("Expected a type in parameter list", search_for_line_number(t));

        if(param_ident->leaf == NULL || param_type->leaf == NULL)
            error("NULL argument in parameter list where argument is expected", search_for_line_number(t));
        
        char *param_name = param_ident->leaf->text;
        type_t param_t = getTypeFromIdentifier(param_type->leaf->text, param_type->leaf->lineno);
        if (param_t == UNKNOWN_TYPE)
        {
            error("Unknown type in parameter list", param_type->leaf->lineno);
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
        error("Unexpected production rule in parameter list", search_for_line_number(t));
        break;
    }
}

/**
 * Parse the parameters in a function declaration
 * @param t The tree to parse
 * @return The array of parameters
*/
SymbolTableEntry *parseParams(struct tree *t)
{
    if(t == NULL)
        return NULL;
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

/**
 * Parses a block expression
 * @param t The tree to parse
 * @return The type of the block expression
*/
type_t block_expr (struct tree *t)
{
    // This function should parse the block expression and add the symbols to the symbol table
    // Types of block expr are MATCH, IF, IF_LET, WHILE, WHILE_LET, LOOP, FOR

    type_t r_val = UNKNOWN_TYPE;
    switch (t->production_rule)
    {
    case BLOCK_EXPR_R:
        error("BLOCK_EXPR_R rules should not be in irony.", search_for_line_number(t));
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
        error("Match expressions are not implemented in Irony", search_for_line_number(t));
        break;

    case EXPR_IF_R:
        // IF expr_nostruct block
        // IF expr_nostruct block ELSE block_or_if

        type_t if_type = expr_typechecker(t->kids[1]);
        if(if_type != BOOL)
            error("Expected a boolean expression in if statement", search_for_line_number(t));
        scope_enter();
        r_val = build_symbol_tables(t->kids[2]);
        scope_exit();
        if (t->nkids == 5) {
            if (t->kids[4] != NULL 
                    && !((t->kids[4]->production_rule == EXPR_IF_R) || (t->kids[4]->production_rule == EXPR_IF_LET_R))) {
                // This is an ELSE statement
                scope_enter();
                type_t else_block_val = build_symbol_tables(t->kids[4]);
                scope_exit();
                // Validate else block value against if block value
                if(else_block_val == ARRAY && r_val == ARRAY){
                    if(array_sizechecker(t->kids[4]) != array_sizechecker(t->kids[2]))
                        error("Array size mismatch in if-else statement", search_for_line_number(t));
                }

                if (else_block_val != r_val) {
                    if  ( (else_block_val == DOUBLE && (r_val == INT_64 || r_val == U_INT_64))
                            || (r_val == DOUBLE && (else_block_val == INT_64 || else_block_val == U_INT_64))
                        ) {
                        r_val = DOUBLE;
                    } else if ( (else_block_val == INT_64 || else_block_val == U_INT_64)
                            && (r_val == INT_64 || r_val == U_INT_64) 
                        ) {
                        r_val = U_INT_64;
                    } else if ( else_block_val == STRING || r_val == STRING){
                        r_val = STRING;
                        else_block_val = STRING;
                    } else {
                        error("Type mismatch in if-else statement", search_for_line_number(t));
                    }
                }
                
            } else {
                // This is an ELSE IF statement
                type_t elif_val = block_expr(t->kids[4]);
                // Validate else-if block value against if block value
                if(elif_val == ARRAY && r_val == ARRAY){
                    if(array_sizechecker(t->kids[4]) != array_sizechecker(t->kids[2]))
                        error("Array size mismatch in if-else statement", search_for_line_number(t));
                }
                if (elif_val != r_val) {
                    if  ( (elif_val == DOUBLE && (r_val == INT_64 || r_val == U_INT_64))
                            || (r_val == DOUBLE && (elif_val == INT_64 || elif_val == U_INT_64))
                        ) {
                        r_val = DOUBLE;
                    } else if ( (elif_val == INT_64 && r_val == U_INT_64)
                            || (r_val == INT_64 && elif_val == U_INT_64) 
                        ) {
                        r_val = U_INT_64;
                    } else if (elif_val == STRING || r_val == STRING){
                        r_val = STRING;
                        elif_val = STRING;
                    } else {
                        error("Type mismatch in if-else statement", search_for_line_number(t));
                    }
                }
            }
        }
        break;

    case EXPR_IF_LET_R:
        // IF LET pat '=' expr_nostruct block
        // IF LET pat '=' expr_nostruct block ELSE block_or_if

        error("If let statements are not implemented in Irony. They just dont seem practical, sorry.", search_for_line_number(t));
        break;

    case EXPR_WHILE_R:
        // maybe_label WHILE expr_nostruct block
        if (t->kids[0] != NULL) {
            error("Labeled loops are not supported by Irony", search_for_line_number(t));
        }
        type_t while_type = expr_typechecker(t->kids[2]);
        if(while_type != BOOL)
            error("Expected a boolean expression in while statement", search_for_line_number(t));
        scope_enter();
        r_val = build_symbol_tables(t->kids[3]);
        scope_exit();
        break;

    case EXPR_WHILE_LET_R:
        // maybe_label WHILE LET pat '=' expr_nostruct block
        if (t->kids[0] != NULL) {
            error("Labeled loops are not supported by Irony", search_for_line_number(t));
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
            error("Expected a boolean expression in while statement", search_for_line_number(t));
        scope_enter();
        r_val = build_symbol_tables(t->kids[6]);
        scope_exit();
        break;

    case EXPR_LOOP_R:
        error("Loop statements are not implemented in Irony, use a While statement instead.", search_for_line_number(t));
        break;
    case EXPR_FOR_R:
        // maybe_label FOR pat IN expr_nostruct block
        if (t->kids[0] != NULL)
            error("Labeled For-loops are not supported by Irony", search_for_line_number(t));

        char *for_name = NULL;
        if (t->kids[2] != NULL && t->kids[2]->production_rule != IDENTIFIER)
            error("Expected an identifier in for loop", search_for_line_number(t));
        for_name = t->kids[2]->leaf->text;

        type_t for_type = expr_typechecker(t->kids[4]);
        if(for_type != UNKNOWN_TYPE)
            error("Expected an iterator in for loop", search_for_line_number(t));
        scope_enter();
        insert_symbol(create_symbol(LOCAL, IMPLICIT, for_type, for_name));
        r_val = build_symbol_tables(t->kids[5]);
        scope_exit();

    default:
        break;
    }    
    return r_val;
}

/**
 * Declare a constant and add it to the symbol table
 * @param t The tree to declare the constant from
 * @return The return type of the constant
*/
type_t const_declaration (struct tree *t)
{
    // STATIC/CONST ident ':' ty '=' expr ';'
    char *const_name = NULL;
    symbol_t const_symbol = GLOBAL;

    declaration_t const_decl = EXPLICIT;
    type_t const_type = UNKNOWN_TYPE;
    SymbolTableEntry const_sym = NULL;
    int array_size = -1;

    if(t->kids[1] == NULL)
        error("Expected an identifier in const declaration", search_for_line_number(t));
    const_name = t->kids[1]->leaf->text;

    struct tree *ty_tree = t->kids[3];
    switch (ty_tree->production_rule){
        case TY_R:
            // This is a complex type
            if (ty_tree->kids[0] != NULL && ty_tree->kids[0]->production_rule == LEFT_PAREN){
                error("Tuples are not allowed in Irony", search_for_line_number(t));
            }
            error("Complex types are not allowed in Irony", search_for_line_number(t));
            break;
        case TY_CLOSURE_R:
            // This is a closure type
            error("Closures are not allowed in Irony", search_for_line_number(t));
            break;
        case TY_PRIM_R:
            // This is a primitive type
            struct tree *prim_ty = ty_tree;
            
            if (prim_ty->kids[0] != NULL && prim_ty->kids[0]->production_rule == LEFT_BRACKET) {
                // This is an array
                if(prim_ty->kids[1] == NULL)
                    error("Expected a type in let declaration", search_for_line_number(t));
                switch (prim_ty->nkids)
                {
                case 3:
                    // '[' ty ']'
                    // Check if second kid is IDENTIFIER
                    if (prim_ty->kids[1]->production_rule == IDENTIFIER){
                        const_type = getTypeFromIdentifier(prim_ty->kids[1]->leaf->text, prim_ty->kids[1]->leaf->lineno);
                        array_size = -2; // This is a dynamic array
                    } else {
                        error("Expected an identifier in let declaration", search_for_line_number(t));
                    }
                    break;
                case 5:
                    // '[' ty ';' expr ']'
                    // Check if second kid is IDENTIFIER
                    if (prim_ty->kids[1]->production_rule == IDENTIFIER){
                        const_type = getTypeFromIdentifier(prim_ty->kids[1]->leaf->text, prim_ty->kids[1]->leaf->lineno);
                        array_size = atoi(prim_ty->kids[3]->leaf->text);
                        if(array_size <= 0)
                            error("Array size must be greater than 0", search_for_line_number(t));
                    } else {
                        error("Expected an identifier in let declaration", search_for_line_number(t));
                    }
                    break;
                case 6:
                    // '[' ty ',' '..' expr ']'
                    error("Range arrays are not allowed in Irony", search_for_line_number(t));
                    break;
                }
                break;
            }
            if (prim_ty->kids[0] != NULL && prim_ty->kids[0]->production_rule == LEFT_PAREN){
                error("Tuples are not allowed in Irony", search_for_line_number(t));
            }
            error("Primitive types are not allowed in Irony", search_for_line_number(t));
            break;
        case IDENTIFIER:
            // This is a simple type
            const_type = getTypeFromIdentifier(ty_tree->leaf->text, ty_tree->leaf->lineno);
            break;
    }

    type_t expr_type = expr_typechecker(t->kids[5]);

    if(array_size != -1){
        type_t expr_arr_type;
        if(expr_type == ARRAY) {
            expr_arr_type = array_typechecker(t->kids[5]);
        } else {
            error("Expected an array in assignment of const", search_for_line_number(t));
        }

        // This is an array. Sizecheck here then we'll typecheck outside this if block
        if (array_size == -2){
            // This is a dynamic array
            array_size = array_sizechecker(t->kids[5]);
        } else {
            // This is a fixed size array
            if (array_size != array_sizechecker(t->kids[5])){
                error("Array size mismatch in const declaration", search_for_line_number(t));
            }
        }
        expr_type = expr_arr_type;
    }

    if (expr_type != const_type) {
        if(expr_type == DOUBLE && (const_type == INT_64 || const_type == U_INT_64))
            error("Const declared as an integer, but the return type is a float", search_for_line_number(t));
        if ((expr_type == U_INT_64 || expr_type == INT_64)
                && (const_type == INT_64 || const_type == U_INT_64 || const_type == DOUBLE))
            expr_type = const_type;

        if (const_type == STRING) // Allow implicit conversion to string from any type
            expr_type = STRING;

        if (!(expr_type == const_type)){
            fprintf(stderr, "Const name: %s\n", const_name);
            fprintf(stderr, "Const declared type: %d\n", const_type);
            fprintf(stderr, "Const returned type: %d\n", expr_type);
            error("Type mismatch in const declaration", search_for_line_number(t));
        }
    }



    const_sym = create_symbol(const_symbol, const_decl, const_type, const_name);
    insert_global_symbol(const_sym);
    return const_type;
}

/**
 * Declare a let statement and add it to the symbol table
 * @param t The tree to declare the let statement from
 * @return The type of the let statement
*/
type_t let_declaration (struct tree *t)
{
    // This function should parse the let declaration and add the symbols to the symbol table
    char *var_name = NULL;
    symbol_t var_symbol = getCurrentSymbolType();

    
    declaration_t var_decl = IMPLICIT;
    type_t var_type = UNKNOWN_TYPE;
    SymbolTableEntry var = NULL;
    int is_mutable = 0;
    int array_size = -1;

    // LET_R is formulated: LET pat maybe_ty_acription maybe_init_expr ';'
    if (t->production_rule != LET_R)
        error("Expected a let declaration", search_for_line_number(t));
    
    if (t->nkids != 5)
        error("Incorrect number of kids in let declaration", search_for_line_number(t));
    if (t->kids[0]->production_rule != LET)
        error("Expected a let keyword", search_for_line_number(t));

    struct tree *pat = t->kids[1];
    if(pat == NULL)
        error("Expected a pattern in let declaration", search_for_line_number(t));
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
            
            error("Path expressions are not in the irony language.", search_for_line_number(t));
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
            
            error("Kinda confused on let declaration with literals as match pattern. This is not in the irony language unless told otherwise.", search_for_line_number(t));
            break;
        case PAT_R:
            // This is a complex pattern
            struct tree *first_kid = pat->kids[0];
            switch (first_kid->production_rule)
            {
                case AMPERSAND:
                    // This is a reference pattern
                    error("Reference patterns are not allowed in Irony", search_for_line_number(t));
                    break;
                case DOUBLE_AMPERSAND:
                    error("Double ampersand let statements are not allowed in Irony", search_for_line_number(t));
                    break;

                case LIT_OR_PATH_R:
                    case PATH_EXPR_R:
                    case PATH_GENERIC_ARGS_WITH_COLONS_R:
                    
                    error("Path expressions are not in the irony language.", search_for_line_number(t));
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
                    
                    error("Kinda confused on let declaration with literals as match pattern. This is not in the irony language unless told otherwise.", search_for_line_number(t));
                    break;
                
                case BINDING_MODE_R:
                    // This is a binding mode pattern
                    case REF:
                    error("Reference patterns are not allowed in Irony", search_for_line_number(t));
                    break;
                case MUT:
                    is_mutable = 1;
                    // check by number of kids
                    if(pat->nkids == 2){
                        // MUT ident
                        var_name = pat->kids[1]->leaf->text;
                    } else {
                        // MUT ident AT pat
                        error("AT patterns are not allowed in Irony", search_for_line_number(t));
                    }
                    break;
                case IDENTIFIER:
                    // This is ident AT pat
                    error("AT patterns are not allowed in Irony", search_for_line_number(t));
                    break;
                case BOX:
                    error("Boxes are not allowed in Irony", search_for_line_number(t));
                    break;
                case LESS_THAN:
                case DOUBLE_LESS_THAN:
                    // using let <> = ... or let <<>> = ...
                    error("Generic patterns are not allowed in Irony", search_for_line_number(t));
                    break;
                
                case LEFT_PAREN:
                case LEFT_BRACKET:
                    // This something idk because tuple and array patterns are handled later in the MAYBE_TY_ASCRIPTION_R
                    error("Tuple and array patterns are not allowed in Irony", search_for_line_number(t));
                default:
                    break;
            }
            break;
        default:
            break;
    }

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
                error("Type sums are not allowed in Irony", search_for_line_number(t));
                break;
            case TY_R:
                if (ty_tree->kids[1]->nkids == 2) {
                    // This is an empty parenthesis
                    var_type = VOID;
                } else {
                    // This is a complex type
                    error("Complex types are not allowed in Irony", search_for_line_number(t));
                }
                break;
            case TY_CLOSURE_R:
                // This is a closure type
                error("Closures are not allowed in Irony", search_for_line_number(t));
                break;
            case PATH_GENERIC_ARGS_WITHOUT_COLONS_R:
                // This is a path generic args without colons
                error("Paths are not allowed in Irony", search_for_line_number(t));
                break;
            case TY_PRIM_R:
                // This is a primitive type
                // We only care if these are arrays, otherwise they are errors (to us :P)
                struct tree *prim_ty = ty_tree->kids[1];
                if (prim_ty->kids[0] != NULL && prim_ty->kids[0]->production_rule == LEFT_BRACKET){
                    // This is an array
                    if(prim_ty->kids[1] == NULL)
                        error("Expected a type in let declaration", search_for_line_number(t));
                    switch (prim_ty->nkids)
                    {
                    case 3:
                        // '[' ty ']'
                        // Check if second kid is IDENTIFIER
                        if (prim_ty->kids[1]->production_rule == IDENTIFIER){
                            var_type = getTypeFromIdentifier(prim_ty->kids[1]->leaf->text, prim_ty->kids[1]->leaf->lineno);
                            array_size = -2; // This is a dynamic array
                        } else {
                            error("Expected an identifier in let declaration", search_for_line_number(t));
                        }
                        break;
                    case 5:
                        // '[' ty ';' expr ']'
                        // Check if second kid is IDENTIFIER
                        if (prim_ty->kids[1]->production_rule == IDENTIFIER){
                            var_type = getTypeFromIdentifier(prim_ty->kids[1]->leaf->text, prim_ty->kids[1]->leaf->lineno);
                            array_size = atoi(prim_ty->kids[3]->leaf->text);
                            if(array_size <= 0)
                                error("Array size must be greater than 0", search_for_line_number(t));
                        } else {
                            error("Expected an identifier in let declaration", search_for_line_number(t));
                        }
                        break;
                    case 6:
                        // '[' ty ',' '..' expr ']'
                        error("Range arrays are not allowed in Irony", search_for_line_number(t));
                        break;
                    }
                    break;
                }
                if (prim_ty->kids[0] != NULL && prim_ty->kids[0]->production_rule == LEFT_PAREN){
                    error("Tuples are not allowed in Irony", search_for_line_number(t));
                }

                error("Primitive types are not allowed in Irony", search_for_line_number(t));
                break;
            case UNDERSCORE:
                // This is a wildcard type
                var_type = UNKNOWN_TYPE;
                break;
            case TY_BARE_FN_R:
                // This is a bare function type
                error("Bare function types are not allowed in Irony... And I cant even find much documentation about them in general. Does anyone even use these? I guess you do if you triggered this error.", search_for_line_number(t));
                break;
            case FOR_IN_TYPE_R:
                // This is a for in type
                error("For in types are not allowed in Irony", search_for_line_number(t));
                break;
            case IDENTIFIER:
                // This is a simple type
                var_type = getTypeFromIdentifier(ty_tree->kids[1]->leaf->text, ty_tree->kids[1]->leaf->lineno);
                break;
            default:
                break;
        }
    }

    struct tree *init_expr = t->kids[3];
    if (init_expr != NULL) {
        // This is an initialization expression
        // format is '=' expr
        struct tree *expr = init_expr->kids[1];
        if (expr == NULL)
            error("Expected an expression in let declaration", search_for_line_number(t));
        // If it has 3 kids and uses the keyword AS, it is a cast expression, which is not allowed in Irony
        if(expr->nkids == 3 && (expr->kids[1] != NULL && expr->kids[1]->production_rule == AS)){
            error("Cast expressions are not allowed in Irony", search_for_line_number(t));
        }
        // If the first child is BOX, it is a box expression, which is not allowed in Irony
        if(expr->kids[0] != NULL && expr->kids[0]->production_rule == BOX){
            error("Box expressions are not allowed in Irony", search_for_line_number(t));
        }
        // Recurse into this.
        type_t ty = expr_typechecker(expr);
        // type_t ty = build_symbol_tables(expr);
        if (var_type == UNKNOWN_TYPE) {
            var_type = ty;
        }

        if(array_size != -1){
            type_t expr_arr_type = array_typechecker(expr);
            if (!(ty == ARRAY))
                error("Expected an array in assignment of let", search_for_line_number(t));

            // This is an array. Sizecheck here then we'll typecheck outside this if block
            if (array_size == -2){
                // This is a dynamic array
                array_size = array_sizechecker(expr);
            } else {
                // This is a fixed size array
                if (array_size != array_sizechecker(expr)){
                    error("Array size mismatch in let declaration", search_for_line_number(t));
                }
            }
            ty = expr_arr_type;
        }

        if (ty != var_type) {
            if(ty == DOUBLE && (var_type == INT_64 || var_type == U_INT_64))
                error("Let declared as an integer, but the return type is a float", search_for_line_number(t));
            if ((ty == U_INT_64 || ty == INT_64)
                    && (var_type == INT_64 || var_type == U_INT_64 || var_type == DOUBLE))
                ty = var_type;

            if (var_type == STRING) // Allow implicit conversion to string from any type
                ty = STRING;

            if (!(ty == var_type)){
                fprintf(stderr, "Variable name: %s\n", var_name);
                fprintf(stderr, "Variable declared type: %d\n", var_type);
                fprintf(stderr, "Variable returned type: %d\n", ty);
                error("Type mismatch in let declaration", search_for_line_number(t));
            }
        }
    }
    if(var_name == NULL)
        error("Variable name not found", search_for_line_number(t));
    var = create_symbol(var_symbol, var_decl, var_type, var_name);
    var->is_mutable = is_mutable;
    var->array_size = array_size;
    insert_symbol(var);
    return var_type;
}

/**
 * Recursively checks the token tree in a function parameter and type checks against expected
 * @param t The tree to parse
 * @param index The index of the parameter in the list
 * @param params The list of parameters to check against
*/
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

            error("Delimited token trees are not allowed in Irony", search_for_line_number(t));
            break;
        case IDENTIFIER:
            if (getTypeFromIdentifier(t->leaf->text, t->leaf->lineno) != UNKNOWN_TYPE) // This is a static type
                break;
            SymbolTableEntry id = scope_lookup(t->leaf->text);
            if (id == NULL)
                error("Identifier not found in symbol table", search_for_line_number(t));
            param = ll_get(params, index);
            if(param == NULL)
                error("Parameter not found in list", search_for_line_number(t));
            if(param->type_t != id->type_t)
                // If one type is float and the other is int, it can pass
                if ((param->type_t == INT_64 || param->type_t == U_INT_64) && id->type_t == DOUBLE)
                    break;
                if (param->type_t == DOUBLE && (id->type_t == INT_64 || id->type_t == U_INT_64))
                    break;
                // All types can be implicitly cast to string.
                if (param->type_t == STRING && !(id->type_t == VOID || id->type_t == UNKNOWN_TYPE) )
                    break; 
                fprintf(stderr, "Expected type %d, got type %d\n", param->type_t, id->type_t);
                error("Type does not match expected parameter type", search_for_line_number(t));
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
                error("Parameter not found in list", search_for_line_number(t));
            if(param->type_t != type)
                error("Type does not match expected parameter type", search_for_line_number(t));
            break;
    }
}

/**
 * Recursively parse the function parameters and type check against expected
 * @param t The tree to parse
 * @param index The index of the parameter in the list (starting from len - 1)
 * @param params The list of parameters to check against
*/
void recursive_parse_fn_params(struct tree *t, int index, List params){
    if(t == NULL)
        return;
    if(t->production_rule == EXPR_R && index != 0){
        error("Too few parameters in function call", search_for_line_number(t));
    }
    if(index < 0){
        error("Too many parameters in function call", search_for_line_number(t));
    }
    switch (t->production_rule)
    {
    case EXPRS_R:
        // exprs ',' expr
        recursive_parse_fn_params(t->kids[0], index - 1, params);
        t = t->kids[2];
        // Fall through
    case IDENTIFIER:
    case EXPR_R:
        // expr
        type_t type = expr_typechecker(t);
        SymbolTableEntry param = ll_get(params, index);
        if(param == NULL)
            error("Parameter not found in list", search_for_line_number(t));
        if(param->type_t != type)
        {
            if ((param->type_t == INT_64 || param->type_t == U_INT_64 || param->type_t == DOUBLE) && (type == INT_64 || type == U_INT_64 || type == DOUBLE))
                break;

            if (param->type_t == STRING && type != VOID)
                break;
            error("Type does not match expected parameter type", search_for_line_number(t));
        }

        break;
    default:
        break;
    }
}

/**
 * Recursively parse and typecheck an expression tree
 * 
 * @param t The tree to parse
 * @return The type of the expression (ARRAY if it is an array expression, UNKNOWN_TYPE otherwise)
*/
type_t expr_typechecker(struct tree *t)
{
    // This rule should only be called on expr or nonblock_expr
    type_t return_type = UNKNOWN_TYPE;
    switch (t->production_rule)
    {
    case NONBLOCK_PREFIX_EXPR_R:
    case NONBLOCK_PREFIX_EXPR_NOSTRUCT_R:
        struct tree *first_kid = t->kids[0];
        if (first_kid != NULL)
            switch (first_kid->production_rule)
            {
            case AMPERSAND:
                // This is a reference expression
                error("Reference expressions are not allowed in Irony", search_for_line_number(t));
                break;
            case DOUBLE_AMPERSAND:
                error("Double ampersand expressions are not allowed in Irony", search_for_line_number(t));
                break;
            case MOVE:
                // This is a move expression
                error("Move expressions are not allowed in Irony", search_for_line_number(t));
                break;
            case STAR:
                // This is a dereference expression
                error("Dereference expressions are not allowed in Irony", search_for_line_number(t));
                break;
            case BANG:
                // This is a not expression, ensure the next kid is a boolean
                return_type = expr_typechecker(t->kids[1]);
                if (return_type != BOOL)
                    error("Expected a boolean in not expression", search_for_line_number(t));
                break;
            case MINUS:
                // This is a negative expression, ensure the next kid is a number
                return_type = expr_typechecker(t->kids[1]);
                if (!(return_type == INT_64 || return_type == U_INT_64 || return_type == DOUBLE))
                    error("Expected a number in negative expression", search_for_line_number(t));
                break;
            default:
                break;
            }

        break;

    case EXPR_NOSTRUCT_R:
    case EXPR_R:
    case NONBLOCK_EXPR_R:
        // This is an expression
        if (t->kids[0]->production_rule == NONBLOCK_PREFIX_EXPR_NOSTRUCT_R || t->kids[0]->production_rule == NONBLOCK_PREFIX_EXPR_R){
            // if length is 1 it is a lamda expression. Not allowed in Irony
            if(t->nkids == 1 || t->kids[0]->production_rule == MOVE){
                error("Lambda expressions are not allowed in Irony", search_for_line_number(t));
            }

            if (t->kids[0] != NULL)
                switch (t->kids[0]->production_rule)
                {
                case YIELD:
                    error("Yield expressions are not allowed in Irony", search_for_line_number(t));
                    break;
                case SELF:
                    error("Self expressions are not allowed in Irony", search_for_line_number(t));
                    break;
                case SUPER:
                    error("Super expressions are not allowed in Irony", search_for_line_number(t));
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
                error("Reference expressions are not allowed in Irony", search_for_line_number(t));
            }
            break;
        }

        if (t->nkids == 2){
            if (t->kids[0] != NULL && t->kids[0]->production_rule == BOX){
                // This is a box expression
                error("Box expressions are not allowed in Irony", search_for_line_number(t));
            }
            if (t->kids[0] != NULL && t->kids[0]->production_rule == RETURN){
                // This is a return expression, get the type of the return expression
                return_type = expr_typechecker(t->kids[1]);
                break;
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
                return_type = array_typechecker(t->kids[1]);
                return ARRAY;
            }
            type_t left;
            type_t right;
            switch (t->kids[1]->production_rule){
                case DOT:
                    error("Dot expressions are not allowed in Irony", search_for_line_number(t));
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
                case AMPERSAND_EQUAL:
                case PIPE_EQUAL:
                case CARET_EQUAL:
                case PIPE:
                case CARET:
                case AMPERSAND:
                    error("Bitwise expressions are not allowed in Irony", search_for_line_number(t));
                    break;
                case EQUAL:
                    left = expr_typechecker(t->kids[0]);
                    right = expr_typechecker(t->kids[2]);
                    if(left == ARRAY || right == ARRAY){
                        // We need to check if the arrays are the same type and size
                        int left_size = array_sizechecker(t->kids[0]);
                        int right_size = array_sizechecker(t->kids[2]);
                        if(left_size != right_size)
                            error("Array size mismatch in comparison", search_for_line_number(t));
                        
                        left = array_typechecker(t->kids[0]);
                        right = array_typechecker(t->kids[2]);
                        if (left == UNKNOWN_TYPE && right == UNKNOWN_TYPE)
                            return_type = UNKNOWN_TYPE;
                        if (left == UNKNOWN_TYPE) {
                            return_type = right;
                            left = right;
                        }
                        if (right == UNKNOWN_TYPE) {
                            return_type = left;
                            right = left;
                        }
                        if (left != right) {
                            // If one type is float and the other is int, it can pass
                            if ( ((left == INT_64 || left == U_INT_64) && right == DOUBLE)
                                || (left == DOUBLE && (right == INT_64 || right == U_INT_64))) {
                                return_type = DOUBLE;
                                left = DOUBLE;
                                right = DOUBLE;
                            }
                            if (left == STRING || right == STRING) {
                                return_type = STRING;
                                left = STRING;
                                right = STRING;
                            }
                            if ((left == U_INT_64 || right == U_INT_64) && (left == INT_64 || right == INT_64)) {
                                return_type = U_INT_64; 
                                left = U_INT_64;
                                right = U_INT_64;
                            }

                            if (left != right){
                                fprintf(stderr, "Left type: %d\n", left);
                                fprintf(stderr, "Right type: %d\n", right);
                                error("Type mismatch in expression (a)", search_for_line_number(t));
                            }
                        }
                    }
                    //fall through
                case DOUBLE_LESS_THAN_EQUAL:
                case DOUBLE_GREATER_THAN_EQUAL:
                case MINUS_EQUAL:
                case PLUS_EQUAL:
                case STAR_EQUAL:
                case SLASH_EQUAL:
                case PERCENT_EQUAL:
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
                    if (left == UNKNOWN_TYPE) {
                        return_type = right;
                        left = right;
                    }
                    if (right == UNKNOWN_TYPE) {
                        return_type = left; 
                        right = left;
                    }
                    if (left != right) {
                        // If one type is float and the other is int, it can pass
                        if ( ((left == INT_64 || left == U_INT_64) && right == DOUBLE)
                            || (left == DOUBLE && (right == INT_64 || right == U_INT_64))) {
                            return_type = DOUBLE;
                            left = DOUBLE;
                            right = DOUBLE;
                        }
                        if (left == STRING || right == STRING) {
                            return_type = STRING;
                            left = STRING;
                            right = STRING;
                        }
                        if ((left == U_INT_64 || right == U_INT_64) && (left == INT_64 || right == INT_64)) {
                            return_type = U_INT_64; 
                            left = U_INT_64;
                            right = U_INT_64;
                        }

                        if (left != right){
                            fprintf(stderr, "Left type: %d\n", left);
                            fprintf(stderr, "Right type: %d\n", right);
                            error("Type mismatch in expression", search_for_line_number(t));
                        }
                    }
                    return_type = left;
                    break;
                case AS:
                    // This is a cast expression
                    error("Cast expressions are not allowed in Irony", search_for_line_number(t));
                    break;
                case COLON:
                    // This is a type ascription
                    error("Type ascriptions are not allowed in Irony", search_for_line_number(t));
                    break;
                case DOUBLE_DOT:
                    // This is a range expressionrecursive_parse
                    error("Range expressions are not allowed in Irony", search_for_line_number(t));
                    break;
                default:
                    break;
            }
        }

        if (t->nkids == 4){
            if (t->kids[1] != NULL)
            switch (t->kids[1]->production_rule){
                case LEFT_PAREN:
                    // This is a function
                    // First kid is function name.
                    // 3rd is the maybe_exprs.
                    if(t->kids[0] == NULL || t->kids[0]->leaf == NULL)
                        error("Expected a function name in function call", search_for_line_number(t));
                    SymbolTableEntry search = scope_lookup(t->kids[0]->leaf->text);
                    if (search == NULL)
                        error("Function not found in symbol table", t->kids[0]->leaf->lineno);
                    if (search->symbol_t != FUNCTION)
                        error("Expected a function in function call", t->kids[0]->leaf->lineno);
                    return_type = search->type_t;

                    // TODO: Typecheck Params here. (Note : Similar to MACRO_EXPR_R)
                    struct tree *params = t->kids[2];
                    if(params != NULL){
                        SymbolTable fn_table = search->fn_table;
                        if(fn_table == NULL)
                            error("Function table not found in symbol table entry", search_for_line_number(t));

                        // Check the params
                        List params_list = fn_table->params;
                        if(params_list == NULL)
                            error("Params list not found in function table", search_for_line_number(t));
                        struct tree *tmp = params;
                        // recursive_parse_token_trees(tmp, 0, params_list);
                        // TODO: Typecheck the params, its recursed the other way though.
                        recursive_parse_fn_params(tmp, params_list->size - 1, params_list);
                    }
                    break;

                case DEFAULT:
                    error("This is a 4 kid expression. I dont know what to do with this", search_for_line_number(t));
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
            error("Path expressions are not allowed in Irony", search_for_line_number(t));
            break;
        case MACRO_EXPR_R:
            return expr_typechecker(t->kids[0]);
        case EXPR_QUALIFIED_PATH_R:
            error("Qualified path expressions are not allowed in Irony", search_for_line_number(t));
            break;
        
        case BLOCK_EXPR_R:
            if (t->kids[0]->production_rule == UNSAFE){
                error("Unsafe blocks are not allowed in Irony", search_for_line_number(t));
            }
            if (t->kids[1]->production_rule == BANG){
                error("Path expression blocks are not allowed in Irony", search_for_line_number(t));
            }
            // fall through
        case EXPR_MATCH_R:
        case EXPR_IF_R:
        case EXPR_WHILE_R:
        case EXPR_LOOP_R:
        case EXPR_FOR_R:
            // This is a block expression
            return_type = block_expr(t->kids[0]);
            break;
        
        case BLOCK_R:
            // This is a list of statements
            scope_enter();
            if(t->kids[1] != NULL)
                return_type = build_symbol_tables(t->kids[1]);
            scope_exit();
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
                error("Macro expression identifier not found in symbol table.", search_for_line_number(t));
        } else if(t->kids[0]->production_rule == PATH_EXPR_R){
            // This is a path expression
            error("Path expressions are not allowed in Irony", search_for_line_number(t));
        } else {
            error("Unexpected production rule in macro expression", search_for_line_number(t));
        }
        if (t->kids[2] != NULL) {
            // This is a maybe_ident. Idk what to do with this
            error("Ident after a '!' in a macro expression is not allowed in Irony", search_for_line_number(t));
        }
        if (t->kids[3] == NULL) {
            // This is a  to next caselist of tokens
            error("Expected a list of tokens in macro expression", search_for_line_number(t));
        }
        switch (t->kids[3]->production_rule)
        {
        case BRACKETS_DELIMITED_TOKEN_TREES_R:
            error("Macro expressions with bracket surrounded token trees are not allowed in Irony", search_for_line_number(t));
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
                error("Function table not found in symbol table entry", search_for_line_number(t));

            // Check the params
            List params = fn_table->params;
            if(params == NULL)
                error("Params list not found in function table", search_for_line_number(t));
            struct tree *tmp = tokens;
            recursive_parse_token_trees(tmp, 0, params);
        }
        // If we get here, we're good
        return_type = search->type_t;
        break;

    case IDENTIFIER:
        // This is an identifier
        // Look it up and make sure it exists in the symbol table
        SymbolTableEntry id = scope_lookup(t->leaf->text);
        if (id == NULL)
            error("Identifier not found in symbol table", search_for_line_number(t));
        return_type = id->type_t;
        if (id->symbol_t == FUNCTION)
            error("Expected a function call", search_for_line_number(t));
        if (id->array_size != -1){
            // This is an array, we need to figure out how to return the type of the array and its size
            return_type = ARRAY;
        }

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
        return get_type_from_literal(t);
        break;

    default:
        break;
    }

    return return_type;
    // This function should return the type of the expression
    // If the expression is not valid, it should return UNKNOWN_TYPE
    // We expect everything to be sent to this to have come from expr or nonblock_expr
}

/**
 * Get the type of a literal
*/
type_t get_type_from_literal(struct tree *t){
    if (t == NULL)
        error("NULL tree in get_type_from_literal", -1);
    
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
            error("Unexpected production rule in get_type_from_literal", search_for_line_number(t));
            return UNKNOWN_TYPE;
    }
}

/**
 * Recursively gets the size of an array
 * @param t The tree to check
 */
int array_sizechecker(struct tree *t){
    if (t == NULL) {
        return 0;
    }
    if (t->nkids == 0){
        // this is a literal or an identifier
        return 1;
    }
    switch (t->production_rule)
    {
        case EXPR_R:
            if (t->nkids == 3){
                if (t->kids[0] != NULL && t->kids[0]->production_rule == LEFT_BRACKET){
                    // This is an array expression
                    return array_sizechecker(t->kids[1]);
                }
            }
            return 1;
        case EXPRS_R:
            // Formatted [exprs|expr] ',' expr
            return 1 + array_sizechecker(t->kids[0]);
        case VEC_EXPR_R:
            // Formatted as exprs ';' expr
            error("Vector expressions are not allowed in Irony", search_for_line_number(t));
            break;
    }
    error("Unexpected production rule in array_sizechecker", search_for_line_number(t));
    return 0;
}

/**
 * Recursively typechecks an array expression
 * @param t The tree to check
 * @return The type of the array
*/
type_t array_typechecker(struct tree *t){
    if (t == NULL) {
        return UNKNOWN_TYPE;
    }
    if (t->nkids == 0){
        // this is a literal or an identifier
        return expr_typechecker(t);
    }
    switch (t->production_rule)
    {
        case EXPR_R:
            if (t->nkids == 3){
                if (t->kids[0] != NULL && t->kids[0]->production_rule == LEFT_BRACKET){
                    // This is an array expression
                    return array_typechecker(t->kids[1]);
                }
            }
            return expr_typechecker(t);
        case EXPRS_R:
            // Formatted [exprs|expr] ',' expr
            type_t left = array_typechecker(t->kids[0]);
            type_t right = expr_typechecker(t->kids[2]);
            if (left == UNKNOWN_TYPE && right == UNKNOWN_TYPE)
                return UNKNOWN_TYPE;
            if (left == UNKNOWN_TYPE)
                return right;
            if (right == UNKNOWN_TYPE)
                return left;
            if (left != right) {
                // If one type is float and the other is int, it can pass
                if ( ((left == INT_64 || left == U_INT_64) && right == DOUBLE)
                    || (left == DOUBLE && (right == INT_64 || right == U_INT_64))) {
                    return DOUBLE;
                }
                if (left == STRING || right == STRING) {
                    return STRING;
                }
                if ((left == U_INT_64 || right == U_INT_64) && (left == INT_64 || right == INT_64)) {
                    return U_INT_64; 
                }

                if (left != right)
                    error("Type mismatch in array expression", search_for_line_number(t));
            }
            return left;
        case VEC_EXPR_R:
            // Formatted as exprs ';' expr
            error("Vector expressions are not allowed in Irony", search_for_line_number(t));
            break;
    }
    // fprintf(stderr, "Production rule: %d, %s: nkids %d\n", t->production_rule, t->symbolname, t->nkids);

    error("Unexpected production rule in array_typechecker", search_for_line_number(t));
    return UNKNOWN_TYPE;

}