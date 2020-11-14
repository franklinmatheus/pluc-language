%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>

  int yylex();
  int yyerror(char *s);
  extern int yylineno;
  extern char * yytext;

%}

%union {
  int    iValue; 	/* integer value */
	char   cValue; 	/* char value */
	char  *sValue;  /* string value */
  double dValue;  /* float value */
 };

%start program

%token <sValue> ID
%token <sValue> LIT_STRING
%token <cValue> LIT_CHAR
%token <sValue> LIT_BOOLEAN
%token <iValue> LIT_NUMBER
%token <dValue> LIT_DECIMAL 

%token PRINT
%token VOID SHORT INT LONG FLOAT DOUBLE CHAR STRING BOOL ARRAY SET
%token IF ELSE WHILE DO FOR
%token RETURN BREAK EXIT
%token SC CMM LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE
%token ASSIGN PLUS MINUS DIV TIMES
%token EQQ DIFF LESS_EQ LESS HIGHER_EQ HIGHER
%token AND OR NOT
%token DOT

%left	PLUS	MINUS
%left	TIMES	DIV

%%

program:        sections {}

sections:       section {}
                | section sections {}

section:        decl {}
                | func {}

decl:           type var_decls SC {}

type:           INT {}
                | FLOAT {}
                | DOUBLE {}
                | CHAR {}
                | STRING {}
                | BOOL {}
                | VOID {}
                | SHORT {}
                | LONG {}
                | SET type {}
                | ARRAY type {}

var_decls:      var_decl {}
                | var_decl CMM var_decls {}

var_decl:       ID {}
                | assign_lit {}

assign_lit:     ID ASSIGN lit {}
                | arr_accss ASSIGN lit {}

lit:            LIT_NUMBER {}
                | LIT_DECIMAL {} 
                | LIT_STRING {}
                | LIT_CHAR {}
                | LIT_BOOLEAN {}

func:           type ID LEFT_PAREN func_params RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {}

func_params:    VOID {}
                | params {}

params:         param {}
                | param CMM params {}

param:          type ID {}

stmts:          stmt {}
                | stmt stmts {}

stmt:           selection_stmt {}
                | iteration_stmt {}
                | escape {}
                | assign {} 
                | decl {}
                | print {}

selection_stmt: if {}

if:             IF LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {}
                | IF LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE else {}

else:           ELSE LEFT_BRACE stmts RIGHT_BRACE {}

iteration_stmt: while {}

while:          WHILE LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {}

escape:         BREAK SC {}
                | EXIT SC {}
                | RETURN expr SC {}

assign:         assign_lit {}
                | assign_expr {}

assign_expr:    ID ASSIGN expr {}
                | arr_accss ASSIGN expr {}

expr:           ID {}
                | lit {}
                | func_call {}
                | arr_accss {}
                | expr op expr {}
                | LEFT_PAREN expr op expr RIGHT_PAREN {}

func_call:      ID LEFT_PAREN exprs RIGHT_PAREN {}

exprs:          expr {}
                | expr CMM exprs {}

arr_accss:      ID LEFT_BRACKET expr RIGHT_BRACKET {}

op:             math_op {}
                | comp_op {}
                | logic_op {}

math_op:        PLUS {}
                | MINUS {}
                | TIMES {} 
                | DIV {}

comp_op:        EQQ {}
                | DIFF {}
                | LESS_EQ {}
                | LESS {}
                | HIGHER_EQ {} 
                | HIGHER {}

logic_op:       AND {}
                | OR {}

print:          PRINT LEFT_PAREN expr RIGHT_PAREN {}

%%

int main (void) {
    return yyparse();
}

int yyerror (char *msg) {
	fprintf (stderr, "%d: %s at '%s'\n", yylineno, msg, yytext);
	return 0;
}