#ifndef SHARED_H
#define SHARED_H

/* Sharing variables between yacc and lex. Not using global.h to avoid unused warnings. */
static char * main_file = (char *) malloc(sizeof(char *) * 256); 

#endif
