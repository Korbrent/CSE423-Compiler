/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: main.c
 * @brief: This file contains the main code for the Irony fec compiler.
 * 
 * @version: 0.4.6 // 0.HW#.LAB#
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rustparse.h"
#include "tree.h"
#include "graphicTree.h"
#include "symtab.h"
#include "semanticAnalyzer.h"

int yyparse();
extern FILE *yyin;
char *filename;
struct token *yytoken;
void clearFlexBuffer();
int getLineNo();

extern void __yyerror(char *s, int errorCode, int lineno, int returnType) {
    if(lineno != -1)
        fprintf(stderr, "[%d] Error \"%s\" on line %d in file %s\n", errorCode, s, lineno, filename);
    else
        fprintf(stderr, "[%d] Error \"%s\" in file %s\n", errorCode, s, filename);
    exit(returnType);
}

char *getFileName() {
    return filename;
}

int main(int argc, char *argv[]){
    // Check if the number of arguments is correct
    if (argc < 2) {
        printf("Improper usage of this command.\nExample: ./fec <filename> [filenames ...] [-dot] [-tree] [-symtab]\n");
        return 1;
    }

    // Scan for the optional arguments
    int dotFlag = 0;
    int treeFlag = 0;
    int symtabFlag = 0;
    
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "-dot") == 0) {
            dotFlag = i;
        }
        if (strcmp(argv[i], "-tree") == 0) {
            treeFlag = i;
        }
        if (strcmp(argv[i], "-symtab") == 0) {
            symtabFlag = i;
        }
    }
    int numFiles = argc - (1 + (dotFlag != 0) + (treeFlag != 0) + (symtabFlag != 0));

    // Check if the file name was provided
    if (numFiles < 1) {
        printf("Please provide a file name\n");
        return 1;
    }

    // Create an array of filenames
    char **filenames = malloc(sizeof(char *) * (numFiles));
    for (int i = 1; i < argc; i++) {
        char *file = argv[i];
        if(i == dotFlag || i == treeFlag || i == symtabFlag){
            continue;
        }

        // Check if the filename contains a file extension
        if (strchr(file, '.') == NULL) {
            printf("No file extension provided, adding one to %s\n", file);
            // Append ".rs" to the filename
            char *new_filename = malloc(strlen(file) + 4);
            strcpy(new_filename, file);
            strcat(new_filename, ".rs");
            file = new_filename;
        } else {
            // Eh lets malloc it anyways so that we can just free them all later instead of having to check.
            // I doubt anyone is going to be really hungry for the memory of a filename.
            char *new_filename = malloc(strlen(file) + 1);
            strcpy(new_filename, file);
            file = new_filename;
        }
        filenames[i - 1] = file;
    }

    // Loop through the files
    List roots = ll_create();
    for (int fileIndex = 0; fileIndex < numFiles; fileIndex++) {
        filename = filenames[fileIndex];
        // Open the file & check if the file exists
        if (!(yyin = fopen(filename, "r"))) {
            printf("File %s does not exist\n", filename);
            return 1;
        }
        fprintf(stdout, "Now working on file \"%s\"\n", filename);
        
        // Call the parser
        int yp = yyparse();
        fprintf(stderr, "yyparse returns %d\n", yp);

        // Print the tree if -dot argument is provided
        if (dotFlag != 0) {
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
            // printf("\nPrinting dotfile to %s\n", dotfile);
            print_graph(getTreeRoot(), dotfile);
            printf("Dotfile created at %s\n", dotfile);
        }
        
        if (treeFlag != 0) {
            printf("\nPrinting abstract syntax tree\n");
            printTree();
        }
        build_symbol_tables(getTreeRoot());

        ll_add(roots, getTreeRoot());
        clearFlexBuffer();
    }

    if (symtabFlag != 0) {
        printf("\nPrinting symbol table\n");
        print_table();
    }

    for (int i = 0; i < numFiles; i++) {
        free(filenames[i]);
        (struct tree *) ll_remove(roots, 0);
        treefree(getTreeRoot());
    }
}