#include "global.h"
/* Sharing variables between yacc and lex. Not using global.h to avoid unused warnings. */



/* Main file name */
char * main_file = (char *) malloc(sizeof(char *) * 256);

/* Included files name */
char * include_file_name[MAX_INCLUDE_DEPTH] = {(char *) malloc(sizeof(char *) * 256)};

/* Main file line counter */
int lineCounter = 1;

/* Included files line counter */
int include_line_counter[MAX_INCLUDE_DEPTH] = {1};

/* Include files stack pointer (index) */
int include_stack_ptr = -1;

/* Boolean variable to know if we're processing the main file */
bool in_included_file = false;

void count_line();
int get_line();
char * get_current_file();

void count_line(){
	if(!in_included_file)
		lineCounter++;
	else
		include_line_counter[include_stack_ptr]++;
}

int get_line(){
	if(!in_included_file)
		return lineCounter;
	else
		return include_line_counter[include_stack_ptr];
}

char * get_current_file(){
	if(!in_included_file)
		return main_file;
	else
		return include_file_name[include_stack_ptr];
}