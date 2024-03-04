/* Lexical analyzer for the ironic Rust subset, irony. */
%option noyywrap
%option noinput
%option nounput
%{
#include "rustparse.h"
#include "token.h"
int lines = 0;
char *name;
extern struct token *yytoken;
extern void clearFlexBuffer();
%}

%%


as                              {   return AS; }
break                           {   return BREAK; }
const                           {   return CONST; }
continue                        {   return CONTINUE; }
crate                           {   return CRATE; }
else                            {   return ELSE; }
enum                            {   return ENUM; }
extern                          {   return EXTERN; }
false                           {   return FALSE; }
fn                              {   return FN; }
for                             {   return FOR; }
if                              {   return IF; }
impl                            {   return IMPL; }
in                              {   return IN; }
let                             {   return LET; }
loop                            {   return LOOP; }
match                           {   return MATCH; }
mod                             {   return MOD; }
move                            {   return MOVE; }
mut                             {   return MUT; }
pub                             {   return PUB; }
ref                             {   return REF; }
return                          {   return RETURN; }
self                            {   return SELF; }
static                          {   return STATIC; }
struct                          {   return STRUCT; }
super                           {   return SUPER; }
trait                           {   return TRAIT; }
true                            {   return TRUE; }
type                            {   return TYPE; }
unsafe                          {   return UNSAFE; }
use                             {   return USE; }
where                           {   return WHERE; }
while                           {   return WHILE; }

abstract                        {   return ABSTRACT; }
become                          {   return BECOME; }
box                             {   return BOX; }
do                              {   return DO; }
final                           {   return FINAL; }
macro                           {   return MACRO; }
override                        {   return OVERRIDE; }
priv                            {   return PRIV; }
typeof                          {   return TYPEOF; }
unsized                         {   return UNSIZED; }
virtual                         {   return VIRTUAL; }
yield                           {   return YIELD; }

"="                             {   return EQUAL; }
"=="                            {   return DOUBLE_EQUAL; }
"!"                             {   return BANG; }
"!="                            {   return NOT_EQUAL; }
"<"                             {   return LESS_THAN; }
"<="                            {   return LESS_THAN_EQUAL; }
"<<"                            {   return DOUBLE_LESS_THAN; }
"<<="                           {   return DOUBLE_LESS_THAN_EQUAL; }
">"                             {   return GREATER_THAN; }
">="                            {   return GREATER_THAN_EQUAL; }
">>"                            {   return DOUBLE_GREATER_THAN; }
">>="                           {   return DOUBLE_GREATER_THAN_EQUAL; }
"&"                             {   return AMPERSAND; }
"&="                            {   return AMPERSAND_EQUAL; }
"&&"                            {   return DOUBLE_AMPERSAND; }
"|"                             {   return PIPE; }
"|="                            {   return PIPE_EQUAL; }
"||"                            {   return DOUBLE_PIPE; }
"^"                             {   return CARET; }
"^="                            {   return CARET_EQUAL; }

"+"                             {   return PLUS; }
"+="                            {   return PLUS_EQUAL; }
"-"                             {   return MINUS; }
"-="                            {   return MINUS_EQUAL; }
"*"                             {   return STAR; }
"*="                            {   return STAR_EQUAL; }
"/"                             {   return SLASH; }
"/="                            {   return SLASH_EQUAL; }
"%"                             {   return PERCENT; }
"%="                            {   return PERCENT_EQUAL; }

"->"                            {   return ARROW; }
"=>"                            {   return FAT_ARROW; }
","                             {   return COMMA; }
";"                             {   return SEMICOLON; }
":"                             {   return COLON; }
"::"                            {   return DOUBLE_COLON; }
"."                             {   return DOT; }
".."                            {   return DOUBLE_DOT; }
"?"                             {   return QUESTION; }
"@"                             {   return AT; }
"_"                             {   return UNDERSCORE; }
"("                             {   return LEFT_PAREN; }
")"                             {   return RIGHT_PAREN; }
"["                             {   return LEFT_BRACKET; }
"]"                             {   return RIGHT_BRACKET; }
"{"                             {   return LEFT_BRACE; }
"}"                             {   return RIGHT_BRACE; }
"#"                             {   return HASH; }
"$"                             {   return DOLLAR; }


'\\?.'                          {   return CHAR_LITERAL; }
\"([^"\n]|(\\\"))*\"            {   return STRING_LITERAL; }
"-"?[0-9]+                      {   return INTEGER_LITERAL; }
"-"?([0-9]+(\.[0-9]+)?|[0-9]*\.[0-9]+) { 
                                    return FLOAT_LITERAL; }

[a-zA-Z][a-zA-Z0-9_]*           {   return IDENTIFIER; }

\n                              { lines++; }
[ \t\r\f\v]                     {}
("//"|"#").*                    {}
"/*"([^*]|"*"+[^/*])*"*"+"/"    {}
.                               {   // Pass any uncaught character as itself.
                                    return yytext[0];
                                }

%%

void buildToken(int type){
    struct token *t = malloc(sizeof(struct token));
    t->category = type;
    t->text = malloc(strlen(yytext));
    strcpy(t->text, yytext);
    t->lineno = lines;
    t->filename = name;
    t->ival = -1;
    t->dval = -1;
    t->sval = NULL;
    if(type == INTEGER_LITERAL){;
        sscanf(yytext, "%d", &t->ival);
    }
    if(type == FLOAT_LITERAL){
        sscanf(yytext, "%lf", &t->dval);
    }
    if(type == STRING_LITERAL){
        char *temp = yytext;
        // Remove the quotes from the string.
        t->sval = malloc(strlen(temp));
        int i = 0;
        int j = 0;
        int qc = 0;
        while(temp[i] != '\0'){
            // Best case scenario, just copy the character.
            if (temp[i] != '"' && temp[i] != '\\'){
                t->sval[j] = temp[i];
                j++;
            }

            // Deal with escape characters.
            if (temp[i] == '\\'){
                // This is an escape character. Skip it and process the next character.
                i++;
                switch(temp[i]){
                    case 'a':
                        t->sval[j] = '\a';
                        break;
                    case 'b':
                        t->sval[j] = '\b';
                        break;
                    case 'e':
                        t->sval[j] = '\e';
                        break;
                    case 'f':
                        t->sval[j] = '\f';
                        break;
                    case 'n':
                        t->sval[j] = '\n';
                        break;
                    case 'r':
                        t->sval[j] = '\r';
                        break;
                    case 't':
                        t->sval[j] = '\t';
                        break;
                    case 'v':
                        t->sval[j] = '\v';
                        break;
                    case '\\':
                        t->sval[j] = '\\';
                        break;
                    case '\'':
                        t->sval[j] = '\'';
                        break;
                    case '"':
                        t->sval[j] = '"';
                        break;
                    default:
                        t->sval[j] = temp[i];
                        break;
                }
                j++;
            }

            // Deal with quotes.
            if (temp[i] == '"' && qc == 0){
                qc++;
                // This is the opening quote. Skip it->
            } else if (temp[i] == '"' && qc == 1){
                // This is the closing quote. End here.
                t->sval[j] = '\0';
                break;
            }
            i++;
        }
    }
    if(type == CHAR_LITERAL){
        char *temp = yytext;
        char returnChar;
        int qc = 0;
        int i = 0;
        while(1){
            if(temp[i] == '\''){
                switch(qc){
                    case 0:
                        // This is the opening quote. Skip it.
                        qc++;
                        i++;
                        break;
                    case 1:
                        // This is the closing quote.
                        return;
                }
            }
            if(temp[i] == '\\'){
                i++; // Skip the escape character.
                switch(temp[i]){
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
                        returnChar =temp[i];
                        break;
                }
                break;
            } else {
                returnChar =temp[i];
                break;
            }
        }
        t->ival = (int) returnChar;
    }
    yytoken = t;
}

void clearFlexBuffer(){
    yy_delete_buffer(YY_CURRENT_BUFFER);
}