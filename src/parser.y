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

  struct MetadataArr {
    char* result_type;
    char* text;
    char* id;
  };

  struct MetadataRtn {
    char* text;
    int has_return;
  };

  int scope_count = 0;
  int symbol_count = 1;
  char* curr_decl_type;
  
  struct Symbol* temp_list[32];

  struct Symbol* curr_call_func;
  int curr_param_func = 0;

  int temp_list_index = -1;

  int curr_func = -1;  
%}

%union {
	char  *sValue;  /* string value */
  
  struct Metadata* mdValue;
  struct MetadataArr* mrrValue;
  struct MetadataRtn* rtnValue;
 };

%start program

%token<sValue> ID LIT_STRING LIT_CHAR LIT_BOOLEAN LIT_NUMBER LIT_DECIMAL 

%token READ PRINT
%token VOID INT DECIMAL CHAR STRING BOOL ARRAY SET
%token IF ELSE WHILE DO
%token RETURN BREAK EXIT
%token SC CMM LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE
%token ASSIGN PLUS MINUS DIV TIMES
%token EQQ DIFF LESS_EQ LESS HIGHER_EQ HIGHER
%token AND OR NOT

%left	PLUS	MINUS
%left	TIMES	DIV

%type<sValue> sections section decl type var_decls var_decl func func_params params param 
              assign assign_stmt func_stmt exprs math_op rel_op logic_op print

%type<mdValue> expr_atom expr lit func_call arr_assign_content read print_output op
%type<mrrValue> arr_assign arr_access
%type<rtnValue> escape if else selection_stmt stmts stmt iteration_stmt while do_while

%nonassoc REDUCE
%nonassoc ELSE

%%

program:        sections { 
                  display();

                  FILE *file_output;

                  file_output = fopen("compiled.c", "w");

                  if (file_output == NULL) {
                      printf("error!");
                      exit(0);
                  }
                  
                  // add includes to result code
                  // #include <stdio>
                  fprintf(file_output, "%s\n", "#include <stdio.h>");
                  // #include <stdbool>
                  fprintf(file_output, "%s\n", "#include <stdbool.h>");
                  fprintf(file_output, "\n");

                  // simplified c
                  fprintf(file_output, "%s", $1);

                  fclose(file_output);
                }
                ;

sections:       section { $$ = $1; }
                | section sections {
                  $$ = concatenate(2, $1, $2);
                }
                ;

section:        decl { $$ = $1; }
                | func { $$ = $1; }
                ;

decl:           type var_decls SC { 
                  $$ = concatenate(4, "\t", $1, $2, ";\n");
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
                  $$ = concatenate(2, " ", $1);
                  temp_list_index++;
                  struct Symbol* symbol = new_symbol();
                  symbol->id = $1;
                  symbol->scope = top();
                  temp_list[temp_list_index] = symbol;
                }
                | ID ASSIGN expr { 
                  $$ = concatenate(4, " ", $1, "=", $3->text);
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
                  if (lookup_in_scope($2, top()) == NULL) {
                    struct Symbol* symbol = new_symbol();
                    symbol->type = $1;
                    symbol->id = $2;
                    symbol->scope = top();
                    insert(symbol_count, symbol);
                    push(symbol_count);
                    curr_func = symbol_count;
                    symbol_count++;
                  } else {
                    char* temp = concatenate(2, $2, " already declared in this scope");
                    yyerror(temp);
                    exit(0);
                  }
                } LEFT_PAREN func_params RIGHT_PAREN LEFT_BRACE stmts RIGHT_BRACE {
                  if ($8->has_return == 0 && strcmp($1, "void") != 0) {
                    yyerror("function requires return statement");
                    exit(0);
                  }
                  $$ = concatenate(9, $1, " ", $2, "(", $5, ")", "{\n", $8->text, "}\n\n");
                  curr_func = -1;
                  pop();
                }
                ;

func_params:    { $$ = ""; }
                | params { $$ = $1; }
                | VOID { $$ = "void"; }
                ;

params:         param { $$ = $1; }
                | param CMM params { $$ = concatenate(3, $1, ", ", $3); }
                ;

param:          type ID { 
                  $$ = concatenate(3, $1, " ", $2);
                  struct Symbol* symbol = new_symbol();
                  symbol->type = $1;
                  symbol->id = $2;
                  symbol->scope = top();
                  insert_func_param(top(), $1);

                  insert(symbol_count, symbol);
                  symbol_count++;
                }
                ;

stmts:          stmt { 
                  $$ = $1; 
                }
                | stmt stmts { 
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = concatenate(2, $1->text, $2->text);
                  
                  if ($1->has_return == 1 || $2->has_return == 1)
                    metadata->has_return = 1;
                  else
                    metadata->has_return = 0;

                  $$ = metadata;
                  free($1);
                  free($2);
                }
                ;

stmt:           selection_stmt { 
                  $$ = $1; 
                }
                | iteration_stmt { 
                  $$ = $1; 
                }
                | escape { 
                  $$ = $1; 
                }
                | decl {
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = $1;
                  metadata->has_return = 0;
                  $$ = metadata;
                }
                | print { 
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = $1;
                  metadata->has_return = 0;
                  $$ = metadata;
                }
                | func_stmt { 
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = $1;
                  metadata->has_return = 0;
                  $$ = metadata;
                }
                | assign_stmt { 
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = $1;
                  metadata->has_return = 0;
                  $$ = metadata;
                } 
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
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = concatenate(8, "\tif ", "(", $3->text, ")", "\t{\n\t\t", $8->text, "\t}\n", $11->text);
                  if ($8->has_return == 1 && $11->has_return == 1) {
                    metadata->has_return = 1;
                  } else {
                    metadata->has_return = 0;
                  }
                  $$ = metadata;
                }
                ;

else:           {
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = ""; 
                  metadata->has_return = 0;
                  $$ = metadata;
                } 
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
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = concatenate(4, "\telse ", "{\n\t\t", $4->text, "\t}\n");
                  metadata->has_return = $4->has_return;
                  $$ = metadata;
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
                  struct Symbol* symbol = new_symbol();
                  symbol->id = "while";
                  symbol->scope = top();
                  insert(symbol_count, symbol);
                  push(symbol_count);
                  symbol_count++;
                } stmts RIGHT_BRACE {
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));

                  // create identifiers
                  int identifier = top();
                  char identifier_s[20];
                  char loop_id[30] = "loop_while_";
                  char loop_end_id[30] = "end_loop_while_";

                  // copy scope id to strings of init and out of while loop
                  sprintf(identifier_s, "%d", identifier); 
                  strcat(loop_id, identifier_s);
                  strcat(loop_end_id, identifier_s);

                  metadata->text = concatenate(17, loop_id, ":\n", "\tif(!(", $3->text, "))", "{\n\t", "\tgoto", " ", loop_end_id, ";\n\t}\n", $7->text, "\tgoto", " ", loop_id, ";\n", loop_end_id, ":\n");

                  metadata->has_return = $7->has_return;
                  $$ = metadata;
                  pop();
                }
                ;

do_while:       DO LEFT_BRACE {
                  struct Symbol* symbol = new_symbol();
                  symbol->id = "do_while";
                  symbol->scope = top();
                  insert(symbol_count, symbol);
                  push(symbol_count);
                  symbol_count++;
                } stmts RIGHT_BRACE WHILE LEFT_PAREN expr RIGHT_PAREN SC {
                  if (compatible_types($8->result_type, "bool") != 0) {
                    yyerror("do-while expression must be a condition (bool value)");
                    exit(0);
                  }
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));

                  // create identifiers
                  int identifier = top();
                  char identifier_s[20];
                  char loop_id[30] = "loop_do_while_";
                  char loop_end_id[30] = "end_loop_do_while_";

                  // copy scope id to strings of init and out of while loop
                  sprintf(identifier_s, "%d", identifier); 
                  strcat(loop_id, identifier_s);
                  strcat(loop_end_id, identifier_s);

                  metadata->text = concatenate(17, loop_id, ":\n", $4->text,"\tif(!(", $8->text, "))", "{\n\t", "\tgoto", " ", loop_end_id, ";\n\t}\n", "\tgoto", " ", loop_id, ";\n", loop_end_id, ":\n");
                  metadata->has_return = $4->has_return;
                  $$ = metadata;
                  pop();
                }
                ;

escape:         BREAK SC { 
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = "break;";
                  metadata->has_return = 0;
                  $$ = metadata;
                }
                | EXIT SC { 
                  struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                  metadata->text = "exit;";
                  metadata->has_return = 0;
                  $$ = metadata;
                }
                | RETURN expr SC {
                  struct Symbol* symbol = get(curr_func);

                  if (compatible_types(symbol->type, $2->result_type) == 0) {
                    struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                    metadata->text = concatenate(3, "\treturn ", $2->text, ";\n");
                    metadata->has_return = 1;
                    $$ = metadata;
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
                  struct Symbol* symbol = get(curr_func);

                  if (compatible_types(symbol->type, "void") == 0) {
                    struct MetadataRtn* metadata = (struct MetadataRtn*) malloc(sizeof(struct MetadataRtn));
                    metadata->text = concatenate(2, "return", ";\n");;
                    metadata->has_return = 1;
                    $$ = metadata;
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
                | ID ASSIGN read {
                  struct Symbol* symbol = lookup($1);

                  if (compatible_types(symbol->type, $3->result_type) == 0) {
                    char* temp = "\%d";
                    if (compatible_types(symbol->type, "string") == 0) 
                      temp = "\%s";
                    $$ = concatenate(5, "scanf(\"", temp, "\", &", $1, ")");
                  } else {
                    yyerror("uncompatible read type");
                    exit(0);
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
                        struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
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
                    char* temp = concatenate(3, $1->text, $2->text, $3->text);
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->text = temp;
                    metadata->result_type = result_type($1->result_type, $3->result_type);

                    if (strcmp($2->result_type, "logic") == 0) {
                      if (strcmp($1->result_type, "bool") != 0) {
                        yyerror("logic operation requires boolean expressions");
                        free($1);
                        free($2);
                        free($3);
                        exit(0);
                      }
                    } else if(strcmp($2->result_type, "rel") == 0) {
                      if (strcmp($1->result_type, "int") != 0 && strcmp($1->result_type, "decimal") != 0) {
                        yyerror("rel operation requires int or decimal expressions");
                        free($1);
                        free($2);
                        free($3);
                        exit(0);
                      } else {
                        metadata->result_type = "bool";
                      }
                    } else if (strcmp($2->result_type, "math") == 0) {
                      if (strcmp($1->result_type, "int") != 0 && strcmp($1->result_type, "decimal") != 0) {
                        yyerror("math operation requires int or decimal expressions");
                        free($1);
                        free($2);
                        free($3);
                        exit(0);
                      }
                    }
                    
                    $$ = metadata;
                    free($1);
                    free($2);
                    free($3);
                  } else {
                    char* temp = concatenate(4, "uncompatible types ", $1->result_type, " and ", $3->result_type);
                    yyerror(temp);
                    free($1);
                    free($2);
                    free($3);
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
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->text = $1;
                    metadata->result_type = symbol->type;
                    $$ = metadata;
                  } else {
                    yyerror("unknown id");
                    exit(0);
                  }
                }
                | LEFT_PAREN type RIGHT_PAREN ID {
                  struct Symbol* symbol = lookup($4);

                  if(symbol == NULL) {
                    yyerror("id was not found");
                    exit(0);
                  }
                  
                  if (strcmp($2, "decimal") == 0 && strcmp(symbol->type, "int") == 0) {
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->text = concatenate(2, "(double) ", $4);
                    metadata->result_type = "decimal";
                    $$ = metadata;
                  } else if (strcmp($2, "int") == 0 && strcmp(symbol->type, "decimal") == 0) {
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->text = concatenate(2, "(int) ", $4);
                    metadata->result_type = "int";
                    $$ = metadata;
                  } else if (strcmp($2, symbol->type) == 0) {
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->text = concatenate(4, "(", $2, ") ", $4);
                    metadata->result_type = $2;
                    $$ = metadata;
                  } else {
                    yyerror("unable to cast variable to this type");
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
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->text = $1->text;
                  metadata->result_type = $1->result_type;
                  $$ = metadata;
                  free($1);
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
                | ID LEFT_PAREN {
                  curr_call_func = lookup($1);

                  if (curr_call_func == NULL) {
                    yyerror("function not found");
                    exit(0);
                  }
                  curr_param_func = curr_call_func->n_params - 1;
                } exprs RIGHT_PAREN { 
                  if (curr_param_func != -1) {
                    yyerror("wrong number of params in function call");
                    exit(0);
                  } else
                    curr_param_func = 0;

                  struct Symbol* symbol = lookup($1);
                  
                  if (symbol != NULL) {
                    // TODO CHECK PARAMS
                    struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                    metadata->result_type = symbol->type;

                    // TODO: TEXT TO C SIMPLIFIED
                    // TODO: check whether has a scope
                    char* temp;
                    if(top())
                      temp = concatenate(5, "\t", $1, "(", $4, ")");
                    else 
                      temp = concatenate(4, $1, "(", $4, ");");

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

exprs:          expr {
                  if (strcmp(curr_call_func->param_type[curr_param_func], $1->result_type) != 0) {
                    char* temp = concatenate(4, curr_call_func->param_type[curr_param_func], " and ", $1->result_type, " are not compatible in function call");
                    yyerror(temp);
                    free(temp);
                    exit(0);
                  }
                  $$ = $1->text;
                  curr_param_func--;
                }
                | expr CMM exprs {
                  if (curr_param_func < 0) {
                    yyerror("too many params in call func");
                    exit(0);
                  } else
                    if (strcmp(curr_call_func->param_type[curr_param_func], $1->result_type) != 0) {
                      char* temp = concatenate(4, curr_call_func->param_type[curr_param_func], " and ", $1->result_type, " are not compatible in function call");
                      yyerror(temp);
                      free(temp);
                      exit(0);
                    }
                  curr_param_func--;
                  $$ = concatenate(3, $1->text, ",", $3);
                }
                ;

arr_access:     ID LEFT_BRACKET expr RIGHT_BRACKET {
                  if (compatible_types($3->result_type, "int") == 0) {
                    struct MetadataArr* metadata = (struct MetadataArr*) malloc(sizeof(struct MetadataArr));
                    metadata->id = $1;
                    struct Symbol* symbol = lookup($1);

                    if (symbol == NULL) {
                      yyerror("array id was not found");
                      exit(0);
                    }

                    char* temp = symbol->type;
                    temp += 5;
                    metadata->result_type = temp;
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

op:             math_op { 
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->text = $1;
                  metadata->result_type = "math"; 
                  $$ = metadata;
                }
                | rel_op { 
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->text = $1;
                  metadata->result_type = "rel";
                  $$ = metadata;
                }
                | logic_op { 
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->text = $1;
                  metadata->result_type = "logic";
                  $$ = metadata;
                }
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

read:           READ LEFT_PAREN type RIGHT_PAREN { 
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->result_type = $3;
                  metadata->text = "";
                  $$ = metadata;
                }
                ;

print:          PRINT LEFT_PAREN print_output RIGHT_PAREN SC { 
                  char* temp = "\%d";
                  if (compatible_types($3->result_type, "string") == 0)  
                    temp = "\%s";

                  $$ = concatenate(6, "\t","printf(\"", temp, "\", ", $3->text, ");\n");
                }
                ;

print_output:   lit {
                  $$ = $1;
                }
                | ID { 
                  struct Symbol* symbol = lookup($1);

                  if (symbol == NULL) {
                    yyerror("id was not found");
                    exit(0);
                  }
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->text = $1;
                  metadata->result_type = symbol->type;
                  $$ = metadata;
                }
                | arr_access {
                  struct Metadata* metadata = (struct Metadata*) malloc(sizeof(struct Metadata));
                  metadata->text = $1->text;
                  metadata->result_type = $1->result_type;
                  $$ = metadata;
                  free($1);
                }
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