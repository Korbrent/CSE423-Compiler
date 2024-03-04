/**
 * Modified by Korbin Shelley
 * Date: February 18, 2024
 * Filename: tree.c
 * Description: This file contains code for managing tree structures.
 */

#include "tree.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct tree *treealloc(int production_rule, char *symbolname, int nkids, ...) {
    struct tree *t = malloc(sizeof(struct tree));
    t->production_rule = production_rule;
    t->symbolname = symbolname;
    t->nkids = nkids;
    if (nkids > 0) {
        va_list kids;
        va_start(kids, nkids);
        for (int i = 0; i < nkids; i++) {
            t->kids[i] = va_arg(kids, struct tree *);
        }
        va_end(kids);
    } /* else {
        t->leaf = va_arg(kids, struct token *);
    } */
    return t;
}

/* WIP!!! */
void treefree(struct tree *t) {
    if (t->nkids > 0) {
        for (int i = 0; i < t->nkids; i++) {
            treefree(t->kids[i]);
        }
    } else {
        // free(t->leaf);
    }
    free(t);
}

void printNode(struct tree *t, int depth) {
    for (int i = 0; i < depth; i++) {
        // 2 spaces per depth level
        printf("  ");
    }
    // Print the symbol name
    printf("%s\n", t->symbolname);
    for (int i = 0; i < t->nkids; i++) {
        printNode(t->kids[i], depth + 1);
    }
}

void printTree(struct tree *t) {
    printNode(t, 0);
}