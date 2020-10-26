/* 
 * Usage: (1) $ flex lexer.l
 *        (2) $ gcc lex.yy.c -ll (or -lfl)
 *        (3) $ ./a.out
 *        stdin> whatever you like
 *	      stdin> Ctrl-D
 */
%{
  int error_num = 0;
  int char_num = 0;
%}

%%

(\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*+\/)|(\/\/.*) { printf("COMMENT: %s.\n", yytext); }

\"(\\.|[^"\\])*\"                                       { char_num += strlen(yytext); printf("STRING_LIT(%s) ", yytext); }
\'([a-z]|[A-Z])\'                                       { char_num += strlen(yytext); printf("CHAR_LIT(%s) ", yytext); }
true|false                                              { char_num += strlen(yytext); printf("BOOL_LIT(%s) ", yytext); }

if                                                      { char_num += 2; printf("IF "); }
while                                                   { char_num += 5; printf("WHILE "); }
do                                                      { char_num += 2; printf("DO "); }
for                                                     { char_num += 3; printf("FOR "); }

void                                                    { char_num += 4; printf("VOID "); }

return                                                  { char_num += 6; printf("RETURN "); }
break                                                   { char_num += 5; printf("BREAK "); }
exit                                                    { char_num += 4; printf("EXIT "); }

short|int|long|float|double|char|string|bool|array|set  { char_num += strlen(yytext); printf("TYPE(%s) ", yytext); }

\;                                                      { ++char_num; printf("SC "); }
\,                                                      { ++char_num; printf("CMM "); }
\(                                                      { ++char_num; printf("OPNP "); }
\)                                                      { ++char_num; printf("CLSP "); }
\[                                                      { ++char_num; printf("OPNT "); }
\]                                                      { ++char_num; printf("CLST "); }
\{                                                      { ++char_num; printf("OPNB "); }
\}                                                      { ++char_num; printf("CLSB "); }

\=                                                      { ++char_num; printf("ASSIGN "); }
\+                                                      { ++char_num; printf("PLUS "); }
\-                                                      { ++char_num; printf("MINUS "); }
\/                                                      { ++char_num; printf("DIV "); }
\*                                                      { ++char_num; printf("TIMES "); }

\=\=                                                    { char_num += 2; printf("EQQ "); }
\!\=                                                    { char_num += 2; printf("DIFF "); }
\<\=                                                    { char_num += 2; printf("LESSEQ "); }
\<                                                      { char_num += 1; printf("LESS "); }
\>\=                                                    { char_num += 2; printf("HGREQ "); }
\>                                                      { char_num += 1; printf("HGR "); }

\&\&                                                    { char_num += 2; printf("AND "); }
\|\|                                                    { char_num += 2; printf("OR "); }
\!                                                      { char_num += 1; printf("NOT "); }

[a-z][a-zA-Z0-9]*                                       { char_num += strlen(yytext); printf("ID(%s) ", yytext); }

[0-9]+                                                  { char_num += strlen(yytext); printf("LIT_INT(%s) ", yytext); }
([0-9]+"."[0-9]*)|([0-9]*"."[0-9]+)                     { char_num += strlen(yytext); printf("LIT_DEC(%s) ", yytext); }

\.                                                      { ++char_num; printf("DOT "); }

\n                                                      { ++yylineno; printf("\n "); }

[ \t]+                                                  {  }
.                                                       { ++char_num; printf("[Illegal character at line %d: %s] ", yylineno, yytext); ++error_num; }
%%
int main(int argc, char *argv[]) {
  // verify params lenght
  if(argc < 2) {
    printf("Especifique o arquivo na entrada.\n");
    return -1;
  }

  // open file
  FILE *file = fopen(argv[1], "r");
  if(!file) {
    printf("Nao foi possivel identificar arquivo.\n");
    return -1;
  }

  // input to lex
  yyin = file;

  // execution
  yylex();
  printf("\n# of lines = %d, # of chars (no comment) = %d, # of errors = %d\n", yylineno, char_num, error_num);

  // close file
  fclose(file);
  return 0;
}