%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <stdarg.h>

  int yylex();
  int yyerror(char *s);
  extern int yylineno;
  extern char * yytext;

  char* concatenate(int quantity, ...);
%}

%union {
  int    iValue; 	/* integer value */
	char   cValue; 	/* char value */
	char  *sValue;  /* string value */
  double dValue;  /* decimal value */
 };

%start program

%token<sValue> ID
%token<sValue> LIT_STRING
%token<cValue> LIT_CHAR
%token<sValue> LIT_BOOLEAN
%token<iValue> LIT_NUMBER
%token<dValue> LIT_DECIMAL 

%token<sValue> PRINT
%token<sValue> VOID SHORT INT LONG FLOAT DOUBLE CHAR STRING BOOL ARRAY SET
%token<sValue> IF ELSE WHILE DO
%token<sValue> RETURN BREAK EXIT
%token<sValue> SC CMM LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE
%token<sValue> ASSIGN PLUS MINUS DIV TIMES
%token<sValue> EQQ DIFF LESS_EQ LESS HIGHER_EQ HIGHER
%token<sValue> AND OR NOT

%left	PLUS	MINUS
%left	TIMES	DIV

%type<sValue> section decl type var_decls var_decl lit func func_params params param stmts stmt
              selection_stmt if else iteration_stmt while do_while escape assign arr_assign
              arr_assign_content assign_stmt expr expr_atom func_call func_stmt exprs arr_access
              op math_op rel_op logic_op print print_output


%%

program:        sections {}
                ;

sections:       section {}
                | section sections {}
                ;

section:        decl { printf($$); }
                | func { printf($$); }
                ;

decl:           type var_decls SC { $$ = concatenate(3, $1, $2, ";\n"); }
                ;

type:           INT { $$ = "INT"; }
                | FLOAT { $$ = "FLOAT"; }
                | DOUBLE { $$ = "DOUBLE"; }
                | CHAR { $$ = "CHAR"; }
                | STRING { $$ = "STRING"; }
                | BOOL { $$ = "BOOL"; }
                | VOID { $$ = "VOID"; }
                | SHORT { $$ = "SHORT"; }
                | LONG { $$ = "LONG"; }
                | SET type { $$ = concatenate(2, "SET", $2); }
                | ARRAY type { $$ = concatenate(2, "ARRAY", $2); }
                ;

var_decls:      var_decl { $$ = $1; }
                | var_decl CMM var_decls { $$ = concatenate(3, $1, ",", $3); }
                ;

var_decl:       ID { $$ = $1; }
                | assign { $$ = $1; }
                ;

lit:            LIT_NUMBER { $$ = "LIT_NUMBER"; }
                | LIT_DECIMAL { $$ = "LIT_DECIMAL"; } 
                | LIT_STRING { $$ = "LIT_STRING"; }
                | LIT_CHAR { $$ = "LIT_CHAR"; }
                | LIT_BOOLEAN { $$ = "LIT_BOOLEAN"; }
                ;

func:           type ID LEFT_PAREN func_params RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE { $$ = concatenate(8, $1, $2, "(", $4, ")", "{\n", $7, "}\n"); }
                ;

func_params:    %empty { $$ = ""; }
                | params { $$ = $1; }
                | VOID { $$ = $1; }
                ;

params:         param { $$ = $1; }
                | param CMM params { $$ = concatenate(3, $1, ",", $3); }
                ;

param:          type ID { $$ = concatenate(2, $1, $2); }
                ;

stmts:          stmt { $$ = $1; }
                | stmt stmts { $$ = concatenate(2, $1, $2); }
                ;

stmt:           selection_stmt { $$ = $1; }
                | iteration_stmt { $$ = $1; }
                | escape { $$ = $1; }
                | decl { $$ = $1; }
                | print { $$ = $1; }
                | func_stmt { $$ = $1; }
                | assign_stmt { $$ = $1; } 
                ;

selection_stmt: if { $$ = $1; }
                ;

if:             IF LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE { $$ = concatenate(7, "IF", "(", $3, ")", "{\n", $6, "}\n"); }
                | IF LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE else { $$ = concatenate(8, "IF", "(", $3, ")", "{\n", $6, "}\n", $8); }
                ;

else:           ELSE LEFT_BRACE stmts RIGHT_BRACE { $$ = concatenate(4, "ELSE", "{\n", $3, "}\n"); }
                ;

iteration_stmt: while { $$ = $1; }
                | do_while { $$ = $1; }
                ;

while:          WHILE LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE { $$ = concatenate(7, "WHILE", "(", $3, ")", "{\n", $6, "}\n"); }
                ;

do_while:        DO LEFT_BRACE stmts RIGHT_BRACE WHILE LEFT_PAREN expr RIGHT_PAREN SC { $$ = concatenate(9, "DO", "{\n", $3, "}\n", "WHILE", "(", $7, ")", ";\n"); }
                ;

escape:         BREAK SC { $$ = "BREAK;"; }
                | EXIT SC { $$ = "EXIT;"; }
                | RETURN expr SC { $$ = concatenate(3, "RETURN", $2, ";\n"); }
                ;

assign:         ID ASSIGN expr { $$ = concatenate(3, $1, "=", $3); }
                | arr_access ASSIGN expr { $$ = concatenate(3, $1, "=", $3); }
                | arr_assign { $$ = $1; }
                ;

arr_assign:     ID ASSIGN LEFT_BRACKET arr_assign_content RIGHT_BRACKET { $$ = concatenate(5, $1, "=", "[", $4, "]"); }
                | ID ASSIGN type LEFT_PAREN LIT_NUMBER RIGHT_PAREN { $$ = concatenate(6, $1, "=", $3, "(", "LIT_NUMBER", ")"); }
                ;

arr_assign_content: expr { $$ = $1; }
                    | expr CMM arr_assign_content { $$ = concatenate(3, $1, ",", $3); }
                    ;

assign_stmt:    assign SC { $$ = concatenate(2, $1, ";\n"); }
                ;

expr:           expr_atom op expr { $$ = concatenate(3, $1, $2, $3); }
                | NOT expr { $$ = concatenate(2, "!", $2); }
                | expr_atom { $$ = $1; }
                ; 

expr_atom:      ID { $$ = $1; }
                | lit { $$ = $1; }
                | func_call { $$ = $1; }
                | arr_access { $$ = $1; }
                | LEFT_PAREN expr RIGHT_PAREN { $$ = concatenate(3, "(", $2, ")"); }
                ;

func_call:      ID LEFT_PAREN RIGHT_PAREN { $$ = concatenate(3, $1, "(", ")"); }
                | ID LEFT_PAREN exprs RIGHT_PAREN { $$ = concatenate(4, $1, "(", $3, ")"); }
                ;

func_stmt:      func_call SC { $$ = concatenate(2, $1, ";\n"); }
                ;

exprs:          expr { $$ = $1; }
                | expr CMM exprs { $$ = concatenate(3, $1, ",", $3); }
                ;

arr_access:      ID LEFT_BRACKET expr RIGHT_BRACKET { $$ = concatenate(4, $1, "[", $3, "]"); }
                ;

op:             math_op { $$ = $1; }
                | rel_op { $$ = $1; }
                | logic_op { $$ = $1; }
                ;

math_op:        PLUS { $$ = "+"; }
                | MINUS { $$ = "-"; }
                | TIMES { $$ = "*"; }
                | DIV { $$ = "/"; }
                ;

rel_op:        EQQ { $$ = "=="; }
                | DIFF { $$ = "!="; }
                | LESS_EQ { $$ = "<="; }
                | LESS { $$ = "<"; }
                | HIGHER_EQ { $$ = ">="; } 
                | HIGHER { $$ = ">"; }
                ;

logic_op:       AND { $$ = "&&"; }
                | OR { $$ = "||"; }
                ;

print:          PRINT LEFT_PAREN print_output RIGHT_PAREN SC { $$ = concatenate(5, "PRINT", "(", $3, ")", ";\n"); }
                ;

print_output:   lit { $$ = $1; }
                | ID { $$ = $1; }
                | lit PLUS print_output { $$ = concatenate(3, $1, "+", $3); }
                ;

%%

int main (void) {
    return yyparse();
}

int yyerror (char *msg) {
	fprintf (stderr, "%d: %s at '%s'\n", yylineno, msg, yytext);
	return 0;
}

char* concatenate(int quantity, ...) {
    va_list elements;
    /* Initialize valist for arguments quantity */
    va_start(elements, quantity);

    /* Access all elements to get the final string size */
    int result_length = 0;
    for (int i = 0; i < quantity; ++i)
      result_length += strlen(va_arg(elements, char*));

    /* Clean memory reserved for valist */
    va_end(elements);

    /* Reserves a memory space of the required size  */
    char* result = malloc(sizeof(char) * result_length);

    /* Finally, concatenates all strings in result */
    va_start(elements, quantity);
    int delimiter = 0;
    for (int i = 0; i < quantity; ++i) {
      char* source = va_arg(elements, char*);
      strcpy(result + delimiter, source);
      delimiter += strlen(source);
    }
    return result;
  }