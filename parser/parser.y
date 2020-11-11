%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>

  typedef struct node
  {
    struct node *left;
    struct node *right;
    int tokcode;
    char *token;
  } node;

  /******************************* 
    #define YYSTYPE struct node *
  ********************************/

  int yylex();
  int yyerror(char *s);
  extern int yylineno;
  extern char * yytext;

%}

%union {
  	int    iValue; 	/* integer value */
	char   cValue; 	/* char value */
	char *sValue;  /* string value */
 };

%start lines

%token	<iValue> NUMBER
%token	PLUS	MINUS	TIMES	DIVIDE	POWER
%token	LEFT_PARENTHESIS	RIGHT_PARENTHESIS
%token	END

%type <npValue> exp term factor

%left	PLUS	MINUS
%left	TIMES	DIVIDE
%right	POWER

%%

program:

sections:

section:

decl:

type:

group_type:

unit_type:

var_decls:

var_decl:

assign_lit:

lit:

func:

func_params:

params:

stmts:

stmt:

selection_stmt:

if:

else:

iteration_stmt:

while:

escape:

assign:

assign_expr:

expr:

func_call:

exprs:

arr_accss:

op:

math_op:

comp_op:

logic_op:

print: 

%%

int main (void) {
    return yyparse();
}

int yyerror (char *msg) {
	fprintf (stderr, "%d: %s at '%s'\n", yylineno, msg, yytext);
	return 0;
}