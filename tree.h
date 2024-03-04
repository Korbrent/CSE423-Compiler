/**
 * Modified by Korbin Shelley
 * Date: February 18, 2024
 * Filename: tree.h
 * Description: This file contains the tree structure and function prototypes for tree.c
*/
#ifndef TREE_H
#define TREE_H
#include "token.h"

struct tree {
    int production_rule;
    char *symbolname;
    int nkids;
    struct tree *kids[15]; /* if nkids > 0*/
    struct token *leaf; /* if nkids == 0; NULL for ε productions */
};

struct tree *treealloc(int production_rule, char *symbolname, int nkids, ...);
// void printTreeNode(struct tree *t, int depth);
void printNode(struct tree *t, int depth);

void printTree(struct tree *t);

#endif
