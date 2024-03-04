#ifndef GRAPHICTREE_H
#define GRAPHICTREE_H
#include "tree.h"
#include <stdio.h>
#include <stdlib.h>

char *escape(char *s);
char *pretty_print_name(struct tree *t);
void print_branch(struct tree *t, FILE *f);
char *yyname(int);
void print_leaf(struct tree *t, FILE *f);
void print_graph2(struct tree *t, FILE *f);
void print_graph(struct tree *t, char *filename);

#endif