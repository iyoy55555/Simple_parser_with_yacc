/*	Definition section */
%{
#include <stdio.h>

extern int yylineno;
extern int yylex();
int yyerror(char*);
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex

/* Symbol table function - you can add new function if needed. */
int lookup_symbol();
void create_symbol();
void insert_symbol();
void dump_symbol();

%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    double f_val;
    char* string;
}

/* Token without return */
%token PRINT 
%token IF ELSE FOR WHILE
%token ID 
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token DEC_ASSIGN RETURN

/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> S_CONST
%token <i_val> INT
%token <f_val> FLOAT
%token <i_val> BOOL
%token <i_val> VOID
%token <string> STRING

/* Nonterminal with return, which need to sepcify type */

/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program
    : program stat
    | 
;

stat
    : declaration 
    | function_declaration
    | print_func
;

print_func
	: PRINT '(' print_element ')'
;

print_element
	: S_CONST
	| ID
;


declaration
    : type ID '=' initializer ';' {}
    | type ID ';' {} 
;

statement
	: compound_stat
	| expression_statement
	| print_func
	| selection_statement
	| iteration_statement
	| jump_statement
;

expression_statement
	: ';'
	| expression ';'
;

selection_statement
	: IF '(' expression ')' statement ELSE statement
	| IF '(' expression ')' statement
;

iteration_statement
	: WHILE '(' expression ')' statement

compound_stat
	: '{' '}'
	| '{' block_item_list '}'
;

jump_statement
	: RETURN ';'
	| RETURN expression
;

block_item_list
	: block_item
	| block_item_list block_item
;

block_item
	: declaration
	| statement
;

primary_expression
	: ID
	| initializer
;

expression 
	: assignment_expression
	| expression ',' assignment_expression
;
/*******VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV  expression priority high             */
unary_expression
	: postfix_expression
	| INC_OP unary_expression
	| DEC_OP unary_expression
;

multiplicative_expression
	: unary_expression
	| multiplicative_expression '*' unary_expression
	| multiplicative_expression '/' unary_expression
	| multiplicative_expression '%' unary_expression
;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression
	| additive_expression '-' multiplicative_expression
;

shift_expression
	: additive_expression
/*	| shift_expression LEFT_OP additive_expression
	| shift_expression RIGHT_OP additive_expression
*/
;

relational_expression
	: shift_expression
	| relational_expression '<' shift_expression
	| relational_expression '>' shift_expression
	| relational_expression LE_OP shift_expression
	| relational_expression GE_OP shift_expression
;


equality_expression
	: relational_expression
	| equality_expression EQ_OP relational_expression
	| equality_expression NE_OP relational_expression
;


and_expression
	: equality_expression
	| and_expression '&' equality_expression
;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression
;

logic_and_expression
	: inclusive_or_expression
	| logic_and_expression AND_OP inclusive_or_expression
;

logic_or_expression
	: logic_and_expression
	| logic_or_expression OR_OP logic_and_expression
;

condition_expression
	: logic_or_expression
;

assignment_expression
	: condition_expression
	| ID assignment_operator assignment_expression
;
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  expression priority low*/
assignment_operator
	: '='
	| MUL_ASSIGN
	| DIV_ASSIGN
	| MOD_ASSIGN
	| ADD_ASSIGN
	| DEC_ASSIGN
;

argument_expression_list
	: assignment_expression
	| argument_expression_list ',' assignment_expression
;

postfix_expression
	: primary_expression
	| postfix_expression INC_OP
	| postfix_expression DEC_OP
	| postfix_expression '(' ')'
	| postfix_expression '(' argument_expression_list ')'
;


function_declaration
	: type ID parameter compound_stat
	| type ID parameter ';'
;

parameter
	: '(' ')'
	| '(' identifier_list ')'

identifier_list
	: identifier_list ',' type ID
	| type ID
;
/* actions can be taken when meet the token or rule */

parameter
	: parameter ',' declaration
	| declaration
;

type
    : INT {}
    | FLOAT {}
    | BOOL  {}
    | STRING {}
    | VOID {}
;

initializer
	: I_CONST {}
	| F_CONST {}
	| S_CONST
;
%%

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;

    yyparse();
	printf("\nTotal lines: %d \n",yylineno);

    return 0;
}

int yyerror(char *s)
{
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
}

void create_symbol() {}
void insert_symbol() {}
int lookup_symbol() {}
void dump_symbol() {
    printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
}
