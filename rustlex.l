/* Lexical analyzer for the ironic Rust subset, irony. */
%option noyywrap
%option noinput
%option nounput
%{
#include "ytab.h"
int chars = 0;
int words = 0;
int lines = 0;
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
Self                            {   return SELF_CAP; }
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

async                           {   return ASYNC; }
await                           {   return AWAIT; }
dyn                             {   return DYN; }

abstract                        {   return ABSTRACT; }
become                          {   return BECOME; }
box                             {   return BOX; }
do                              {   return DO; }
final                           {   return FINAL; }
macro                           {   return MACRO; }
override                        {   return OVERRIDE; }
priv                            {   return PRIV; }
try                             {   return TRY; }
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
"..="                           {   return DOUBLE_DOT_EQUALS; }
"?"                             {   return QUESTION; }
"@"                             {   return AT; }
"_"                             {   return UNDERSCORE; }
"("                             {   return LEFT_PAREN; }
")"                             {   return RIGHT_PAREN; }
"["                             {   return LEFT_BRACKET; }
"]"                             {   return RIGHT_BRACKET; }
"{"                             {   return LEFT_BRACE; }
"}"                             {   return RIGHT_BRACE; }


\"([^"\n]|(\\\"))*\"          {   return STRING_LITERAL; }
"-"?[0-9]+|0[xX][0-9a-fA-F]+    {   return INTEGER_LITERAL; }
"-"?([0-9]+(\.[0-9]+)?|[0-9]*\.[0-9]+)([eE][+-]?[0-9]+)? { 
                                    return FLOAT_LITERAL; }

[a-zA-Z][a-zA-Z0-9_]*           {   return IDENTIFIER; }

[ \t]+                          {}
\n                              { lines++; }
[ \t\r\f\v]                     {}
"//".*                          {}
"/*"([^*]|"*"+[^/*])*"*"+"/"    {}
.                               {   // Anything that is not a keyword or whitespace is considered a word.
                                    chars += strlen(yytext);
                                    return UNCAUGHT_TOKEN;
                                }

%%