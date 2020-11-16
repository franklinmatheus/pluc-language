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
%token IF ELSE WHILE DO
%token RETURN BREAK EXIT
%token SC CMM LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE
%token ASSIGN PLUS MINUS DIV TIMES
%token EQQ DIFF LESS_EQ LESS HIGHER_EQ HIGHER
%token AND OR NOT

%left	PLUS	MINUS
%left	TIMES	DIV

%%

program:        sections {}
                ;

sections:       section {}
                | section sections {}
                ;

section:        decl {}
                | func {}
                ;

decl:           type var_decls SC {}
                ;

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
                ;

var_decls:      var_decl {}
                | var_decl CMM var_decls {}
                ;

var_decl:       ID {}
                | assign {}
                ;

lit:            LIT_NUMBER {}
                | LIT_DECIMAL {} 
                | LIT_STRING {}
                | LIT_CHAR {}
                | LIT_BOOLEAN {}
                ;

func:           type ID LEFT_PAREN func_params RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {}
                ;

func_params:    %empty {}
                | params {}
                | VOID {}
                ;

params:         param {}
                | param CMM params {}
                ;

param:          type ID {}
                ;

stmts:          stmt {}
                | stmt stmts {}
                ;

stmt:           selection_stmt {}
                | iteration_stmt {}
                | escape {}
                | decl {}
                | print {}
                | func_stmt {}
                | assign_stmt {} 
                ;

selection_stmt: if {}
                ;

if:             IF LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {}
                | IF LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE else {}
                ;

else:           ELSE LEFT_BRACE stmts RIGHT_BRACE {}
                ;

iteration_stmt: while {}
                | do_while {}
                ;

while:          WHILE LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {}
                ;

do_while:        DO LEFT_BRACE stmts RIGHT_BRACE WHILE LEFT_PAREN expr RIGHT_PAREN SC {}
                ;

escape:         BREAK SC {}
                | EXIT SC {}
                | RETURN expr SC {}
                ;

assign:         ID ASSIGN expr {}
                | arr_access ASSIGN expr {}
                | arr_assign {}
                ;

arr_assign:     ID ASSIGN LEFT_BRACKET arr_assign_content RIGHT_BRACKET {}
                | ID ASSIGN type LEFT_PAREN LIT_NUMBER RIGHT_PAREN {}
                ;

arr_assign_content: expr {}
                    | expr CMM arr_assign_content {}
                    ;

assign_stmt:    assign SC {}
                ;

expr:           expr_atom op expr {}
                | NOT expr {}
                | expr_atom {}
                ; 

expr_atom:      ID {}
                | lit {}
                | func_call {}
                | arr_access {}
                | LEFT_PAREN expr RIGHT_PAREN {}
                ;

func_call:      ID LEFT_PAREN RIGHT_PAREN {}
                | ID LEFT_PAREN exprs RIGHT_PAREN {}
                ;

func_stmt:      func_call SC {}
                ;

exprs:          expr {}
                | expr CMM exprs {}
                ;

arr_access:      ID LEFT_BRACKET expr RIGHT_BRACKET {}
                ;

op:             math_op {}
                | rel_op {}
                | logic_op {}
                ;

math_op:        PLUS {}
                | MINUS {}
                | TIMES {} 
                | DIV {}
                ;

rel_op:        EQQ {}
                | DIFF {}
                | LESS_EQ {}
                | LESS {}
                | HIGHER_EQ {} 
                | HIGHER {}
                ;

logic_op:       AND {}
                | OR {}
                ;

print:          PRINT LEFT_PAREN print_output RIGHT_PAREN SC {}
                ;

print_output:   lit {}
                | ID {}
                | lit PLUS print_output {}
                ;

%%

int main (void) {
    return yyparse();
}

int yyerror (char *msg) {
	fprintf (stderr, "%d: %s at '%s'\n", yylineno, msg, yytext);
	return 0;
}