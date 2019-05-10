/*	Definition section */
%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
extern int scope_state;
extern int yylineno;
extern int yylex();
extern char* id_temp;
int yyerror(char*);
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex

struct symbol{
	int index;
	char name[10];
	char entry_type[10];
	char data_type[7];
	int scope_level;
	char formal_parameters[100];
	struct symbol * next;
    struct symbol * next_index;
};
/* Symbol table function - you can add new function if needed. */
int lookup_symbol();
void create_symbol(char *,int);
void insert_symbol(int,struct symbol *);
void dump_symbol();

struct symbol * table[30][30];
struct symbol * index_stack[30];

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
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token DEC_ASSIGN RETURN
%token ID

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
    : type ID '=' initializer ';' {create_symbol(id_temp,scope_state);}
    | type ID ';' {create_symbol(id_temp,scope_state);} 
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
	: '{' '}' {dump_symbol(scope_state);}
	| '{' block_item_list '}' {dump_symbol(scope_state); scope_state--;}
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
	: func_id parameter compound_stat  {}
	| func_id parameter ';'
;

parameter
	: '(' ')'
	| '(' identifier_list ')' {}
;

identifier_list
	: identifier_list ',' type ID {create_symbol(id_temp,scope_state+1);}
	| type ID {create_symbol(id_temp,scope_state+1);}
;


func_id
    : type ID {printf("%s %d\n",id_temp,scope_state);create_symbol(id_temp,scope_state);}
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
    dump_symbol(scope_state);
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

void create_symbol(char* name, int scope) {
	struct symbol* s = malloc(sizeof(struct symbol));
	
    /*insert data*/
	strcpy(s->name, name);
    free(id_temp);
	s->scope_level = scope;
	int hash_num = s->name[0]%30;
	insert_symbol(hash_num,s);


    /*insert to index stack*/
    if(index_stack[scope]==NULL)
        index_stack[scope]=s;
    else {
        struct symbol * temp=index_stack[scope];
        while(temp->next_index != NULL)
            temp=temp->next_index;
        temp->next_index=s;
    }
}
void insert_symbol(int hash_num, struct symbol * s) {
	int scope=s->scope_level;
	if(table[scope][hash_num]==NULL){
		table[scope][hash_num]=s;
	}
	else{
		struct symbol * p = table[scope][hash_num];
		while(p->next!=NULL){
			p=p->next;
		}
		p->next=s;
	}
}
int lookup_symbol() {}
void dump_symbol(int scope) {
    if(index_stack[scope]==NULL)return;

	printf("\n\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
	int index=0;
	struct symbol * s;
    s=index_stack[scope];
    while(s!=NULL){
        printf("%-10d%-10s\n",index,s->name);
        index_stack[scope]=s->next_index;
        index++;
        free(s);
        s=index_stack[scope];
    }
    for(int i=0;i<30;++i){
        table[scope][i]=NULL;
    }
}
