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

// The root of the tree, manipulated by setTreeRoot() and getTreeRoot().
struct tree *treeRoot;
int tree_id = 0;

/**
 * Allocates a new tree node and initializes it with the given values.
 * @param production_rule The production rule number that created this node.
 * @param symbolname The name of the symbol that this node represents.
 * @param nkids The number of children this node has.
 * @param ... The children of this node. (struct tree *)
 * @return A pointer to the new tree node.
 */
struct tree *treealloc(int production_rule, char *symbolname, int nkids, ...) {
    // printf("treealloc called for rule %s\n", symbolname); // DEBUG

    // Allocate the tree node
    struct tree *t = malloc(sizeof(struct tree));
    t->production_rule = production_rule;
    t->symbolname = symbolname;
    t->nkids = nkids;
    t->leaf = NULL;
    t->id = getTreeId();

    // Set the children using variadic arguments
    if (nkids > 0) {
        va_list kids;
        va_start(kids, nkids);
        for (int i = 0; i < nkids; i++) {
            struct tree *kid = va_arg(kids, struct tree *);
            // if(kid != NULL)
                // printf("kid %d: %s\n", i, kid->symbolname);
            t->kids[i] = kid;
        }
        // Fill the rest of the kids with NULL
        for (int i = nkids; i < MAXKIDS; i++) {
            t->kids[i] = NULL;
        }
        va_end(kids);
    } else {
        // Leaf nodes are handled by the lexer
        fprintf(stderr, "Error in treealloc: nkids is 0. Leaf nodes should be handled elsewhere.\n");
    }
    return t;
}

/**
 * Sets the root of the tree to the given node.
 * @param t The node to set as the root of the tree.
 */
void setTreeRoot(struct tree *t) {
    treeRoot = t;
}

/**
 * Returns the root of the tree.
 * @return The root of the tree.
 */
struct tree *getTreeRoot() {
    return treeRoot;
}

/**
 * Frees the given tree node and all of its children.
 * @param t The tree node to free.
 */
void treefree(struct tree *t) {
    // printf("treefree called for rule %s (kids: %d)\n", t->symbolname, t->nkids); // DEBUG
    if (t->nkids > 0) {
        // Free all the kids
        for (int i = 0; i < t->nkids; i++){
            if(t->kids[i] != NULL)
                treefree(t->kids[i]);
        }
    } else {
        // printf("Freeing %s token\n", t->symbolname);
        // This is a leaf node, free the token
        if (t->leaf != NULL)
            tokenfree(t->leaf);
    }
    // free(t->symbolname);
    // printf("Freeing %s\n", t->symbolname);
    free(t);
}

/**
 * Prints the given tree node and all of its children.
 * @param t The tree node to print.
 * @param depth The depth of the current node in the tree.
 */
void printNode(struct tree *t, int depth) {
    for (int i = 0; i < depth; i++) {
        // 2 spaces per depth level
        printf("  ");
    }
    // Print the symbol name
    printf("%s [#%d]\n", t->symbolname, t->id);
    for (int i = 0; i < t->nkids; i++) {
        if(t->kids[i] != NULL)
            printNode(t->kids[i], depth + 1);
        else{
            for (int i = 0; i < depth + 1; i++) {
                // 2 spaces per depth level
                printf("  ");
            }
            printf("NULL\n");
        }
    }
}

/**
 * Prints the entire tree.
 */
void printTree() {
    printNode(treeRoot, 0);
}

int getTreeId() {
    return tree_id++;
}