#include "graphicTree.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree.h"

/**
 * This file contains the implementation of the functions declared in graphicTree.h
 * Source code is a modified version of the code provided by the professor
 * Located at https://www.cs.nmt.edu/~jeffery/courses/423/lab5.html
*/

/**
 * This function is used to escape the characters in the string
 * @param s The string to be escaped
 * @return The escaped string
 */
char *escape(char *s){
    char *s2 = malloc(strlen(s) + 3);
    if (s[0] == '\"') {
        if (s[strlen(s) - 1] != '\"') {
            fprintf(stderr, "Mismatched quotations\n");
        }
        sprintf(s2, "\\%s", s); // Add a backslash at the beginning
        s2[strlen(s2) - 1] = '\0'; // Remove the trailing quote
        strcat(s2 + strlen(s2) - 1, "\\\""); // Add a backslash and quote at the end
        return s2;
    }
    else{
        free(s2); // Free the memory allocated for s2
        return s;
    }
}

/**
 * This function is used to pretty print the name of the tree
 * @param t The tree to be printed
 * @return The pretty printed name of the tree
 */
char *pretty_print_name(struct tree *t) {
    char *s;
    if (t->leaf == NULL) {
        s = malloc(strlen(t->symbolname) + 16);
        sprintf(s, "%s#%d", t->symbolname, t->production_rule);
    }
    else {
        s = malloc(strlen(t->leaf->text) + 16);
        char *s2 = escape(t->leaf->text);
        sprintf(s, "%s:%d", s2, t->leaf->category);
        free(s2); // Free the RAM from this mundane task of data allocation
    }
    return s;
}
/**
 * This function is used to print the branch of the tree
 * @param t The tree to be printed
 * @param f The file to be printed to
 */
void print_branch(struct tree *t, FILE *f) {
    fprintf(f, "N%d [shape=box label=\"%s\"];\n", t->id, pretty_print_name(t));
}

char *yyname(int);

void print_leaf(struct tree *t, FILE *f) {
    char *s = yyname(t->leaf->category);
    // print_branch(t, f);
    fprintf(f, "N%d [shape=box style=dotted label=\" %s \\n ", t->id, s);
    fprintf(f, "text = %s \\l lineno = %d \\l\"];\n", escape(t->leaf->text),
            t->leaf->lineno);
}

int serial = 0;
void print_graph2(struct tree *t, FILE *f) {
    int i;
    if (t->leaf != NULL) {
        print_leaf(t, f);
        return;
    }
    /* not a leaf ==> internal node */
    print_branch(t, f);
    // Print the kids
    for (i = 0; i < t->nkids; i++) {
        if (t->kids[i] != NULL) {
            fprintf(f, "N%d -> N%d;\n", t->id, t->kids[i]->id);
            print_graph2(t->kids[i], f);
        }
        else {
            /* NULL kid, epsilon production or something */
            fprintf(f, "N%d -> N%d%d;\n", t->id, 800, serial);
            fprintf(f, "N%d%d [label=\"%s\"];\n", 800, serial, "Empty rule");
            serial++;
        }
    }
}

void print_graph(struct tree *t, char *filename)
{
    FILE *f = fopen(filename, "w"); /* should check for NULL */
    printf("Writing dotfile to %s\n", filename);
    fprintf(f, "digraph {\n");
    print_graph2(t, f);
    fprintf(f, "}\n");
    fclose(f);
}