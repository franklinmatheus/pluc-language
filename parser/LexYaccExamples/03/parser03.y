%{
#include <stdio.h>

int yylex(void);
int yyerror(char *s);
extern int yylineno;
extern char * yytext;

%}

%union {
	int    iValue; 	/* integer value */
	char   cValue; 	/* char value */
	char * sValue;  /* string value */
	};

%token <sValue> ID
%token <iValue> NUMBER
%token WHILE BLOCK_BEGIN BLOCK_END DO IF THEN ELSE SEMI ASSIGN

%start prog

%type <sValue> stm

%%
prog : stmlist {} 
	 ;

stm : ID {$<sValue>$ = $1; printf("%s\n",$<sValue>$);} ASSIGN ID {$$ = $4; printf("%s\n",$$);}
    | WHILE ID DO stm						{}
	| BLOCK_BEGIN stmlist BLOCK_END			{}
	| IF ID THEN stm 						{}
	| IF ID THEN stm ELSE stm 				{}
	;
	
stmlist : stm								{}
		| stmlist SEMI stm					{}
	    ;
%%

int main (void) {
	return yyparse ( );
}

int yyerror (char *msg) {
	fprintf (stderr, "%d: %s at '%s'\n", yylineno, msg, yytext);
	return 0;
}