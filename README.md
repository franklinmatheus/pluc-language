# Pluc Language
## A C-based programming language
### Usage
Run lex in .l file
```
$ flex lexer.l
```

Compile lex.yy.c generated on last step
```
 $ gcc lex.yy.c -ll (or -lfl)
 ```

Execute output file providing a file to test passing to input in command line, like the example below:
```
$ ./a.out example.plc
```