/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: semanticAnalyzer.h
 * @brief: Declarations of the functions for semantic analysis
 * 
 * @version: 0.4.6
*/
#ifndef SEMANTIC_ANALYZER_H
#define SEMANTIC_ANALYZER_H

#include "tree.h"
#include "symtab.h"
#include "symbolRules.h"
#include "parserRules.h"
#include "rustparse.h"

// Function declarations
void build_symbol_tables(struct tree *t);

type_t getTypeFromIdentifier(char *ident);

#endif // SEMANTIC_ANALYZER_H