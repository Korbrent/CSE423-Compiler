/**
 * Modified by Korbin Shelley
 * Date: February 18, 2024
 * Filename: token.c
 * Description: This file contains code for managing token structures.
*/
#include "token.h"
#include "rustparse.h"
#include <stdlib.h>
#include <string.h>

/**
 * Allocates a new token and initializes it with the given values.
 * @param type The type of token.
 * @param text The text of the token.
 * @param lineno The line number where the token was found.
 * @param filename The name of the file where the token was found.
 * @return A pointer to the new token.
 */
struct token *buildToken(int type, char *text, int lineno, char *filename) {
    // Allocate the token & initialize it with the given values.
    struct token *t = malloc(sizeof(struct token));
    t->category = type;
    t->text = malloc(strlen(text) + 1);
    strcpy(t->text, text);
    t->lineno = lineno;
    t->filename = filename;
    t->ival = -1;
    t->dval = -1.0;
    t->sval = NULL;

    // Parse the text into the token.
    switch(type){
        case INTEGER_LITERAL:
            sscanf(text, "%d", &t->ival);
            break;
        case FLOAT_LITERAL:
            sscanf(text, "%lf", &t->dval);
            break;
        case STRING_LITERAL:
            t->sval = malloc(strlen(text));
            string_literal_parser(text, t->sval);
            break;
        case CHAR_LITERAL:
            t->ival = char_literal_parser(text);
            if (t->ival == -1){
                printf("Error: Not a character literal.\n");
            }
            break;
    }
    return t;
}

/**
 * Parses a string literal and converts escape characters.
 * @param input The string to parse.
 * @param output The parsed string.
 */
void string_literal_parser(char *input, char *output){
    int i = 0; // Index for the input string.
    int j = 0; // Index for the output string.
    int qc = 0; // Quote count.

    char *temp = input;
    while(temp[i] != '\0'){
        // Best case scenario, just copy the character.
        if (!(temp[i] == '"' || temp[i] == '\\')){
            output[j] = temp[i];
            j++;
        }

        // Deal with escape characters.
        if (temp[i] == '\\'){
            // This is an escape character. Skip it and process the next character.
            i++;
            switch(temp[i]){
                case 'a':
                    output[j] = '\a';
                    break;
                case 'b':
                    output[j] = '\b';
                    break;
                case 'e':
                    output[j] = '\e';
                    break;
                case 'f':
                    output[j] = '\f';
                    break;
                case 'n':
                    output[j] = '\n';
                    break;
                case 'r':
                    output[j] = '\r';
                    break;
                case 't':
                    output[j] = '\t';
                    break;
                case 'v':
                    output[j] = '\v';
                    break;
                case '\\':
                    output[j] = '\\';
                    break;
                case '\'':
                    output[j] = '\'';
                    break;
                case '"':
                    output[j] = '"';
                    break;
                default:
                    output[j] = temp[i];
                    break;
            }
            j++;
        }

        // Deal with quotes.
        if (temp[i] == '"' && qc == 0){
            qc++;
            // This is the opening quote. Skip it
        } else if (temp[i] == '"' && qc == 1){
            // This is the closing quote. End here.
            output[j] = '\0';
            break;
        }
        i++;
    }
    // The string is now parsed.
}

/**
 * Parses a character literal and converts escape characters.
 * @param input The string to parse.
 * @return The parsed character.
*/
int char_literal_parser(char *input){
    // Chars are like strings, but with only one character.
    // So it doesnt make sense to parse in a loop.
    int i = 0;
    char returnChar;

    // Check for the opening quote.
    if(input[i] != '\''){
        // This is not a character literal.
        printf("Error: Not a character literal.\n");
        return -1;
    }
    i++; // Skip the opening quote.

    switch(input[i]){
        case '\\':
            i++; // Skip the escape character.
            switch(input[i]){
                case 'a':
                    returnChar ='\a';
                    break;
                case 'b':
                    returnChar ='\b';
                    break;
                case 'e':
                    returnChar ='\e';
                    break;
                case 'f':
                    returnChar ='\f';
                    break;
                case 'n':
                    returnChar ='\n';
                    break;
                case 'r':
                    returnChar ='\r';
                    break;
                case 't':
                    returnChar ='\t';
                    break;
                case 'v':
                    returnChar ='\v';
                    break;
                case '\\':
                    returnChar ='\\';
                    break;
                case '\'':
                    returnChar ='\'';
                    break;
                case '"':
                    returnChar ='"';
                    break;
                default:
                    // This is not a recognized escape character. Just copy it.
                    returnChar = input[i];
                    break;
            }
            break;
        default:
            returnChar = input[i];
            break;
    }
    i++; // Skip the character.

    // Check for the closing quote.
    if(input[i] != '\''){
        // This is not a character literal.
        printf("Error: Not a character literal.\n");
        return -1;
    }

    return returnChar;
}

/**
 * Frees the given token.
 * @param t The token to free.
 */
void tokenfree(struct token *t) {
    // printf("Freeing token %s\n", t->text);
    if (t->text != NULL){
        free(t->text);
    }
    // Don't free the filename, it's a pointer to the command line argument.
    // if (t->filename != NULL){
    //     printf("Freeing filename %s\n", t->filename);
    //     free(t->filename);
    // }
    if (t->category == STRING_LITERAL){
        free(t->sval);
    }
    free(t);
}