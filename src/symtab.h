/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: symtab.h
 * @brief: Declarations of structs and functions for the symbol table
 * 
 * @version: 0.4.6
*/
#ifndef SYMTAB_H
#define SYMTAB_H

#include "symbolRules.h"
#include "hashtable.h"
#include "linkedlist.h"

typedef struct sym_table *SymbolTable;
typedef struct sym_entry *SymbolTableEntry;

/**
 * @brief SymbolTableEntry is a single entry in the symbol table
 * symbol_t: The type of the symbol (GLOBAL, LOCAL, PARAM, FUNCTION, UNKNOWN)
 * declaration_t: EXPLICIT or IMPLICIT declaration. 
 *      If IMPLICIT, then we must enforce type-lookahead to determine type
 * type_t: The variable type (or return type for functions)
 * ordinance: Ordinance of the symbol in the table
 * fn_table: Symbol table for the function (if the symbol is a function)
 */
struct sym_entry {
    // SymbolTable table;
    char *name;
    symbol_t symbol_t;
    declaration_t declaration_t;
    type_t type_t;
    int ordinance; // Ordinance of the symbol in the table
    SymbolTable fn_table; // Symbol table for the function (if the symbol is a function)
    int is_mutable;
    int line_no;
};
// *SymbolTableEntry;



/**
 * @brief SymbolTable is a symbol table representing a single layer of the scope stack 
 * nEntries: Number of entries in the symbol table
 * next: Next layer in the SymbolTable stack. (last one is Global)
*/
struct sym_table {
    int nEntries;
    // struct sym_table *parent;
    HashTable table;
    SymbolTable next; // Pointer to the next table in the stack, (lower layer in scope. Bottom is global scope)
    List subTables; // List of subtables (This points downward, unlike next which points upward)
    List params; // List of parameters for the function (Of type SymbolTableEntry)
};
// *SymbolTable;


SymbolTableEntry create_symbol
(symbol_t symbol, declaration_t declaration, type_t type, char *name);

/**
 * @brief Push new table on top of the stack to create a new scope
 */
void scope_enter();
/**
 * @brief Pop the top table from the stack to leave the current scope
 */
SymbolTable scope_exit();
/**
 * @brief Returns the current scope level
 * @return int
 */
int scope_level();

/**
 * @brief Adds a symbol to the root of the stack
 */
void insert_global_symbol(SymbolTableEntry symbol);

/**
 * @brief Adds a symbol to the top of the stack
 */
void insert_symbol(SymbolTableEntry symbol);

/**
 * @brief Adds entry to top table, mapping name to sym
 * @param name Name of the symbol
 * @param sym Symbol to bind to name
 */
void scope_bind(char *name, struct sym_entry *sym);
/**
 * @brief Looks up name in all tables in the stack
 * @param name Name of the symbol
 * @return struct sym_entry* Pointer to the first matching symbol entry
 */
SymbolTableEntry scope_lookup(char *name);
/**
 * @brief Looks up name in the current table
 * @param name Name of the symbol
 * @return struct sym_entry* Pointer to the matching symbol entry
 */
SymbolTableEntry scope_lookup_current(char *name);

void free_table(SymbolTable table);
void free_symbol(SymbolTableEntry symbol);
symbol_t getCurrentSymbolType();

SymbolTableEntry *getParams();

void print_table();

#endif