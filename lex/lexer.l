/* 
 * Usage: (1) $ flex lexer.l
 *        (2) $ gcc lex.yy.c -ll (or -lfl)
 *        (3) $ ./a.out
 *        stdin> whatever you like
 *	      stdin> Ctrl-D
 */

%%

\"(\\.|[^"\\])*\"                           { printf("STRING_LIT "); }
\'([a-z]|[A-Z])\'                           { printf("CHAR_LIT "); }
[tT][rR][uU][eE]|[fF][aA][lL][sS][eE]       { printf("BOOL_LIT "); }

if                                          { printf("IF "); }
while                                       { printf("WHILE "); }
do                                          { printf("DO "); }
for                                         { printf("FOR "); }

void                                        { printf("VOID "); }

return                                      { printf("RETURN "); }
break                                       { printf("BREAK "); }
exit                                        { printf("EXIT "); }

short                                       { printf("TYPE(%s) ", yytext); }
int                                         { printf("TYPE(%s) ", yytext); }
long                                        { printf("TYPE(%s) ", yytext); }
float                                       { printf("TYPE(%s) ", yytext); }
double                                      { printf("TYPE(%s) ", yytext); }
char                                        { printf("TYPE(%s) ", yytext); }
string                                      { printf("TYPE(%s) ", yytext); }
bool                                        { printf("TYPE(%s) ", yytext); }

array                                       { printf("ARRAY_GTYPE "); }
set                                         { printf("SET_GTYPE "); }

\;                                          { printf("SC "); }
\,                                          { printf("CMM "); }
\(                                          { printf("OPNP "); }
\)                                          { printf("CLSP "); }
\[                                          { printf("OPNT "); }
\]                                          { printf("CLST "); }
\{                                          { printf("OPNB "); }
\}                                          { printf("CLSB "); }

\=                                          { printf("ASSIGN "); }
\+                                          { printf("PLUS "); }
\-                                          { printf("MINUS "); }
\/                                          { printf("DIV "); }
\*                                          { printf("TIMES "); }

\=\=                                        { printf("EQQ "); }
\!\=                                        { printf("DIFF "); }
\<\=                                        { printf("LESSEQ "); }
\<                                          { printf("LESS "); }
\>\=                                        { printf("HGREQ "); }
\>                                          { printf("HGR "); }

\&\&                                        { printf("AND "); }
\|\|                                        { printf("OR "); }
\!                                          { printf("NOT "); }

\{([0-9]+(" "*," "*[0-9]+)*)\}              { printf("LIT_SET "); }
\[([0-9]+(" "*," "*[0-9]+)*)\]              { printf("LIT_ARRAY "); }

[a-z][a-zA-Z0-9]*                           { printf("ID(%s) ", yytext); }

[0-9]+                                      { printf("LIT_INT "); }
([0-9]+"."[0-9]*)|([0-9]*"."[0-9]+)         { printf("LIT_DEC "); }

\n                                          { printf("\n"); }
" "                                         {  }
.                                           { printf("Illegal character ");}
%%
/*
-> Array:
|--> Array pode ser vazio, apenas um elemento, ou vários elementos separados por vírtula
|--> "[" "]" | "[" ([0-9]+(" "* ", " " ")) [0-9]+"]"
*/
int main(void) {
  yylex();
  
  return 0;
}

