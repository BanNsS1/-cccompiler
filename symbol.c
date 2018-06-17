#include "global.h"
#define MAX_SYMBOLS 512


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
	//for(i = nextIndex-1; i >= 0; i--){
		if(strcmp(symbols[i].lexptr, s) == 0){
			return &symbols[i];
		}else{
		}
	}
	
	return NULL;
}

Symbol *insert(const char *s, int token)
{
	if(nextIndex >= MAX_SYMBOLS){
		char error_msg[256];
		sprintf(error_msg, "Cannot allocate more than %d symbols", MAX_SYMBOLS);
		error(error_msg);
	}
	symbols[nextIndex].token = token;
	symbols[nextIndex].lexptr = strdup(s);	/*	Fixing segmentation fault problem */
	
	nextIndex++;
	return &symbols[nextIndex-1];
}
