/* Lexical analyzer for the ironic Rust subset, irony. */
%option noyywrap
%option noinput
%option nounput
%{
#include "ytab.h"
int chars = 0;
int words = 0;
int lines = 0;
char *filename;
extern struct token *yytoken;
void buildToken(int type);
%}

%%


as                              {   buildToken(AS); 
                                    return AS; }
break                           {   buildToken(BREAK);
                                    return BREAK; }
const                           {   buildToken(CONST);
                                    return CONST; }
continue                        {   buildToken(CONTINUE);
                                    return CONTINUE; }
crate                           {   buildToken(CRATE);
                                    return CRATE; }
else                            {   buildToken(ELSE);
                                    return ELSE; }
enum                            {   buildToken(ENUM);
                                    return ENUM; }
extern                          {   buildToken(EXTERN);
                                    return EXTERN; }
false                           {   buildToken(FALSE);
                                    return FALSE; }
fn                              {   buildToken(FN);
                                    return FN; }
for                             {   buildToken(FOR);
                                    return FOR; }
if                              {   buildToken(IF);
                                    return IF; }
impl                            {   buildToken(IMPL);
                                    return IMPL; }
in                              {   buildToken(IN);
                                    return IN; }
let                             {   buildToken(LET);
                                    return LET; }
loop                            {   buildToken(LOOP);
                                    return LOOP; }
match                           {   buildToken(MATCH);
                                    return MATCH; }
mod                             {   buildToken(MOD);
                                    return MOD; }
move                            {   buildToken(MOVE);
                                    return MOVE; }
mut                             {   buildToken(MUT);
                                    return MUT; }
pub                             {   buildToken(PUB);
                                    return PUB; }
ref                             {   buildToken(REF);
                                    return REF; }
return                          {   buildToken(RETURN);
                                    return RETURN; }
self                            {   buildToken(SELF);
                                    return SELF; }
Self                            {   buildToken(SELF_CAP);
                                    return SELF_CAP; }
static                          {   buildToken(STATIC);
                                    return STATIC; }
struct                          {   buildToken(STRUCT);
                                    return STRUCT; }
super                           {   buildToken(SUPER);
                                    return SUPER; }
trait                           {   buildToken(TRAIT);
                                    return TRAIT; }
true                            {   buildToken(TRUE);
                                    return TRUE; }
type                            {   buildToken(TYPE);
                                    return TYPE; }
unsafe                          {   buildToken(UNSAFE);
                                    return UNSAFE; }
use                             {   buildToken(USE);
                                    return USE; }
where                           {   buildToken(WHERE);
                                    return WHERE; }
while                           {   buildToken(WHILE);
                                    return WHILE; }

async                           {   buildToken(ASYNC);
                                    return ASYNC; }
await                           {   buildToken(AWAIT);
                                    return AWAIT; }
dyn                             {   buildToken(DYN);
                                    return DYN; }

abstract                        {   buildToken(ABSTRACT);
                                    return ABSTRACT; }
become                          {   buildToken(BECOME);
                                    return BECOME; }
box                             {   buildToken(BOX);
                                    return BOX; }
do                              {   buildToken(DO);
                                    return DO; }
final                           {   buildToken(FINAL);
                                    return FINAL; }
macro                           {   buildToken(MACRO);
                                    return MACRO; }
override                        {   buildToken(OVERRIDE);
                                    return OVERRIDE; }
priv                            {   buildToken(PRIV);
                                    return PRIV; }
try                             {   buildToken(TRY);
                                    return TRY; }
typeof                          {   buildToken(TYPEOF);
                                    return TYPEOF; }
unsized                         {   buildToken(UNSIZED);
                                    return UNSIZED; }
virtual                         {   buildToken(VIRTUAL);
                                    return VIRTUAL; }
yield                           {   buildToken(YIELD);
                                    return YIELD; }

"="                             {   buildToken(EQUAL);
                                    return EQUAL; }
"=="                            {   buildToken(DOUBLE_EQUAL);
                                    return DOUBLE_EQUAL; }
"!"                             {   buildToken(BANG);
                                    return BANG; }
"!="                            {   buildToken(NOT_EQUAL);
                                    return NOT_EQUAL; }
"<"                             {   buildToken(LESS_THAN);
                                    return LESS_THAN; }
"<="                            {   buildToken(LESS_THAN_EQUAL);
                                    return LESS_THAN_EQUAL; }
"<<"                            {   buildToken(DOUBLE_LESS_THAN);
                                    return DOUBLE_LESS_THAN; }
"<<="                           {   buildToken(DOUBLE_LESS_THAN_EQUAL);
                                    return DOUBLE_LESS_THAN_EQUAL; }
">"                             {   buildToken(GREATER_THAN);
                                    return GREATER_THAN; }
">="                            {   buildToken(GREATER_THAN_EQUAL);
                                    return GREATER_THAN_EQUAL; }
">>"                            {   buildToken(DOUBLE_GREATER_THAN);
                                    return DOUBLE_GREATER_THAN; }
">>="                           {   buildToken(DOUBLE_GREATER_THAN_EQUAL);
                                    return DOUBLE_GREATER_THAN_EQUAL; }
"&"                             {   buildToken(AMPERSAND);
                                    return AMPERSAND; }
"&="                            {   buildToken(AMPERSAND_EQUAL);
                                    return AMPERSAND_EQUAL; }
"&&"                            {   buildToken(DOUBLE_AMPERSAND);
                                    return DOUBLE_AMPERSAND; }
"|"                             {   buildToken(PIPE);
                                    return PIPE; }
"|="                            {   buildToken(PIPE_EQUAL);
                                    return PIPE_EQUAL; }
"||"                            {   buildToken(DOUBLE_PIPE);
                                    return DOUBLE_PIPE; }
"^"                             {   buildToken(CARET);
                                    return CARET; }
"^="                            {   buildToken(CARET_EQUAL);
                                    return CARET_EQUAL; }

"+"                             {   buildToken(PLUS);
                                    return PLUS; }
"+="                            {   buildToken(PLUS_EQUAL);
                                    return PLUS_EQUAL; }
"-"                             {   buildToken(MINUS);
                                    return MINUS; }
"-="                            {   buildToken(MINUS_EQUAL);
                                    return MINUS_EQUAL; }
"*"                             {   buildToken(STAR);
                                    return STAR; }
"*="                            {   buildToken(STAR_EQUAL);
                                    return STAR_EQUAL; }
"/"                             {   buildToken(SLASH);
                                    return SLASH; }
"/="                            {   buildToken(SLASH_EQUAL);
                                    return SLASH_EQUAL; }
"%"                             {   buildToken(PERCENT);
                                    return PERCENT; }
"%="                            {   buildToken(PERCENT_EQUAL);
                                    return PERCENT_EQUAL; }

"->"                            {   buildToken(ARROW);
                                    return ARROW; }
"=>"                            {   buildToken(FAT_ARROW);
                                    return FAT_ARROW; }
","                             {   buildToken(COMMA);
                                    return COMMA; }
";"                             {   buildToken(SEMICOLON);
                                    return SEMICOLON; }
":"                             {   buildToken(COLON);
                                    return COLON; }
"::"                            {   buildToken(DOUBLE_COLON);
                                    return DOUBLE_COLON; }
"."                             {   buildToken(DOT);
                                    return DOT; }
".."                            {   buildToken(DOUBLE_DOT);
                                    return DOUBLE_DOT; }
"..="                           {   buildToken(DOUBLE_DOT_EQUALS);
                                    return DOUBLE_DOT_EQUALS; }
"?"                             {   buildToken(QUESTION);
                                    return QUESTION; }
"@"                             {   buildToken(AT);
                                    return AT; }
"_"                             {   buildToken(UNDERSCORE);
                                    return UNDERSCORE; }
"("                             {   buildToken(LEFT_PAREN);
                                    return LEFT_PAREN; }
")"                             {   buildToken(RIGHT_PAREN);
                                    return RIGHT_PAREN; }
"["                             {   buildToken(LEFT_BRACKET);
                                    return LEFT_BRACKET; }
"]"                             {   buildToken(RIGHT_BRACKET);
                                    return RIGHT_BRACKET; }
"{"                             {   buildToken(LEFT_BRACE);
                                    return LEFT_BRACE; }
"}"                             {   buildToken(RIGHT_BRACE);
                                    return RIGHT_BRACE; }


'\\?.'                          {   buildToken(CHAR_LITERAL);
                                    return CHAR_LITERAL; }
\"([^"\n]|(\\\"))*\"            {   buildToken(STRING_LITERAL);
                                    return STRING_LITERAL; }
"-"?[0-9]+                      {   buildToken(INTEGER_LITERAL);
                                    return INTEGER_LITERAL; }
"-"?([0-9]+(\.[0-9]+)?|[0-9]*\.[0-9]+) { 
                                    buildToken(FLOAT_LITERAL);
                                    return FLOAT_LITERAL; }

[a-zA-Z][a-zA-Z0-9_]*           {   buildToken(IDENTIFIER);
                                    return IDENTIFIER; }

\n                              { lines++; }
[ \t\r\f\v]                     {}
"//".*                          {}
"/*"([^*]|"*"+[^/*])*"*"+"/"    {}
.                               {   // Anything that is not a keyword or whitespace is considered a word.
                                    buildToken(UNCAUGHT_TOKEN);
                                    return UNCAUGHT_TOKEN;
                                }

%%

void buildToken(int type){
    struct token *t = malloc(sizeof(struct token));
    t->category = type;
    t->text = malloc(strlen(yytext));
    strcpy(t->text, yytext);
    t->lineno = lines;
    t->filename = filename;
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