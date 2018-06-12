#include "global.h"
#define MAX_SYMBOLS 512
#define MAX_LENGTH 1024


/*
Symbol defined at global.h
{
	const char *lexptr;
	int  token;
	int  localvar;		not needed any longer
}
*/

Symbol symbols[MAX_SYMBOLS];
int nextIndex = 0;


Symbol *lookup(const char *s)
{
	int i;
	for(i = 0; i < nextIndex; i++){
		if(strcmp(symbols[i], s) == 0)
			return symbols[i];
	}

	//Error: Couldn't find that symbol.
	return NULL;
}

Symbol *insert(const char *s, int token)
{
	if(strlen(s) > MAX_LENGTH){
		//Error: Cannot allocate more than MAX_SYMBOLS symbols.
	}
	
	symbols[nextIndex].token = token;
	symbols[nextIndex].lexptr = malloc(strlen(s) * sizeof(char))
	strcpy(symbols[nextIndex].lexptr, s);

	nextIndex++;
	return symbols[nextIndex-1];
}
