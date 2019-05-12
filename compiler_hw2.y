/*	Definition section */
%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
extern int scope_state;
extern int yylineno;
extern int yylex();
extern char type_temp[10];
char para_buf[256];
int yyerror(char*);
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex


struct symbol{
	int index;
	char name[10]; /*malloc pointer may segmentation fault*/
	char entry_type[15];
	char data_type[7];
	int scope_level;
	char formal_parameters[100];
	struct symbol * next;
    struct symbol * next_index;
};
/* Symbol table function - you can add new function if needed. */
int lookup_symbol(const char *);
void create_symbol(char *,int,char *,char *);
void insert_symbol(int,struct symbol *);
void dump_symbol();
void semantic_error(char * , char *);

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
%token <string> ID

/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> S_CONST
%token <string> INT
%token <string> FLOAT
%token <string> BOOL
%token <string> VOID
%token <string> STRING

/* Nonterminal with return, which need to sepcify type */
%type <string> type
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
    : type ID '=' initializer ';' {
        if(lookup_symbol($2))
            semantic_error("Redeclared variable",$2);
        else
            create_symbol($2,scope_state,"variable",$1);}
    | type ID ';' {
        if(lookup_symbol($2))
            semantic_error("Redeclared variable",$2);
        else
            create_symbol($2,scope_state,"variable",$1);} 
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
	: type ID parameter compound_stat  {create_symbol($2,scope_state,"function",$1);}
;

parameter
	: '(' ')'
	| '(' identifier_list ')' {}
;

identifier_list
	: identifier_list ',' type ID {
        if(strlen(para_buf)!=0)
            strcat(para_buf,", ");
        strcat(para_buf,$3);
        create_symbol($4,scope_state+1,"parameter",$3);}
	| type ID {
        if(strlen(para_buf)!=0)
            strcat(para_buf,", ");
        strcat(para_buf,$1);
        create_symbol($2,scope_state+1,"parameter",$1);}
;



;
/* actions can be taken when meet the token or rule */

parameter
	: parameter ',' declaration
	| declaration
;

type
    : INT { $$ =$1;}
    | FLOAT {$$ =$1;}
    | BOOL  {$$ =$1;}
    | STRING {$$ =$1;}
    | VOID {$$ =$1;}
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

void create_symbol(char* name, int scope,char* kind, char* type) {
	struct symbol* s = malloc(sizeof(struct symbol));
	
    /*insert data*/
	strcpy(s->name, name);
	s->scope_level = scope;
	int hash_num = s->name[0]%30;
    strcpy(s->entry_type,kind);
    strcpy(s->data_type,type);
    if(strcmp("function",kind)==0){
        strcpy(s->formal_parameters,para_buf);
        memset(para_buf,0,strlen(para_buf));
    }
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
int lookup_symbol(const char * name) {
    int hash_num = name[0]%30;
    struct symbol * s = table[scope_state][hash_num];
    while(s!=NULL){
        if(strcmp(name , s->name)==0){
            return 1;
        }
        s=s->next;
    }
    return 0;
}
void dump_symbol(int scope) {
    if(index_stack[scope]==NULL)return;

	printf("\n\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
	int index=0;
	struct symbol * s;
    s=index_stack[scope];
    while(s!=NULL){
        printf("%-10d%-10s%-12s%-10s%-10d%s\n",
            index,s->name,s->entry_type,s->data_type,s->scope_level,s->formal_parameters);
        index_stack[scope]=s->next_index;
        index++;
        free(s);
        s=index_stack[scope];
    }
    for(int i=0;i<30;++i){
        table[scope][i]=NULL;
    }
}

void semantic_error(char * error_type,char * name){
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno, buf);
    printf("| %s %s",error_type, name);
    printf("\n|-----------------------------------------------|\n\n");
}
