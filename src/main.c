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

int yyparse();
extern FILE *yyin;
extern char *filename;
struct token *yytoken;
void clearFlexBuffer();
int getLineNo();

void printsymbol(char *s){
    printf("%s\n", s); fflush(stdout);
}

/**
 * This is a cheap throwaway function used to fulfill the requirements for Lab6
 * It will be deleted after this submission.
 * 
 * I was busy working on planning the recursive function for building the symbol tables.
 * I wanted to pre-plan how I was gonna handle semanticAnalyzer.{c,h} beforehand
 * 
 * Although look how pretty my symtab.{c,h} and hashtable.{c,h} files are.
 * 
 * My next behemoth is finishing semanticAnalyzer.{c,h}
 */
void printsyms(struct tree *t){
    if(scope_level() == -1){
        scope_enter();
    }
    if (t->leaf != NULL){
        if(t->leaf->category == IDENTIFIER){
            SymbolTableEntry s = create_symbol(UNKNOWN, IMPLICIT, UNKNOWN_TYPE, t->leaf->text);
            if(scope_lookup_current(s->name) == NULL)
                insert_symbol(s);
            for(int i = 0; i < scope_level(); i++){
                printf("  ");
            }
            printsymbol(t->leaf->text);
        }
        if(t->leaf->category == LEFT_BRACE){
            scope_enter();
            for(int i = 0; i < scope_level(); i++){
                printf("  ");
            }
            printf("----------------\n");
        }
        if(t->leaf->category == RIGHT_BRACE){
            for(int i = 0; i < scope_level(); i++){
                printf("  ");
            }
            printf("----------------\n");
            SymbolTable st = scope_exit();
            free_table(st);
        }
        return;
    }
    for (int i = 0; i < t->nkids; i++){
        if(t->kids[i] != NULL)
            printsyms(t->kids[i]);
    }
}

extern int __yyerror(char *s, int yystate) {
    fprintf(stderr, "[%d] Error \"%s\" on line %d in file %s\n", yystate, s, getLineNo(), filename);
    exit(yystate == LEXICAL_ERROR ? 1 : 2);
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
    for (int fileIndex = 0; fileIndex < numFiles; fileIndex++) {
        filename = filenames[fileIndex];
        // Open the file & check if the file exists
        if (!(yyin = fopen(filename, "r"))) {
            printf("File %s does not exist\n", filename);
            return 1;
        }

        // Instead of calling the lexer, call the parser
        int yp = yyparse();
        printf("yyparse returns %d\n", yp);

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
            printf("\nPrinting dotfile to %s\n", dotfile);
            print_graph(getTreeRoot(), dotfile);
        }
        
        if (treeFlag != 0) {
            printf("\nPrinting abstract syntax tree\n");
            printTree();
        }
        
        if (symtabFlag != 0) {
            printf("\nPrinting symbol table\n");
            printsyms(getTreeRoot());
        }
        treefree(getTreeRoot());
        clearFlexBuffer();
    }

    for (int i = 0; i < numFiles; i++) {
        free(filenames[i]);
    }
}