/**
 * Modified by Korbin Shelley
 * Date: February 18, 2024
 * Filename: tree.h
 * Description: This file contains the tree structure and function prototypes for tree.c
*/
#ifndef TREE_H
#define TREE_H
#include "token.h"
#define MAXKIDS 15

// Tree node structure
struct tree {
    int id;
    int production_rule;
    char *symbolname;
    int nkids;
    struct tree *kids[MAXKIDS]; /* if nkids > 0*/
    struct token *leaf; /* if nkids == 0; NULL for ε productions */
};

struct tree* treealloc(int production_rule, char *symbolname, int nkids, ...);

/*
 * I actually define treeRoot in tree.c
 * Prevents other files from directly accessing treeRoot
 * Hooray for OOP principles.
 */
// struct tree* treeRoot;
extern void setTreeRoot(struct tree *t);
extern struct tree* getTreeRoot();

void treefree(struct tree *t);


void printNode(struct tree *t, int depth);
void printTree();

int getTreeId();

#endif
