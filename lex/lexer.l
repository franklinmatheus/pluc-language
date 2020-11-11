/* 
 * Usage: (1) $ flex lexer.l
 *        (2) $ gcc lex.yy.c -ll (or -lfl)
 *        (3) $ ./a.out
 *        stdin> whatever you like
 *	      stdin> Ctrl-D
 */
%{
#include "y.tab.h"
#include <stdio.h>

extern int yyerror (char *msg);
%}

%%

(\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*+\/)|(\/\/.*)         { }

\"(\\.|[^"\\])*\"                                               { yylval.sValue = strdup(yytext); return STRING; }
\'([a-z]|[A-Z])\'                                               { yylval.cValue = strdup(yytext); return CHAR; }
true|false                                                      { return BOOLEAN; }

if                                                              return(IF);
while                                                           return(WHILE);
do                                                              return(DO);
for                                                             return(FOR);

return                                                          return(RETURN);
break                                                           return(BREAK);
exit                                                            return(EXIT);

void|short|int|long|float|double|char|string|bool|array|set     return(TYPE);

\;                                                              return(SC);
\,                                                              return(CMM);
\(                                                              return(LEFTPAREN);
\)                                                              return(RIGHTPAREN);
\[                                                              return(LEFTBRACKET);
\]                                                              return(RIGHTBRACKET);
\{                                                              return(LEFTBRACE);
\}                                                              return(RIGHTBRACE);

\=                                                              return(ASSIGN);
\+                                                              return(PLUS);
\-                                                              return(MINUS);
\/                                                              return(DIV);
\*                                                              return(TIMES);

\=\=                                                            return(EQQ);
\!\=                                                            return(DIFF);
\<\=                                                            return(LESSEQ);
\<                                                              return(LESS);
\>\=                                                            return(HIGHEREQ);
\>                                                              return(HIGHER);

\&\&                                                            return(AND);
\|\|                                                            return(OR);
\!                                                              return(NOT);

[a-z][a-zA-Z0-9]*                                               { yylval.sValue = strdup(yytext); return ID; }

[0-9]+                                                          { yylval.iValue = atoi(yytext); return NUMBER; }
([0-9]+"."[0-9]*)|([0-9]*"."[0-9]+)                             { yylval.iValue = atof(yytext); return DECIMAL; }

\.                                                              return(DOT);

[ \t\n]+                                                        {  }
.                                                               { yyerror("invalid character"); }
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