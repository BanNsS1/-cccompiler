/* TO BE COMPLETED */
%x include
%option noyywrap
%option yylineno
%option nounistd

%{
#include "global.h"
#include "mycc.h"
#include "shared.h"
#define MAX_INCLUDE_DEPTH 5

static int localvar = 3;
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int include_line_counter[MAX_INCLUDE_DEPTH] = {};
char * include_file_name[MAX_INCLUDE_DEPTH];
int include_stack_ptr = -1;
bool in_included_file = false;

int lineCounter = 1;

static void count_line();
static int get_line();
static char * get_current_file();

static int install_id();
static int install_int();
static int install_oct();
static int install_hex();
static int install_chr();
static int install_fp();
static int install_str();
    
%}

digit           [0-9]
alpha           [a-zA-Z_]
id              {alpha}({alpha}|{digit})*
int             {digit}+
oct             0[0-7]+
hex             0[xX][0-9a-fA-F]+
chr             '(\\'|[^'\n])*'
fp              {int}(\.{int}([Ee][+-]?{int})?|(\.{int})?[Ee][+-]?{int})
str             \"(\\\"|\\\n|[^"])*\"

%%

[ \t\v\f\r]                    /* skip white space */
[\n]                           { count_line(); }
___                            /* TO BE COMPLETED: ignore inline and multiline comments */
{id}                           { return install_id(); }
{oct}                          { return install_oct(); }
{hex}                          { return install_hex(); }
{int}                          { return install_int(); }
{chr}                          { return install_chr(); }
{fp}                           { return install_fp(); }
{str}                          { return install_str(); }
"+="                           { return PA; }
"-="                           { return NA; }
"*="                           { return TA; }
"/="                           { return DA; }
"%="                           { return MA; }
"&="                           { return AA; }
"^="                           { return XA; }
"|="                           { return OA; }
"<<="                          { return LA; }
">>="                          { return RA; }
"||"                           { return OR; }
"&&"                           { return AN; }
"=="                           { return EQ; }
"!="                           { return NE; }
"<="                           { return LE; }
">="                           { return GE; }
"<<"                           { return LS; }
">>"                           { return RS; }
"++"                           { return PP; }
"--"                           { return NN; }
"->"                           { return AR; }
"<%"                           { return '{'; }
"%>"                           { return '}'; }
"<:"                           { return '['; }
":>"                           { return ']'; }
"//"[^\n]*                     { /*ignore inline comments*/ }
"#"include                     { BEGIN(include); }
<include>[ \t\<]*              { /* skip white space and < */ }
<include>[a-zA-Z0-9\.\/\-]+    {
									char * filename = (char *) malloc(sizeof(char *) * 256);
									strcpy(filename, yytext);
									if ( include_stack_ptr >= MAX_INCLUDE_DEPTH -1 ){
										char error_msg[256];
										sprintf(error_msg, "%s:%d: Includes nested too deeply", get_current_file(), get_line());
                                    	error(error_msg);
                                    	exit(1);
									}
									include_stack_ptr++;
									include_stack[include_stack_ptr] = YY_CURRENT_BUFFER;
									include_line_counter[include_stack_ptr] = 1;
									include_file_name[include_stack_ptr] = filename;
                                	yyin = fopen(filename, "r" );
                                	if ( ! yyin ){
										char error_msg[256];
										sprintf(error_msg, "%s:%d: Include file %s not found", get_current_file(), get_line(), filename);
                                    	exit(1);
                                	}
									in_included_file = true;
                               }
<include>[\>\n]                {
									yy_switch_to_buffer(
                                	yy_create_buffer( yyin, YY_BUF_SIZE ) );
                                	BEGIN(0);
                               }
<<EOF>>                        {
									include_stack_ptr--;
									if(include_stack_ptr < 0 ){
                                    	yyterminate();
										in_included_file = false;
                                	}else{
                                   		yy_delete_buffer( YY_CURRENT_BUFFER );
                                    	yy_switch_to_buffer(include_stack[include_stack_ptr]);
                                	}
                               }
[!$%&()*+,\-./:;<=>?\[\]^{|}~] { return yytext[0]; }


%%

static void count_line(){
	if(!in_included_file)
		lineCounter++;
	else
		include_line_counter[include_stack_ptr]++;
}

static int get_line(){
	if(!in_included_file)
		return lineCounter;
	else
		return include_line_counter[include_stack_ptr];
}

static char * get_current_file(){
	if(!in_included_file)
		return main_file;
	else
		return include_file_name[include_stack_ptr];
}
	
/* install_id - add identifier to symbol table if not already there */
static int install_id()
{
	yylval.sym = lookup(yytext);

	if (!yylval.sym)
	{
		yylval.sym = insert(yytext, ID);
		yylval.sym->localvar = localvar++;
	}

	return yylval.sym->token;
}

/* install_int - convert decimal yytext[] to INT8, INT16, or INT32 */
static int install_int()
{
	sscanf(yytext, "%u", &yylval.num);

	if (yylval.num < 128)
		return INT8;

	if (yylval.num < 32368)
		return INT16;

	return INT32;
}

/* install_oct - convert octal yytext[] to INT8, INT16, or INT32 */
static int install_oct()
{
	sscanf(yytext, "%o", &yylval.num);

  	if (yylval.num < 128)
		return INT8;

	if (yylval.num < 32368)
		return INT16;

	return INT32;
}

/* install_hex - convert hexadecimal yytext[] to INT8, INT16, or INT32 */
static int install_hex()
{
	sscanf(yytext, "%x", &yylval.num);

	if (yylval.num < 128)
		return INT8;

	if (yylval.num < 32368)
		return INT16;

	return INT32;
}

/* install_chr - convert ASCII character yytext[1] to INT8 */
static int install_chr()
{
	char c;

	sscanf(yytext + 1, "%c", &c);
	yylval.num = (int)c;

	return INT8;
}

/* install_fp - convert float yytext[] into float FLT */
static int install_fp()
{
	sscanf(yytext, "%g", &yylval.flt);

	return FLT;
}

/* install_str - duplicate yytext[] string without the quotes */
static int install_str()
{
	yylval.str = (char*)malloc(yyleng - 1);

	if (yylval.str)
	{
		strcpy(yylval.str, yytext + 1);
		yylval.str[yyleng - 2] = '\0';
	}

	return STR;
}
