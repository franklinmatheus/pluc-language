#include <stdio.h>
#include <string.h>

#define SIZE 256
#define CAPACITY 32

struct Symbol {
    char* type; /* yacc constants */
    char* id;
    int scope; /* structure/func key */
    
    char* text;

    unsigned short return_stmt;
};

struct HashItem {
    int key;
    struct Symbol* symbol;
};

/*
 * key(int) -> data(symbol)
 */
struct HashItem* hash_table[SIZE];

/*
 * stack of scopes (int)
 * pointer tells the last scope
 */
int stack[CAPACITY];
int pointer = 0;

void push(int __key) {
    if (pointer < CAPACITY)
        stack[pointer++] = __key;
}

void pop(void) {
    pointer -= 1;
}

int top(void) {
    return stack[pointer-1];
}

int previous(int __key) {
    for (int i = 1; i < pointer; ++i) 
        if (stack[i] == __key)
            return stack[i-1];
    return -1;
}

int hash_code(int __key) {
    return __key % SIZE;
}

struct Symbol* new_symbol() {
    struct Symbol* symbol = (struct Symbol*) malloc(sizeof(struct Symbol));
    symbol->type = "";
    symbol->id = "";
    symbol->scope = -1;
    symbol->text = "";
    symbol->return_stmt = 0;
    return symbol;
}

struct Symbol* lookup(char* __id) {
    unsigned short stop = 0;
    int scope = top();
    do {
        for(int i = 1; i < SIZE; ++i) {
            if (hash_table[i] == NULL) break;
            
            if(strcmp(__id, hash_table[i]->symbol->id) == 0 && hash_table[i]->symbol->scope == scope) 
                return hash_table[i]->symbol;
        }
        scope = previous(scope);

        if(scope = -1) stop = 1;

    } while (stop = 0);

    return NULL;
}

void insert(int __key, struct Symbol* __symbol) {
    struct HashItem* item = (struct HashItem*) malloc(sizeof(struct HashItem));
    item->key = __key;
    item->symbol = __symbol;

    int hash_index = hash_code(__key);

    while(hash_table[hash_index] != NULL && hash_table[hash_index]->key != -1) {
        hash_index++;
        hash_index %= SIZE;
    }
    
    hash_table[hash_index] = item;
}

void display(void) {
    for (int i = 1; i < SIZE; ++i) {
        if (hash_table[i] != NULL) {
            printf("#### symbol #%d ####\n", hash_table[i]->key);
            printf("\ttype %s\n", hash_table[i]->symbol->type);
            printf("\tid %s\n", hash_table[i]->symbol->id);
            printf("\tscope %d\n", hash_table[i]->symbol->scope);
            printf("\treturn %d\n", hash_table[i]->symbol->return_stmt);
        }
    }
}

// returns 0 when types are compatible
int compatible_types(char* __lhs, char* __rhs) {
    return strcmp(__lhs, __rhs);
}

//for now, compatible types must be equals, so just returns one of them
char* result_type(char* __lhs, char* __rhs) {
    return __lhs;
}