%{
  #include stdio.h
  #include stdlib.h
  #include string.h

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
	char  *sValue;  /* string value */
 };

%start program

%%

program:        sections {}

sections:       section {}
                | section sections {}

section:        decl {}
                | func {}

decl:           type var_decls SC {}

type:           group_type unit_type {}
                | unit_type {}

group_type:     SET {}
                | ARRAY {}

unit_type:      INT {}
                | FLOAT {}
                | DOUBLE {}
                | CHAR {}
                | STRING {}
                | BOOL {}
                | VOID {}

var_decls:      var_decl {}
                | var_decl CMM var_decls {}

var_decl:       ID {}
                | assign_lit {}

assign_lit:     ID ASSIGN lit {}
                | arr_acss EQ lit {}

lit:            NUMBER {}
                | DECIMAL {} 
                | STRING {}
                | CHAR {}
                | BOOL {}

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
                | switch {}

if:             if LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {}
                | if LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE else {}

else:           else LEFT_BRACE stmts RIGHT_BRACE {}

iteration_stmt: for {}
                | while {}
                | do_while {}

while:          while LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {}

escape:         break SC {}
                | exit SC {}
                | return expr SC {}

assign:         assign_lit {}
                | assign_expr {}

assign_expr:    ID EQ expr {}
                | arr_acss EQ expr {}

expr:           ID {}
                | lit {}
                | func_call {}
                | arr_acss {}
                | expr op expr {}
                | LEFT_PAREN expr op expr RIGHT_PAREN {}

func_call:      ID LEF_PAREN exprs RIGHT_PAREN {}

exprs:          expr {}
                | expr CMM exprs {}

arr_accss:      ID LEFT_BRACK expr RIGHT_BRACK {}

op:             math_op {}
                | comp_op {}
                | logic_op {}

math_op:        PLUS {}
                | MINUS {}
                | TIMES {} 
                | DIV {}

comp_op:        EQQ {}
                | DIFF {}
                | LSSEQ {}
                | LESS {}
                | HIGHEREQ {} 
                | HIGHER {}

logic_op:       AND {}
                | OR {}

print:          print LEFT_PAREN expr RIGHT_PAREN {}

%%

int main (void) {
    return yyparse();
}

int yyerror (char *msg) {
	fprintf (stderr, "%d: %s at '%s'\n", yylineno, msg, yytext);
	return 0;
}