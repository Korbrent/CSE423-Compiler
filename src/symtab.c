/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: symtab.c
 * @brief: Functions for the symbol table
 * 
 * @version: 0.4.6
*/
#include "symtab.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

SymbolTable stack = NULL;

int __yyerror(char *s, int yystate);

void push_table(){
    SymbolTable new_table = malloc(sizeof(struct sym_table));
    new_table->next = stack;
    new_table->table = ht_create();
    stack = new_table;
}

void pop_table(){
    // SymbolTable temp = stack;
    stack = stack->next;
}

void scope_enter(){
    push_table();
}

SymbolTable scope_exit(){
    SymbolTable temp = stack;
    pop_table();
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
    if(symbol == FUNCTION){
        new_symbol->fn_table = malloc(sizeof(struct sym_table));
        new_symbol->fn_table->next = stack;
    }

    // If implicit, we must enforce type-lookahead to determine type
    new_symbol->declaration_t = declaration;
    new_symbol->type_t = type;
    new_symbol->name = name;
    return new_symbol;
}

void insert_symbol(SymbolTableEntry symbol){
    // Inserts the symbol into the current scope
    SymbolTable temp = stack;
    if(temp == NULL){
        __yyerror("No scope to insert symbol into. This is 100\% a bug in the fec compiler. Fix ur stuff brogrammer", 3);
        return;
    }

    if(ht_search(temp->table, symbol->name) != NULL){
        __yyerror("Symbol already exists in the current scope.", 3);
        return;
    }
    /* The following will check for shadowing.
     * But we wanna try and implement shadowing if we can for now
     */
    // temp = temp->next;
    // while(temp != NULL){
    //     if(ht_search(temp->table, symbol->name) != NULL){
    //         __yyerror("Shadowing is not currently supported in Irony.", 3);
    //         return;
    //     }
    //     temp = temp->next;
    // }
    ht_insert(stack->table, symbol->name, symbol);
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
    ht_insert(temp->table, name, entry);
}

SymbolTableEntry scope_lookup(char *name){
    // Returns the first entry for the name in all scopes
    SymbolTable temp = stack;
    while(temp != NULL){
        SymbolTableEntry entry = ht_search(temp->table, name);
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
    SymbolTableEntry entry = ht_search(temp->table, name);
    if(entry != NULL){
        return entry;
    }
    return NULL;
}


void free_table(SymbolTable table){
    // Frees the given table
    if(table == NULL){
        return;
    }
    if (table->table != NULL)
        ht_delete(table->table);
    free(table);
}

void free_symbol(SymbolTableEntry symbol){
    // Frees the given symbol
    free(symbol);
}