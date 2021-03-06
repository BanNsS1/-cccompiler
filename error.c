#include "global.h"

int errnum = 0;

/* yyerror - invoked by yyparse to report a syntax error */
int yyerror(const char *msg)
{
	fprintf(stderr, "%s:%d: %s\n", get_current_file(), get_line(), msg);

	//fprintf(stderr, "line %d: %s\n", yylineno, msg);

	if (errnum++ > 10)
		error("Too many errors: jumping ship");

	return 0;
}

/* error - report error and exit */
void error(const char *msg)
{
	fprintf(stderr, "%s:%d: %s\n", get_current_file(), get_line(), msg);
	exit(1);
}
