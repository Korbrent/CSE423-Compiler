/**
 * @file main.c 
 * @author Korbin Shelley
 * @brief Main function for the lexical analyzer
 * @version lab1
 * @date 2024-01-26
 * 
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ytab.h"

// Flex function calls
int yylex();
extern char *yytext;
extern FILE *yyin;
extern int chars, words, lines;



int main(int argc, char *argv[]) {
    // Check if the number of arguments is correct
    if (argc != 2) {
        printf("Improper usage of this command.\nExample: ./wc <filename>\n");
        return 1;
    }
    
    // Get the first argument as a file name
    char *filename = argv[1];

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

    printf("ID\tLine\tToken\n");
    
    // Call the lexer
    int l_ret;
    while ((l_ret = yylex()))
    {
        printf("%d\t%d\t%s\n", l_ret, lines, yytext);
        if(l_ret > 400){
            switch (l_ret)
            {
            case 401:
                printf("[ERROR %d] Unused keyword [%s] Sorry, this hasn't been implemented in Irony\n", yytext);
                break;
            case 402:
                printf("[ERROR %d] Unused symbol [%s] Sorry, this hasn't been implemented in Irony\n", yytext);
                break;
            case 404:
                printf("[ERROR %d] Uncaught token: %s\n", yytext);
                break;
            default:
                printf("[ERROR %d] Unknown 400 error. Return Value: [%d] String: [%s]");
                break;
            }
            return 1;
        }
    }
    
    // Print the results
    printf("Words: %d\n", words);
    printf("Chars: %d\n", chars);

    // Free dynamically allocated memory
    fclose(yyin);
    free(yytext);
    if(strcmp(filename, argv[1]) != 0) {
        free(filename);
    }

    return 0;
}