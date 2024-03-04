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

int yyparse();
extern FILE *yyin;
extern char *filename;
struct token *yytoken;

int yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
    exit(1);
}

int main(int argc, char *argv[]){
    // Check if the number of arguments is correct
    if (argc != 2) {
        printf("Improper usage of this command.\nExample: ./fec <filename>\n");
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
}