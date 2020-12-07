#include <stdio.h>
#include <stdbool.h>

int main(){
	int x=0;
loop_while_3:
	if(!(x<10)){
		goto end_loop_while_3;
	}
	printf("%d", x);
x=x+1;
	goto loop_while_3;
end_loop_while_3:
	return 0;
}

