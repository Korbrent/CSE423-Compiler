/**
 * Modified by Korbin Shelley
 * Date: February 18, 2024
 * Filename: main.c
 * Description: This file contains the main code for the Irony fec compiler.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rustparse.h"
#include "tree.h"
#include "graphicTree.h"

int yyparse();
extern FILE *yyin;
extern char *filename;
struct token *yytoken;
void clearFlexBuffer();
int getLineNo();

extern int __yyerror(char *s, int yystate) {
    fprintf(stderr, "[%d] Error \"%s\" on line %d in file %s\n", yystate, s, getLineNo(), filename);
    exit(yystate == LEXICAL_ERROR ? 1 : 2);
}

int main(int argc, char *argv[]){
    // Check if the number of arguments is correct
    if (argc != 2 && argc != 3) {
        printf("Improper usage of this command.\nExample: ./fec <filename> [-dot]\n");
        return 1;
    }

    // Get the first argument as a file name
    filename = argv[1];
    
    // Check if the file name was provided
    if (filename == NULL) {
        printf("Please provide a file name\n");
        return 1;
    }

    // Check if the filename contains a file extension
    if (strchr(filename, '.') == NULL) {
        printf("No file extension provided, adding one to %s\n", filename);
        // Append ".rs" to the filename
        char *new_filename = malloc(strlen(filename) + 4);
        strcpy(new_filename, filename);
        strcat(new_filename, ".rs");
        filename = new_filename;
    }

    // Open the file & check if the file exists
    if (!(yyin = fopen(filename, "r"))) {
        printf("File %s does not exist\n", filename);
        return 1;
    }

    // Instead of calling the lexer, call the parser
    int i = yyparse();
    printf("yyparse returns %d\n", i);

    // Print the tree if -dot argument is provided
    if (argc == 3 && strcmp(argv[2], "-dot") == 0) {
        char *dotfile = malloc(strlen(filename) + 5);
        // Replace `.[suffix]` with `.dot`
        strcpy(dotfile, filename);
        for (int i = strlen(dotfile) - 1; i >= 0; i--) {
            if (dotfile[i] == '.') {
                dotfile[i] = '\0';
                break;
            }
        }
        strcat(dotfile, ".dot");
        // Shrink the malloc dotfile
        dotfile = realloc(dotfile, strlen(dotfile) + 1);
        print_graph(getTreeRoot(), dotfile);
    } else {
        printTree();
    }

    treefree(getTreeRoot());
    clearFlexBuffer();
}