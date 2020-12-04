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

  struct MetadataExpr {
    char* result_type;
    char* text;
  };

  struct MetadataArr {
    char* result_type;
    char* text;
    char* id;
  };

  int scope_count = 0;
  int symbol_count = 1;
  char* curr_decl_type;
  
  struct Symbol* temp_list[32];
  int temp_list_index = -1;
  
%}

%union {
	char  *sValue;  /* string value */
  
  struct MetadataExpr* mdValue;
  struct MetadataArr* mrrValue;
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
              selection_stmt if else iteration_stmt while do_while escape assign
              assign_stmt func_stmt exprs
              op math_op rel_op logic_op print print_output

%type<mdValue> expr_atom expr lit func_call arr_assign_content 
%type<mrrValue> arr_assign arr_access

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
                    if (lookup_in_scope(temp_list[i]->id, top()) == NULL) {
                      insert(symbol_count, temp_list[i]);
                      symbol_count++;  
                    } else {
                      char* temp = concatenate(2, temp_list[i]->id, " already declared in this scope");
                      yyerror(temp);
                      exit(0);
                    }
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
                | arr_assign { 
                  $$ = $1->text;
                  temp_list_index++;
                  struct Symbol* symbol = new_symbol();
                  symbol->id = $1->id;
                  symbol->scope = top();
                  temp_list[temp_list_index] = symbol;
                }
                ;

lit:            LIT_NUMBER {  
                  struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
                  metadata->result_type = "int";
                  metadata->text = $1;
                  $$ = metadata;
                }
                | LIT_DECIMAL { 
                  struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
                  metadata->result_type = "decimal";
                  metadata->text = $1;
                  $$ = metadata;
                } 
                | LIT_STRING { 
                  struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
                  metadata->result_type = "string";
                  metadata->text = $1;
                  $$ = metadata;
                }
                | LIT_CHAR { 
                  struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
                  metadata->result_type = "char";
                  metadata->text = $1;
                  $$ = metadata;
                }
                | LIT_BOOLEAN { 
                  struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
                  metadata->result_type = "bool";
                  metadata->text = $1;
                  $$ = metadata;
                }
                ;

func:           type ID {
                  if (lookup_in_scope($2, top()) == NULL) {
                    struct Symbol* symbol = new_symbol();
                    symbol->type = $1;
                    symbol->id = $2;
                    symbol->scope = top();
                    insert(symbol_count, symbol);
                    push(symbol_count);
                    symbol_count++;
                  } else {
                    char* temp = concatenate(2, $2, " already declared in this scope");
                    yyerror(temp);
                    exit(0);
                  }
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

if:             IF LEFT_PAREN expr { 
                  if (compatible_types($3->result_type, "bool") != 0) {
                    yyerror("if expression must be a condition (bool value)");
                    exit(0);
                  }
                } RIGHT_PAREN LEFT_BRACE { 
                  struct Symbol* symbol = new_symbol();
                  symbol->id = "if";
                  symbol->scope = top();
                  insert(symbol_count, symbol);
                  push(symbol_count);
                  symbol_count++;
                } stmts RIGHT_BRACE {
                  pop();
                }
                else { 
                  $$ = concatenate(8, "IF", "(", $3->text, ")", "{\n", $8, "}\n", $11); 
                }
                ;

else:           {} 
                | ELSE LEFT_BRACE {
                  struct Symbol* symbol = new_symbol();
                  symbol->id = "else";
                  symbol->scope = top();
                  insert(symbol_count, symbol);
                  push(symbol_count);
                  symbol_count++;
                } 
                stmts RIGHT_BRACE { 
                  pop();
                  $$ = concatenate(4, "ELSE", "{\n", $4, "}\n"); 
                }
                ;

iteration_stmt: while { $$ = $1; }
                | do_while { $$ = $1; }
                ;

while:          WHILE LEFT_PAREN expr RIGHT_PAREN LEFT_BRACE {
                  if (compatible_types($3->result_type, "bool") != 0) {
                    yyerror("while expression must be a condition (bool value)");
                    exit(0);
                  }
                  push(symbol_count);
                  symbol_count++;
                } stmts RIGHT_BRACE { 
                  $$ = concatenate(7, "WHILE", "(", $3->text, ")", "{\n", $7, "}\n");
                  pop();
                }
                ;

do_while:       DO LEFT_BRACE {
                  push(symbol_count);
                  symbol_count++;
                } stmts RIGHT_BRACE WHILE LEFT_PAREN expr RIGHT_PAREN SC {
                  if (compatible_types($8->result_type, "bool") != 0) {
                    yyerror("do-while expression must be a condition (bool value)");
                    exit(0);
                  }
                  $$ = concatenate(9, "DO", "{\n", $4, "}\n", "WHILE", "(", $8->text, ")", ";\n"); 
                  pop();
                }
                ;

escape:         BREAK SC { $$ = "BREAK;"; }
                | EXIT SC { $$ = "EXIT;"; }
                | RETURN expr SC {
                  struct Symbol* symbol = get(top());

                  if (compatible_types(symbol->type, $2->result_type) == 0) {
                    $$ = concatenate(3, "RETURN", $2->text, ";\n");
                    struct Symbol* symbol = new_symbol();
                    symbol->scope = top();
                    symbol->return_stmt = 1;
                    insert(symbol_count, symbol);
                    symbol_count++;
                  } else {
                    char* temp = concatenate(4, "uncompatible return type ", $2->result_type, " with ", symbol->type);
                    yyerror(temp);
                    exit(0);
                  }
                }
                | RETURN SC {
                  struct Symbol* symbol = get(top());

                  if (compatible_types(symbol->type, "void") == 0) {
                    $$ = concatenate(2, "RETURN", ";\n");
                    struct Symbol* symbol = new_symbol();
                    symbol->scope = top();
                    symbol->return_stmt = 1;
                    insert(symbol_count, symbol);
                    symbol_count++;
                  } else {
                    char* temp = concatenate(2, "uncompatible return type void with ", symbol->type);
                    yyerror(temp);
                    exit(0);
                  }
                }
                ;

assign:         ID ASSIGN expr { 
                  struct Symbol* symbol = lookup($1);

                  if (symbol == NULL) {
                    yyerror("array id was not found");
                    free($3);
                    exit(0);
                  } else {
                    if(compatible_types(symbol->type, $3->result_type) == 0) {
                      $$ = concatenate(3, $1, "=", $3->text);
                    } else {
                      yyerror("variable type does not correspond to assigned expression");
                      free($3);
                      exit(0);
                    }
                  } 
                }
                | arr_access ASSIGN expr { 
                  struct Symbol* symbol = lookup($1->id);

                  if (symbol == NULL) {
                    yyerror("array id was not found");
                    free($1);
                    exit(0);
                  } else {
                    if(compatible_types(symbol->type, concatenate(2,"array", $3->result_type)) == 0) {
                      $$ = concatenate(3, $1->text, "=", $3->text);
                    } else {
                      yyerror("array type does not correspond to assigned literal");
                      free($1);
                      exit(0);
                    }
                  }
                }
                | arr_assign { 
                  struct Symbol* symbol = lookup($1->id);

                  if (symbol == NULL) {
                    yyerror("array id was not found");
                    free($1);
                    exit(0);
                  } else {
                    if(compatible_types(symbol->type, $1->result_type) == 0) {
                      $$ = $1->text;
                    } else {
                      yyerror("array type does not correspond to assigned literal");
                      free($1);
                      exit(0);
                    }
                  }
                }
                ;

arr_assign:     ID ASSIGN LEFT_BRACKET arr_assign_content RIGHT_BRACKET {
                  struct MetadataArr* metadata = (struct MetadataArr*) malloc(sizeof(struct MetadataArr));
                  metadata->id = $1;
                  metadata->result_type = concatenate(2, "array", $4->result_type);
                  metadata->text = concatenate(5, $1, "=", "[", $4->text, "]");
                  $$ = metadata;
                  free($4);
                }
                | ID ASSIGN type LEFT_PAREN LIT_NUMBER RIGHT_PAREN {
                  struct MetadataArr* metadata = (struct MetadataArr*) malloc(sizeof(struct MetadataArr));
                  metadata->id = $1;
                  metadata->result_type = concatenate(2, "array", $3);
                  metadata->text = concatenate(6, $1, "=", $3, "(", $5, ")");
                  $$ = metadata;
                }
                ;

arr_assign_content: expr { 
                      $$ = $1; 
                    }
                    | expr CMM arr_assign_content { 
                      if (compatible_types($1->result_type, $3->result_type) == 0) {
                        struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
                        metadata->text = concatenate(3, $1->text, ",", $3->text);
                        metadata->result_type = $1->result_type;
                        $$ = metadata;
                        free($1);
                        free($3);
                      } else {
                        yyerror("uncompatible types in array assign");
                        free($1);
                        free($3);
                        exit(0);
                      }
                    }
                    ;

assign_stmt:    assign SC { $$ = concatenate(2, $1, ";\n"); }
                ;

expr:           expr_atom op expr {
                  if (compatible_types($1->result_type, $3->result_type) == 0) {
                    // TODO TEXT TO C SIMPLIFIED
                    char* temp = concatenate(3, $1->text, $2, $3->text);
                    struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
                    metadata->text = temp;
                    metadata->result_type = result_type($1->result_type, $3->result_type);
                    $$ = metadata;
                    free($1);
                    free($3);
                  } else {
                    char* temp = concatenate(4, "uncompatible types ", $1->result_type, " and ", $3->result_type);
                    yyerror(temp);
                    free($1);
                    free($3);
                    exit(0);
                  }
                }
                | NOT expr { 
                  if (compatible_types($2->result_type, "bool") == 0) {
                    // TODO TEXT TO C SIMPLIFIED
                    char* temp = concatenate(2, "!", $2->text);
                    struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
                    metadata->text = temp;
                    metadata->result_type = $2->result_type;
                    $$ = metadata;
                    free($2);
                  } else {
                    char* temp = concatenate(2, "cannot use ! operand with ", $2->result_type);
                    yyerror(temp);
                    free($2);
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
                    struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
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
                  // TODO
                }
                | LEFT_PAREN expr RIGHT_PAREN {  
                  $2->text = concatenate(3, "(", $2->text, ")");
                  $$ = $2;
                }
                ;

func_call:      ID LEFT_PAREN RIGHT_PAREN { 
                  struct Symbol* symbol = lookup($1);
                  
                  if (symbol != NULL) {
                    struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
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
                    struct MetadataExpr* metadata = (struct MetadataExpr*) malloc(sizeof(struct MetadataExpr));
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

arr_access:     ID LEFT_BRACKET expr RIGHT_BRACKET {
                  if (compatible_types($3->result_type, "int") == 0) {
                    struct MetadataArr* metadata = (struct MetadataArr*) malloc(sizeof(struct MetadataArr));
                    metadata->id = $1;
                    metadata->text = concatenate(4, $1, "[", $3->text, "]");
                    $$ = metadata;
                    free($3);
                  } else {
                    yyerror("array access must be an integer expression");
                    free($3);
                    exit(0);
                  }
                  
                }
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

rel_op:         EQQ { $$ = "=="; }
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
	fprintf (stderr, "line %d: %s at '%s'\n", yylineno, msg, yytext);
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