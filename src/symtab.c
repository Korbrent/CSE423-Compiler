/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: symtab.c
 * @brief: Functions for the symbol table
 * 
 * @version: 0.4.6
*/
#include "symtab.h"
#include "tree.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "main.h"
// #define NDEBUG
#include <assert.h>

SymbolTable stack = NULL;
List roots; // One for each file
List names; // Name of each file
int isFunction = 0;

int __yyerror(char *s, int yystate);

void push_table(){
    SymbolTable new_table = malloc(sizeof(struct sym_table));
    new_table->next = stack;
    new_table->table = ht_create();
    new_table->params = NULL;
    new_table->nEntries = 0;
    new_table->subTables = NULL;
    stack = new_table;
}

void pop_table(){
    // SymbolTable temp = stack;
    stack = stack->next;
}

void scope_enter(){
    push_table();
    stack->subTables = ll_create();
}

SymbolTable scope_exit(){
    SymbolTable temp = stack;
    pop_table();

    if (stack != NULL && stack->subTables != NULL && !isFunction) {
        // We finished a scope, so we need to add the subtable to the parent
        ll_add(stack->subTables, temp);
    }
    if(isFunction){
        isFunction = 0;
    }

    if (stack == NULL){
        // This is the end of the file
        if (roots == NULL){
            roots = ll_create();
            names = ll_create();
        }
        ll_add(roots, temp);
        ll_add(names, getFileName());
    }

    return temp;
}

int scope_level(){
    int level = -1;
    SymbolTable temp = stack;
    while(temp != NULL){
        level++;
        temp = temp->next;
    }
    return level; // 0 is global scope
}

SymbolTableEntry create_symbol
(symbol_t symbol, declaration_t declaration, type_t type, char *name)
{
    
    SymbolTableEntry new_symbol = malloc(sizeof(struct sym_entry));

    // Set the fields of the new symbol

    // Type of the symbol (GLOBAL, LOCAL, PARAM, FUNCTION, UNKNOWN)
    new_symbol->symbol_t = symbol;
    // If implicit, we must enforce type-lookahead to determine type
    new_symbol->declaration_t = declaration;
    // The variable type (or return type for functions)
    new_symbol->type_t = type;
    // Name of the symbol (identifier)
    new_symbol->name = name;
    // Ordinance of the symbol in the table (initialized to -1)
    new_symbol->ordinance = -1;
    // Symbol table for the function (if the symbol is a function)
    new_symbol->fn_table = NULL;
    // if(symbol == FUNCTION){
    //     // continue;
    //     // scope_enter();
    //     // new_symbol->fn_table = stack;
    // }
    new_symbol->is_mutable = 0;
    return new_symbol;
}

void insert_global_symbol(SymbolTableEntry symbol) {
    // Inserts the symbol into the global scope
    if(stack == NULL){
        __yyerror("No scope to insert symbol into. This is 100 percent a bug in the fec compiler. Fix ur stuff brogrammer", 3);
        return;
    }

    SymbolTable temp = stack;
    while(temp->next != NULL){
        temp = temp->next;
    }
    if(ht_search(temp->table, symbol->name) != NULL){
        __yyerror("Symbol already exists in the current scope.", 3);
        return;
    }
    symbol->ordinance = temp->nEntries++;
    symbol->is_mutable = 0;
    ht_insert(temp->table, symbol->name, symbol);
    temp->nEntries++;
}

void insert_symbol(SymbolTableEntry symbol){
    // Inserts the symbol into the current scope
    if(stack == NULL){
        __yyerror("No scope to insert symbol into. This is 100 percent a bug in the fec compiler. Fix ur stuff brogrammer", 3);
        return;
    }

    if(ht_search(stack->table, symbol->name) != NULL){
        __yyerror("Symbol already exists in the current scope.", 3);
        return;
    }

    /* The following will check for shadowing.
     * But we wanna try and implement shadowing if we can for now
     */
    // SymbolTable temp = stack;
    // temp = temp->next;
    // while(temp != NULL){
    //     if(ht_search(temp->table, symbol->name) != NULL){
    //         __yyerror("Shadowing is not currently supported in Irony.", 3);
    //         return;
    //     }
    //     temp = temp->next;
    // }
    ht_insert(stack->table, symbol->name, symbol);

    assert(ht_search(stack->table, symbol->name) != NULL);

    stack->nEntries++;
    if (symbol->symbol_t == FUNCTION) {
        isFunction = 1;
        // scope_enter();
        // symbol->fn_table = stack;
    }

    if(symbol->symbol_t == PARAM){
        if(stack->params == NULL){
            stack->params = ll_create();
        }
        ll_add(stack->params, symbol);
    }
    symbol->ordinance = stack->nEntries;
}

void scope_bind(char *name, SymbolTableEntry entry){
    // Binds name to the entry in the current scope
    SymbolTable temp = stack;
    if(temp == NULL){
        __yyerror("No scope to bind symbol in. This is 100 percent a bug in the fec compiler. Fix ur stuff brogrammer", 3);
        return;
    }
    if(ht_search(temp->table, name) != NULL){
        __yyerror("Symbol already exists in the current scope.", 3);
        return;
    }
    // TODO: FIX THIS!!! IT IS NOT CORRECT!!!!!!!
    __yyerror("This function is not implemented yet. Fix ur stuff brogrammer", 3);
    ht_insert(temp->table, name, entry);
}
// 
SymbolTableEntry scope_lookup(char *name){
    // Returns the first entry for the name in all scopes
    SymbolTable temp = stack;
    while(temp != NULL){
        SymbolTableEntry entry = (SymbolTableEntry)ht_search(temp->table, name);
        if(entry != NULL){
            return entry;
        }
        temp = temp->next;
    }
    return NULL;
}

SymbolTableEntry scope_lookup_current(char *name){
    // Returns the first entry for the name in the current scope
    SymbolTable temp = stack;
    if(temp == NULL){
        printf("No scope to look up symbol in. This is 100 percent a bug in the fec compiler. Fix ur stuff brogrammer\n");
        return NULL;
    }
    SymbolTableEntry entry = (SymbolTableEntry)ht_search(temp->table, name);
    return entry;
}


void free_table(SymbolTable table){
    // Frees the given table
    if(table == NULL){
        return;
    }
    if (table->table != NULL)
        ht_delete(table->table);
    if (table->params != NULL){
        SymbolTableEntry param = ll_remove(table->params, 0);
        while(param != NULL){
            free_symbol(param);
            param = ll_remove(table->params, 0);
        }
        ll_destroy(table->params);
    }
    if (table->subTables != NULL){
        SymbolTable subTable = ll_remove(table->subTables, 0);
        while(subTable != NULL){
            free_table(subTable);
            subTable = ll_remove(table->subTables, 0);
        }
        ll_destroy(table->subTables);
    }
    free(table);
}

void free_symbol(SymbolTableEntry symbol){
    // Frees the given symbol
    if(symbol->fn_table != NULL){
        free_table(symbol->fn_table);
    }
    free(symbol);
}

symbol_t getCurrentSymbolType() {
    if (scope_level() == 0) {
        return GLOBAL;
    }
    return LOCAL;
}

void print_table_recursive(SymbolTable symtab, int level);

void print_table() {
    for (int i = 0; i < ll_size(roots); i++) {
        SymbolTable root = (SymbolTable)ll_get(roots, i);
        if(root == NULL){
            printf("Root is NULL\n");
            continue;
        }
        printf("File: %s\n", (char *)ll_get(names, i));

        print_table_recursive(root, 0);
    }
}

char *type_to_str(type_t ty){
    switch (ty) {
        case INT_64:
            return "i64";
        case U_INT_64:
            return "u64";
        case DOUBLE:
            return "f64";
        case BOOL:
            return "bool";
        case CHAR:
            return "char";
        case STRING:
            return "str";
        case VOID:
            return "void";
        case UNKNOWN_TYPE:
        default:
            return "N/A";
    }
}

void print_table_recursive(SymbolTable symtab, int level) {
    if(symtab == NULL){
        return;
    }
    // fprintf(stderr, "Printing table\n");
    assert(symtab->table != NULL);
    HashTable table = symtab->table;
    for (int i = 0; i < HASH_SIZE; i++) {
        HashItem item = table->items[i];
        while (item != NULL) {
            SymbolTableEntry entry = (SymbolTableEntry)item->value;
            for (int j = 0; j < level; j++) {
                printf("  ");
            }
            printf("%s [%s]\n", item->key, type_to_str(entry->type_t));
            if (entry->fn_table != NULL) {
                // printf("Function table\n");
                print_table_recursive(entry->fn_table, level + 1);
            }
            item = item->next;
        }
        // printf("Moving on\n");
    }
    for (int i = 0; i < ll_size(symtab->subTables); i++) {
        // fprintf(stderr, "Subtables\n");
        SymbolTable subTable = (SymbolTable)ll_get(symtab->subTables, i);
        print_table_recursive(subTable, level + 1);
    }
}