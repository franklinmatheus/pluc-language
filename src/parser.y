%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <stdarg.h>

  #include "symboltable.c"

  int yylex();
  int yyerror(char *s);
  extern int yylineno;
  extern char * yytext;

  char* concatenate(int quantity, ...);

  struct Metadata {
    char* result_type;
    char* text;
  };

  int scope_count = 0;
  int symbol_count = 1;
  char* curr_decl_type;
  
  struct Symbol* temp_list[32];
  int temp_list_index = -1;
  
%}

%union {
	char  *sValue;  /* string value */
  
  struct Metadata* mdValue;
 };

%start program

%token<sValue> ID LIT_STRING LIT_CHAR LIT_BOOLEAN LIT_NUMBER LIT_DECIMAL 

%token PRINT
%token VOID INT DECIMAL CHAR STRING BOOL ARRAY SET
%token IF ELSE WHILE DO
%token RETURN BREAK EXIT
%token SC CMM LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE
%token ASSIGN PLUS MINUS DIV TIMES
%token EQQ DIFF LESS_EQ LESS HIGHER_EQ HIGHER
%token AND OR NOT

%left	PLUS	MINUS
%left	TIMES	DIV

%type<sValue> section decl type var_decls var_decl func func_params params param stmts stmt
              selection_stmt if else iteration_stmt while do_while escape assign arr_assign
              arr_assign_content assign_stmt func_stmt exprs arr_access
              op math_op rel_op logic_op print print_output

%type<mdValue> expr_atom expr lit func_call

%nonassoc REDUCE
%nonassoc ELSE

%%

program:        sections { display(); }
                ;

sections:       section {}
                | section sections {}
                ;

section:        decl { printf("%s", $$); }
                | func { printf("%s", $$); }
                ;

decl:           type var_decls SC { 
                  $$ = concatenate(3, $1, $2, ";\n");
                  for (int i = 0; i <= temp_list_index; ++i) {
                    temp_list[i]->type = $1;
                    insert(symbol_count, temp_list[i]);
                    symbol_count++;
                  }

                  temp_list_index = -1;
                }
                ;

type:           INT { $$ = "int"; }
                | DECIMAL { $$ = "decimal"; }
                | CHAR { $$ = "char"; }
                | STRING { $$ = "string"; }
                | BOOL { $$ = "bool"; }
                | VOID { $$ = "void"; }
                | SET type { $$ = concatenate(2, "set", $2); }
                | ARRAY type { $$ = concatenate(2, "array", $2); }
                ;

var_decls:      var_decl { $$ = $1; }
                | var_decl CMM var_decls { $$ = concatenate(3, $1, ",", $3); }
                ;

var_decl:       ID {
                  $$ = $1;
                  temp_list_index++;
                  struct Symbol* symbol = new_symbol();
                  symbol->id = $1;
                  symbol->scope = top();
                  temp_list[temp_list_index] = symbol;
                }
                | ID ASSIGN expr { 
                  $$ = $1;
                  temp_list_index++;
                  struct Symbol* symbol = new_symbol();
                  symbol->id = $1;
                  symbol->scope = top();
                  temp_list[temp_list_index] = symbol;
                }
                | arr_assign { $$ = $1; }
                ;

lit:            LIT_NUMBER {  
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->result_type = "int";
                  metadata->text = $1;
                  $$ = metadata;
                }
                | LIT_DECIMAL { 
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->result_type = "decimal";
                  metadata->text = $1;
                  $$ = metadata;
                } 
                | LIT_STRING { 
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->result_type = "string";
                  metadata->text = $1;
                  $$ = metadata;
                }
                | LIT_CHAR { 
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->result_type = "char";
                  metadata->text = $1;
                  $$ = metadata;
                }
                | LIT_BOOLEAN { 
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->result_type = "bool";
                  metadata->text = $1;
                  $$ = metadata;
                }
                ;

func:           type ID {
                  struct Symbol* symbol = new_symbol();
                  symbol->type = $1;
                  symbol->id = $2;
                  symbol->scope = top();
                  insert(symbol_count, symbol);
                  push(symbol_count);
                  symbol_count++;
                } LEFT_PAREN func_params RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {
                  $$ = concatenate(8, $1, $2, "(", $5, ")", "{\n", $8, "}\n");
                  pop();
                }
                ;

func_params:    { $$ = ""; }
                | params { $$ = $1; }
                | VOID { $$ = "VOID"; }
                ;

params:         param { $$ = $1; }
                | param CMM params { $$ = concatenate(3, $1, ",", $3); }
                ;

param:          type ID { 
                  $$ = concatenate(2, $1, $2);
                  struct Symbol* symbol = new_symbol();
                  symbol->type = $1;
                  symbol->id = $2;
                  symbol->scope = top();
                  insert(symbol_count, symbol);
                  symbol_count++;
                }
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

if:             IF LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE else { 
                  //$$ = concatenate(8, "IF", "(", $3, ")", "{\n", $6, "}\n", $8); 
                }
                |
                IF LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE { 
                  //$$ = concatenate(7, "IF", "(", $3, ")", "{\n", $6, "}\n"); 
                }
                ;

else:           ELSE LEFT_BRACE stmts RIGHT_BRACE { $$ = concatenate(4, "ELSE", "{\n", $3, "}\n"); }
                ;

iteration_stmt: while { $$ = $1; }
                | do_while { $$ = $1; }
                ;

while:          WHILE LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE { 
                  push(symbol_count);
                  symbol_count++;
                } stmts RIGHT_BRACE { 
                  $$ = concatenate(7, "WHILE", "(", $3->text, ")", "{\n", $7, "}\n"); 
                }
                ;

do_while:       DO LEFT_BRACE {
                  push(symbol_count);
                  symbol_count++;
                } stmts RIGHT_BRACE WHILE LEFT_PAREN expr RIGHT_PAREN SC { 
                  $$ = concatenate(9, "DO", "{\n", $4, "}\n", "WHILE", "(", $8->text, ")", ";\n"); 
                }
                ;

escape:         BREAK SC { $$ = "BREAK;"; }
                | EXIT SC { $$ = "EXIT;"; }
                | RETURN expr SC { 
                    $$ = concatenate(3, "RETURN", $2->text, ";\n");
                    struct Symbol* symbol = new_symbol();
                    symbol->scope = top();
                    symbol->return_stmt = 1;
                    insert(symbol_count, symbol);
                    symbol_count++;
                  }
                ;

assign:         ID ASSIGN expr { $$ = concatenate(3, $1, "=", $3->text); }
                | arr_access ASSIGN expr { $$ = concatenate(3, $1, "=", $3->text); }
                | arr_assign { $$ = $1; }
                ;

arr_assign:     ID ASSIGN LEFT_BRACKET arr_assign_content RIGHT_BRACKET {
                  $$ = concatenate(5, $1, "=", "[", $4, "]"); 
                }
                | ID ASSIGN type LEFT_PAREN LIT_NUMBER RIGHT_PAREN { 
                  $$ = concatenate(6, $1, "=", $3, "(", "LIT_NUMBER", ")"); 
                }
                ;

arr_assign_content: expr { $$ = $1->text; }
                    | expr CMM arr_assign_content { $$ = concatenate(3, $1->text, ",", $3); }
                    ;

assign_stmt:    assign SC { $$ = concatenate(2, $1, ";\n"); }
                ;

expr:           expr_atom op expr {
                  if (compatible_types($1->result_type, $3->result_type) == 0) {
                    // TODO TEXT TO C SIMPLIFIED
                    char* temp = concatenate(3, $1->text, $2, $3->text);
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->text = temp;
                    metadata->result_type = result_type($1->result_type, $3->result_type);
                    $$ = metadata;
                  } else {
                    char* temp = concatenate(4, "uncompatible types ", $1->result_type, " and ", $3->result_type);
                    yyerror(temp);
                    exit(0);
                  }
                }
                | NOT expr { 
                  if (compatible_types($2->result_type, "bool") == 0) {
                    // TODO TEXT TO C SIMPLIFIED
                    char* temp = concatenate(2, "!", $2->text);
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->text = temp;
                    metadata->result_type = $2->result_type;
                    $$ = metadata;
                  } else {
                    char* temp = concatenate(2, "cannot use ! operand with ", $2->result_type);
                    yyerror(temp);
                    exit(0);
                  }
                }
                | expr_atom {
                  $$ = $1;
                }
                ; 

expr_atom:      ID {
                  struct Symbol* symbol = lookup($1);
                  
                  if(symbol != NULL) {
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->text = $1;
                    metadata->result_type = symbol->type;
                    $$ = metadata;
                  } else {
                    yyerror("unknown id");
                    exit(0);
                  }
                }
                | lit { 
                  $$ = $1;
                }
                | func_call { 
                  $$ = $1;
                }
                | arr_access {  

                }
                | LEFT_PAREN expr RIGHT_PAREN {  
                  $2->text = concatenate(3, "(", $2->text, ")");
                  $$ = $2;
                }
                ;

func_call:      ID LEFT_PAREN RIGHT_PAREN { 
                  struct Symbol* symbol = lookup($1);
                  
                  if (symbol != NULL) {
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->result_type = symbol->type;

                    // TODO TEXT TO C SIMPLIFIED
                    char* temp = concatenate(3, $1, "(", ")");
                    metadata->text = temp;
                    $$ = metadata;
                  } else {
                    char* temp = concatenate(3, "function ", $1 , " not found");
                    yyerror(temp);
                    exit(0);
                  }
                }
                | ID LEFT_PAREN exprs RIGHT_PAREN { 
                  struct Symbol* symbol = lookup($1);
                  
                  if (symbol != NULL) {
                    // TODO CHECK PARAMS
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->result_type = symbol->type;

                    // TODO TEXT TO C SIMPLIFIED
                    char* temp = concatenate(4, $1, "(", $3, ")");
                    metadata->text = temp;
                    $$ = metadata;
                  } else {
                    char* temp = concatenate(3, "function ", $1 , " not found");
                    yyerror(temp);
                    exit(0);
                  }
                }
                ;

func_stmt:      func_call SC { $$ = concatenate(2, $1->text, ";\n"); }
                ;

exprs:          expr { $$ = $1->text; }
                | expr CMM exprs { $$ = concatenate(3, $1->text, ",", $3); }
                ;

arr_access:     ID LEFT_BRACKET expr RIGHT_BRACKET { $$ = concatenate(4, $1, "[", $3->text, "]"); }
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

print_output:   lit { $$ = $1->text; }
                | ID { $$ = $1; }
                | lit PLUS print_output { $$ = concatenate(3, $1->text, "+", $3); }
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