/* TO BE COMPLETED */

%{

#include "lex.yy.h"
#include "global.h"

#define MAXFUN 100
#define MAXFLD 100

static struct ClassFile cf;

/* main file name*/
	
/* stacks of symbol tables and offsets, depth is just 2 in C (global/local) */
static Table *tblptr[2];
static int offset[2];

/* stack pointers (index into tblptr[] and offset[]) */
static int tblsp = -1;
static int offsp = -1;

/* stack operations */
#define top_tblptr	(tblptr[tblsp])
#define top_offset	(offset[offsp])
#define push_tblptr(t)	(tblptr[++tblsp] = t)
#define push_offset(n)	(offset[++offsp] = n)
#define pop_tblptr	(tblsp--)
#define pop_offset	(offsp--)

/* flag to indicate we are compiling main's body (to differentiate 'return') */
static int is_in_main = 0;

%}

/* declare YYSTYPE attribute types of tokens and nonterminals */
%union
{ Symbol *sym;  /* token value yylval.sym is the symbol table entry of an ID */
  unsigned num; /* token value yylval.num is the value of an int constant */
  float flt;    /* token value yylval.flt is the value of a float constant */
  char *str;    /* token value yylval.str is the value of a string constant */
  unsigned loc; /* location of instruction to backpatch */
  Type typ;	/* type descriptor */
}

/* declare ID token and its attribute type */
%token <sym> ID

/* Declare INT tokens (8 bit, 16 bit, 32 bit) and their attribute type 'num' */
%token <num> INT8 INT16 INT32

/* Declare FLT token for literal floats */
%token <flt> FLT

/* Declare STR token for literal strings */
%token <str> STR

/* declare tokens for keywords */
/* Note: install_id() returns Symbol* for keywords and identifiers */
%token <sym> BREAK CHAR DO ELSE FLOAT FOR IF INT MAIN RETURN VOID WHILE

/* declare operator tokens */
%right '=' PA NA TA DA MA AA XA OA LA RA
%left OR
%left AN
%left '|'
%left '^'
%left '&'
%left EQ NE LE '<' GE '>'
%left LS RS
%left '+' '-'
%left '*' '/' '%'
%right '!' '~'
%left PP NN 
%left '.' AR

/* Declare attribute types for marker nonterminals, such as K L M and N */
/* TODO: TO BE COMPLETED WITH ADDITIONAL NONMARKERS AS NECESSARY */
%type <loc> K L M N

%type <typ> type list args

%type <num> ptr

%%

prog	: Mprog exts	{ addwidth(top_tblptr, top_offset);
			  pop_tblptr;
			  pop_offset;
			}
	;

Mprog	: /* empty */	{ push_tblptr(mktable(NULL));
			  push_offset(0);
			}
	;

exts	: exts func
	| exts decl
	| /* empty */
	;

func	: MAIN '(' ')' Mmain block
			{ // need a temporary table pointer
			  Table *table;
			  // the type of main is a JVM type descriptor
			  Type type = mkfun("[Ljava/lang/String;", "V");
			  // emit the epilogue part of main()
			  emit3(getstatic, constant_pool_add_Fieldref(&cf, "java/lang/System", "out", "Ljava/io/PrintStream;"));
			  emit(iload_2);
			  emit3(invokevirtual, constant_pool_add_Methodref(&cf, "java/io/PrintStream", "println", "(I)V"));
			  emit(return_);
			  // method has public access and is static
			  cf.methods[cf.method_count].access = (enum access_flags)(ACC_PUBLIC | ACC_STATIC);
			  // method name is "main"
			  cf.methods[cf.method_count].name = "main";
			  // method descriptor of "void main(String[] arg)"
			  cf.methods[cf.method_count].descriptor = type;
			  // local variables
			  cf.methods[cf.method_count].max_locals = top_offset;
			  // max operand stack size of this method
			  cf.methods[cf.method_count].max_stack = 100;
			  // length of bytecode is in the emitter's pc variable
			  cf.methods[cf.method_count].code_length = pc;
			  // must copy code to make it persistent
			  cf.methods[cf.method_count].code = copy_code();
			  if (!cf.methods[cf.method_count].code)
				error("Out of memory");
			  // advance to next method to store in method array
			  cf.method_count++;
			  if (cf.method_count > MAXFUN)
			  	error("Max number of functions exceeded");
			  // add width information to table
			  addwidth(top_tblptr, top_offset);
			  // need this table of locals for enterproc
			  table = top_tblptr;
			  // exit the local scope by popping
			  pop_tblptr;
			  pop_offset;
			  // enter the function in the global table
			  enterproc(top_tblptr, $1, type, table);
			}
	| type ptr ID '(' Margs args ')' block
			{ /* TASK 3: TO BE COMPLETED */
			/*
			 	// add code to create function’s type with mkfun()
				// add new static method to Class file method array (see below)
				// invoke addwidth, pop tblptr and offset, enter procedure in global table
			*/
				Table * table = top_tblptr;
				Type type = mkfun($6, $1);
				
				cf.methods[cf.method_count].access = (enum access_flags)(ACC_PUBLIC | ACC_STATIC);
				cf.methods[cf.method_count].name = $3->lexptr; // name of the function;
				cf.methods[cf.method_count].descriptor = type; // type of the function;
				cf.methods[cf.method_count].code_length = pc; // the code size
				cf.methods[cf.method_count].code = copy_code();
				if (!cf.methods[cf.method_count].code)
					error("Out of memory");
				cf.methods[cf.method_count].max_stack = 100;
				cf.methods[cf.method_count].max_locals = top_offset;
				cf.method_count++;
				if (cf.method_count > MAXFUN)
					error("Max number of functions exceeded");
				// add width information to table
				addwidth(table, top_offset);
				// exit the local scope by popping
				pop_tblptr;
				pop_offset;
				// enter the function in the global table
				enterproc(top_tblptr, $3, type, table);
			}
	;

Mmain	:		{ int label1, label2;
			  Table *table;
			  // create new table for local scope of main()
			  table = mktable(top_tblptr);
			  // push it to create new scope
			  push_tblptr(table);
			  // for main(), we must start with offset 3 in the local variables of the frame
			  push_offset(3);
			  // init code block to store stmts
			  init_code();
			  // emit the prologue part of main()
			  emit(aload_0);
			  emit(arraylength);
			  emit2(newarray, T_INT);
			  emit(astore_1);
			  emit(iconst_0);
			  emit(istore_2);
			  label1 = pc;
			  emit(iload_2);
			  emit(aload_0);
			  emit(arraylength);
			  label2 = pc;
			  emit3(if_icmpge, PAD);
			  emit(aload_1);
			  emit(iload_2);
			  emit(aload_0);
			  emit(iload_2);
			  emit(aaload);
			  emit3(invokestatic, constant_pool_add_Methodref(&cf, "java/lang/Integer", "parseInt", "(Ljava/lang/String;)I"));
			  emit(iastore);
			  emit32(iinc, 2, 1);
			  emit3(goto_, label1 - pc);
			  backpatch(label2, pc - label2);
			  // global flag to indicate we're in main()
			  is_in_main = 1;
			}
	;

Margs	:		{ /* TASK 3: TO BE COMPLETED */
					// add code to create new table and push on tblptr and push offset 0
					Table * table = mktable(top_tblptr);
					push_tblptr(table);
					push_offset(0);
					init_code();
					is_in_main = 0;
				}
	;

block	: '{' decls stmts '}'
	;

decls	: decls decl
	| /* empty */
	;

decl	: list ';'
	;

type	: VOID		{ $$ = mkvoid(); }
	| INT		{ $$ = mkint(); }
	| FLOAT		{ $$ = mkfloat(); }
	| CHAR		{ $$ = mkchar(); }
	;

args	: args ',' type ptr ID
			{ if ($4 && ischar($3))
				enter(top_tblptr, $5, mkstr(), top_offset++);
			  else
				enter(top_tblptr, $5, $3, top_offset++);
			  $$ = mkpair($1, $3);
			}
	| type ptr ID	{ if ($2 && ischar($1))
				enter(top_tblptr, $3, mkstr(), top_offset++);
			  else
				enter(top_tblptr, $3, $1, top_offset++);
			  $$ = $1;
			}
	;

list	: list ',' ptr ID
			{ // (PR4.pdf) check global level:
			/*
				in pdf: list : list ’,’ ID
				in code: list : list ',' ptr ID
				so $3 => $4
				
				 // add code to enter variable ID in table with type and place
				 // for local variables, use offset as place and increment offset
			*/
				if (top_tblptr->level == 0){ 
					cf.fields[cf.field_count].access = ACC_STATIC;
					cf.fields[cf.field_count].name = $4->lexptr;
					cf.fields[cf.field_count].descriptor = $1;
					cf.field_count++;
					enter(top_tblptr, $4, $1, constant_pool_add_Fieldref(&cf, cf.name, $4->lexptr, $1));
				}else{ // local variable declaration
					enter(top_tblptr, $4, $1, top_offset++);
				}
				$$ = $1;
			}
	| type ptr ID	{ /* TASK 1 and 4: TO BE COMPLETED */
			/*
				Also taken from pr4.pdf. Same as above:
				in pdf: | type ID
				in code: | type ptr ID
				so $2 => $3
				
				// add code to enter variable ID in table with type and place
				// for local variables, use offset as place and increment offset
			*/
			if (top_tblptr->level == 0){
				cf.fields[cf.field_count].access = ACC_STATIC;
				cf.fields[cf.field_count].name = $3->lexptr;
				cf.fields[cf.field_count].descriptor = $1;
				cf.field_count++;
				enter(top_tblptr, $3, $1, constant_pool_add_Fieldref(&cf, cf.name, $3->lexptr, $1));
			}else{ // local variable declaration
				enter(top_tblptr, $3, $1, top_offset++);
			}
			$$ = $1;
		}
	;

ptr	: /* empty */	{ $$ = 0; }
	| '*'		{ $$ = 1; }
	;

stmts   : stmts stmt
        | /* empty */
        ;

/* TASK 1: TO BE COMPLETED: */
stmt    : ';'
        | expr ';'      { emit(pop); }
		
        | IF '(' expr ')' M stmt
			{
				/* https://www.cs.fsu.edu/~engelen/courses/COP562109/Ch5b.pdf */
				backpatch($5, pc - $5);
			}
		| IF '(' expr ')' M stmt ELSE N stmt 
                        { error("if-then-else not implemented"); }
        | WHILE '(' L expr ')' M stmt N
                        { error("while-loop not implemented"); }
        | DO L stmt WHILE '(' expr ')' K ';'
                        { error("do-while-loop not implemented"); }
        | FOR '(' expr P ';' L expr M N ';' L expr P N ')' L stmt N
                        { error("for-loop not implemented"); }
        | RETURN expr ';'
            { 
				if (is_in_main)
			  		emit(istore_2); /* TO BE COMPLETED */
			  	else
					emit(ireturn);
			}
	| BREAK ';'	{ /* BREAK is optional to implement (see Pr3) */
			  error("break not implemented");
			}
        | '{' stmts '}'
        | error ';'     { yyerrok; }
        ;

exprs	: exprs ',' expr
	| expr
	;


/* TASK 1: TO BE COMPLETED (use pr3 code, then work on assign operators): */
expr    : ID   '=' expr {
			int level = getlevel(top_tblptr, $1),
				place = getplace(top_tblptr, $1);
			Type type = gettype(top_tblptr, $1);
			
			emit(dup);
			if(level == 0){
				emit3(putstatic, place);
			}else if(isint(type)){
				emit2(istore, place);
			}else if(isfloat(type)){
				error("Unsupported type float");
			}
		}
        | ID   PA  expr { error("+= operator not implemented"); }
        | ID   NA  expr { error("-= operator not implemented"); }
        | ID   TA  expr { error("*= operator not implemented"); }
        | ID   DA  expr { error("/= operator not implemented"); }
        | ID   MA  expr { error("%= operator not implemented"); }
        | ID   AA  expr { error("&= operator not implemented"); }
        | ID   XA  expr { error("^= operator not implemented"); }
        | ID   OA  expr { error("|= operator not implemented"); }
        | ID   LA  expr { error("<<= operator not implemented"); }
        | ID   RA  expr { error(">>= operator not implemented"); }
		/* https://docs.oracle.com/javase/specs/jvms/se7/html/jvms-6.html */
        | expr OR  expr { emit(ior); }
        | expr AN  expr { emit(iand); }
        | expr '|' expr { emit(ior); }
        | expr '^' expr { emit(ixor); }
        | expr '&' expr { emit(iand); }
        | expr EQ  expr { emit3(if_icmpeq, 8); emit2(bipush,0); /* if_icmpeq succeeds if and only if value1 = value2 */ }
        | expr NE  expr { emit3(if_icmpne, 8); emit2(bipush,0); /* if_icmpne succeeds if and only if value1 ≠ value2 */ }
        | expr '<' expr { emit3(if_icmplt, 8); emit2(bipush,0); /* if_icmplt succeeds if and only if value1 < value2 */ }
        | expr '>' expr { emit3(if_icmpgt, 8); emit2(bipush,0); /* if_icmpgt succeeds if and only if value1 > value2 */ }
        | expr LE  expr { emit3(if_icmple, 8); emit2(bipush,0); /* if_icmple succeeds if and only if value1 ≤ value2 */ }
        | expr GE  expr { emit3(if_icmpne, 8); emit2(bipush,0); /* if_icmpne succeeds if and only if value1 ≠ value2 */ }
        | expr LS  expr { emit(ishl); }
        | expr RS  expr { emit(ishr); /*arithmetic. for logical iushr*/ }
        | expr '+' expr { emit(iadd); }
        | expr '-' expr { emit(isub); }
        | expr '*' expr { emit(imul); }
        | expr '/' expr { emit(idiv); }
        | expr '%' expr { emit(irem); }
        | '!' expr      { emit(ineg); }
        | '~' expr      { error("~ operator not implemented"); }
        | '+' expr %prec '!'
                        { error("unary + operator not implemented"); }
        | '-' expr %prec '!'
                        { error("unary - operator not implemented"); }
        | '(' expr ')'
        | '$' INT8      { // check that we are in main()
			  if (is_in_main)
			  {	emit(aload_1);
			  	emit2(bipush, $2);
			  	emit(iaload);
			  }
			  else
			  	error("invalid use of $# in function");
			}
        | PP ID         { error("pre ++ operator not implemented"); }
        | NN ID         { error("pre -- operator not implemented"); }
		/* https://www.artima.com/underthehood/bytecode3.html 
			ID PP and ID NN doesn't work
			Java Error "Unable to pop operand off an empty stack"
		*/
        | ID PP         { emit(iadd); emit(iconst_1);  }
        | ID NN         { emit(iadd); emit(iconst_m1); }
		| ID            {
			int level = getlevel(top_tblptr, $1),
				place = getplace(top_tblptr, $1);
			Type type = gettype(top_tblptr, $1);
			
			if(level == 0){
				emit3(getstatic, place);
			}else if(isint(type)){
				emit2(iload, place);
			}else if(isfloat(type)){
				error("Unsupported type float");
			}
		}
        | INT8          { emit2(bipush, $1); }
        | INT16         { emit3(sipush, $1); }
        | INT32         { emit2(ldc, constant_pool_add_Integer(&cf, $1)); }
	| FLT		{ emit2(ldc, constant_pool_add_Float(&cf, $1)); }
	| STR		{ emit2(ldc, constant_pool_add_String(&cf, constant_pool_add_Utf8(&cf, $1))); }
	| ID '(' exprs ')'
		{ 
			/* TASK 3: TO BE COMPLETED */
			/* from pr4.pdf */
			emit3(
				invokestatic,
				constant_pool_add_Methodref(
					&cf, 
					cf.name, 
					$1->lexptr, 
					gettype(top_tblptr, $1)
				)
			);
		}
        ;

K       : /* empty */   { $$ = pc; emit3(ifne, 0); }
        ;

L       : /* empty */   { $$ = pc; }
        ;

M       : /* empty */   { $$ = pc;	/* location of inst. to backpatch */
			  emit3(ifeq, 0);
			}
        ;

N       : /* empty */   { $$ = pc;	/* location of inst. to backpatch */
			  emit3(goto_, 0);
			}
        ;

P       : /* empty */   { emit(pop); }
        ;

%%

int main(int argc, char **argv)
{
	// init the compiler
	init();

	// set up a new class file structure
	init_ClassFile(&cf);

	// class has public access
	cf.access = ACC_PUBLIC;

	// class name is "Code"
	cf.name = "Code";

	// field counter (incremented for each field we add)
	cf.field_count = 0;

	// method counter (incremented for each method we add)
	cf.method_count = 0;

	// allocate an array of MAXFLD fields
	cf.fields = (struct FieldInfo*)malloc(MAXFLD * sizeof(struct FieldInfo));

	// allocate an array of MAXFUN methods
	cf.methods = (struct MethodInfo*)malloc(MAXFUN * sizeof(struct MethodInfo));

	if (!cf.methods)
		error("Out of memory");

	if (argc > 1){
		if (!(yyin = fopen(argv[1], "r")))
			error("Cannot open file for reading");
		else
			main_file = argv[1];
	}else
		main_file = (char*) "";
	if (yyparse() || errnum > 0)
		error("Compilation errors: class file not saved");

	fprintf(stderr, "Compilation successful: saving %s.class\n", cf.name);

	// save class file
	save_classFile(&cf);

	return 0;
}

