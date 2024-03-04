/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: graphicTree.h
 * @brief: This file contains the functions for printing the tree in a graphical format.
 * 
 * @version: 0.3.5
*/

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