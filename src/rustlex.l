/* Lexical analyzer for the ironic Rust subset, irony. */
%option noyywrap
%option noinput
%option nounput

%{
#include "token.h"
#include "rustparse.h"
#include "tree.h"
#include "main.h"
int lineno = 0;
// extern struct token *yytoken;
extern void clearFlexBuffer();
// char *filename;

extern int getLineNo(){
    return lineno;
}
int leafAlloc(int i);
void string_literal_parser(char *temp, char *output);
int char_literal_parser(char *input);
void __yyerror(char *s, int yystate);
%}

%%


as                              {   return leafAlloc(AS); }
break                           {   return leafAlloc(BREAK); }
const                           {   return leafAlloc(CONST); }
continue                        {   return leafAlloc(CONTINUE); }
crate                           {   return leafAlloc(CRATE); }
else                            {   return leafAlloc(ELSE); }
enum                            {   return leafAlloc(ENUM); }
extern                          {   return leafAlloc(EXTERN); }
false                           {   return leafAlloc(FALSE); }
fn                              {   return leafAlloc(FN); }
for                             {   return leafAlloc(FOR); }
if                              {   return leafAlloc(IF); }
impl                            {   return leafAlloc(IMPL); }
in                              {   return leafAlloc(IN); }
let                             {   return leafAlloc(LET); }
loop                            {   return leafAlloc(LOOP); }
match                           {   return leafAlloc(MATCH); }
mod                             {   return leafAlloc(MOD); }
move                            {   return leafAlloc(MOVE); }
mut                             {   return leafAlloc(MUT); }
pub                             {   return leafAlloc(PUB); }
ref                             {   return leafAlloc(REF); }
return                          {   return leafAlloc(RETURN); }
self                            {   return leafAlloc(SELF); }
static                          {   return leafAlloc(STATIC); }
struct                          {   return leafAlloc(STRUCT); }
super                           {   return leafAlloc(SUPER); }
trait                           {   return leafAlloc(TRAIT); }
true                            {   return leafAlloc(TRUE); }
type                            {   return leafAlloc(TYPE); }
unsafe                          {   return leafAlloc(UNSAFE); }
use                             {   return leafAlloc(USE); }
where                           {   return leafAlloc(WHERE); }
while                           {   return leafAlloc(WHILE); }

abstract                        {   return leafAlloc(ABSTRACT); }
become                          {   return leafAlloc(BECOME); }
box                             {   return leafAlloc(BOX); }
do                              {   return leafAlloc(DO); }
final                           {   return leafAlloc(FINAL); }
macro                           {   return leafAlloc(MACRO); }
override                        {   return leafAlloc(OVERRIDE); }
priv                            {   return leafAlloc(PRIV); }
typeof                          {   return leafAlloc(TYPEOF); }
unsized                         {   return leafAlloc(UNSIZED); }
virtual                         {   return leafAlloc(VIRTUAL); }
yield                           {   return leafAlloc(YIELD); }

"="                             {   return leafAlloc(EQUAL); }
"=="                            {   return leafAlloc(DOUBLE_EQUAL); }
"!"                             {   return leafAlloc(BANG); }
"!="                            {   return leafAlloc(NOT_EQUAL); }
"<"                             {   return leafAlloc(LESS_THAN); }
"<="                            {   return leafAlloc(LESS_THAN_EQUAL); }
"<<"                            {   return leafAlloc(DOUBLE_LESS_THAN); }
"<<="                           {   return leafAlloc(DOUBLE_LESS_THAN_EQUAL); }
">"                             {   return leafAlloc(GREATER_THAN); }
">="                            {   return leafAlloc(GREATER_THAN_EQUAL); }
">>"                            {   return leafAlloc(DOUBLE_GREATER_THAN); }
">>="                           {   return leafAlloc(DOUBLE_GREATER_THAN_EQUAL); }
"&"                             {   return leafAlloc(AMPERSAND); }
"&="                            {   return leafAlloc(AMPERSAND_EQUAL); }
"&&"                            {   return leafAlloc(DOUBLE_AMPERSAND); }
"|"                             {   return leafAlloc(PIPE); }
"|="                            {   return leafAlloc(PIPE_EQUAL); }
"||"                            {   return leafAlloc(DOUBLE_PIPE); }
"^"                             {   return leafAlloc(CARET); }
"^="                            {   return leafAlloc(CARET_EQUAL); }

"+"                             {   return leafAlloc(PLUS); }
"+="                            {   return leafAlloc(PLUS_EQUAL); }
"-"                             {   return leafAlloc(MINUS); }
"-="                            {   return leafAlloc(MINUS_EQUAL); }
"*"                             {   return leafAlloc(STAR); }
"*="                            {   return leafAlloc(STAR_EQUAL); }
"/"                             {   return leafAlloc(SLASH); }
"/="                            {   return leafAlloc(SLASH_EQUAL); }
"%"                             {   return leafAlloc(PERCENT); }
"%="                            {   return leafAlloc(PERCENT_EQUAL); }

"->"                            {   return leafAlloc(ARROW); }
"=>"                            {   return leafAlloc(FAT_ARROW); }
","                             {   return leafAlloc(COMMA); }
";"                             {   return leafAlloc(SEMICOLON); }
":"                             {   return leafAlloc(COLON); }
"::"                            {   return leafAlloc(DOUBLE_COLON); }
"."                             {   return leafAlloc(DOT); }
".."                            {   return leafAlloc(DOUBLE_DOT); }
"?"                             {   return leafAlloc(QUESTION); }
"@"                             {   return leafAlloc(AT); }
"_"                             {   return leafAlloc(UNDERSCORE); }
"("                             {   return leafAlloc(LEFT_PAREN); }
")"                             {   return leafAlloc(RIGHT_PAREN); }
"["                             {   return leafAlloc(LEFT_BRACKET); }
"]"                             {   return leafAlloc(RIGHT_BRACKET); }
"{"                             {   return leafAlloc(LEFT_BRACE); }
"}"                             {   return leafAlloc(RIGHT_BRACE); }
"#"                             {   return leafAlloc(HASH); }
"$"                             {   return leafAlloc(DOLLAR); }

"~"                             {   return leafAlloc(TILDE); }


'\\?.'                          {   return leafAlloc(CHAR_LITERAL); }
\"([^"\n]|(\\\"))*\"            {   return leafAlloc(STRING_LITERAL); }
\"([^"\n]|(\\\"))*\n            {   __yyerror("Unclosed string", LEXICAL_ERROR); }
"-"?[0-9]+                      {   return leafAlloc(INTEGER_LITERAL); }
"-"?([0-9]+(\.[0-9]+)?|[0-9]*\.[0-9]+) { 
                                    return leafAlloc(FLOAT_LITERAL); }

[a-zA-Z][a-zA-Z0-9_]*           {   return leafAlloc(IDENTIFIER); }

\n                              { lineno++; }
[ \t\r\f\v]                     {}
("//"|"#").*                    {}
"/*"([^*]|"*"+[^/*])*"*"+"/"    { // Count the number of lines in a block comment.
                                    char *temp = yytext;
                                    int i = 0;
                                    int len = strlen(temp);
                                    while(temp[i] != '\0' && i < len){
                                        if(temp[i] == '\n'){
                                            lineno++;
                                        }
                                        i++;
                                    }
                                }
.                               {   // Pass any uncaught character as itself.
                                    // return leafAlloc(yytext[0]);
                                    __yyerror("Unrecognized token", LEXICAL_ERROR);
                                }

%%

// Initialize the token struct.
/* struct token *buildToken(int type, char *text){
    struct token *t = malloc(sizeof(struct token));
    t->category = type;
    t->text = malloc(strlen(text));
    strcpy(t->text, text);
    t->lineno = lineno;
    t->filename = filename;
    t->ival = -1;
    t->dval = -1;
    t->sval = NULL;
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
} */

// Clear the flex buffer.
void clearFlexBuffer(){
    yy_delete_buffer(YY_CURRENT_BUFFER);
}

// Allocate a token node within the tree.
int leafAlloc(int i){
    struct token *t = buildToken(i, yytext, lineno, getFileName());
    yylval.treeptr = malloc(sizeof(struct tree));

    yylval.treeptr->id = getTreeId();
    yylval.treeptr->production_rule = i;
    yylval.treeptr->symbolname = t->text;
    yylval.treeptr->nkids = 0;
    for (int i = 0; i < MAXKIDS; i++){
        yylval.treeptr->kids[i] = NULL;
    }
    yylval.treeptr->leaf = t;
    
    // printf("Leaf node allocated!");
    // printNode(yylval.treeptr, 2);
    return i;
}