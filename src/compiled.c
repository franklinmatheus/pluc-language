#include <stdio.h>
#include <stdbool.h>

void sub(decimal x, decimal y, int c){
	int result=((x*x)-y)+(double) c;
	printf("%d", result);
}

int main(){
	int c=3;
	decimal x=1.2, y=3.2;
	sub(x,y,c);
	return 0;
A}

