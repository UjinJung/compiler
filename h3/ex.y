%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdarg.h>
    #include "ex.h"
    #include "y.tab.h"

    synTree_ *operNode_(int oper, int operNumber, ...);
    synTree_ *idNode_(char* id);
    synTree_ *constNode_(int value);
    synTree_ *doubleNode_(double value);
    synTree_ *functionNode_();
    void freeNode(synTree_ *syntaxTree);
    double eval(synTree_ *syntaxTree);
    int yylex(void);

    double temp;
    char controlStmt = 0;
    int id_num = 1;
    void yyerror(char *msg);
    int symTable[100];

    struct SymTable_* sym_table;
%}

%union {
    int ival;
    double dval;
    char sIndex[17];
    synTree_ *nPtr;
};

%token <ival> INTEGER
%token <dval> DOUBLE 
%token <sIndex> VARIABLE 
%token WHILE IF END DEF
%nonassoc IFX
%nonassoc ELSE

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type <nPtr> stmt expr stmt_list
%%

line:
    eval_print            { exit(0); }
    ;

eval_print:
    eval_print stmt       { 
            temp = eval($2);
            if(temp != -1){
                if((int)(temp*10)%10 != 0){
                    printf("%f \n?- ", temp); 
                } else {
                    printf("%d \n?- ", (int)temp); 
                }
                controlStmt = 0;
            }
            freeNode($2); 
        }
    |
    ;

stmt:
    ';'                 {
                            if(controlStmt == 1)
                            printf("> ");  $$ = operNode_(';', 2, NULL, NULL); 
                        }
    | expr ';'          {
                            if(controlStmt == 1)
                            printf("> ");  $$ = $1; 
                        }
    | VARIABLE '=' expr ';'     { 
                                    if(controlStmt == 1)
                                    printf("> ");  
                                    $$ = operNode_('=', 2, idNode_($1), $3);  
                                }
    | WHILE '(' expr ')' stmt END { controlStmt = 1; $$ = operNode_(WHILE, 2, $3, $5); }
    | IF '(' expr ')' stmt_list %prec IFX END   { $$ = operNode_(IF, 2, $3, $5); }
    | IF '(' expr ')' stmt_list ELSE stmt_list END    { $$ = operNode_(IF, 3, $3, $5, $7); }
    ;

stmt_list:
    stmt                { $$ = $1; }
    | stmt_list stmt    { $$ = operNode_(';', 2, $1, $2); }
    ;

expr:
    INTEGER             { $$ = constNode_($1); }
    | DOUBLE            { $$ = doubleNode_($1); }
    | VARIABLE          { $$ = idNode_($1); }
    | '-' expr %prec UMINUS { $$ = operNode_(UMINUS, 1, $2); }
    | expr '+' expr     { $$ = operNode_('+', 2, $1, $3); }
    | expr '-' expr     { $$ = operNode_('-', 2, $1, $3); }
    | expr '*' expr     { $$ = operNode_('*', 2, $1, $3); }
    | expr '/' expr     { $$ = operNode_('/', 2, $1, $3); }
    | expr '<' expr     { $$ = operNode_('<', 2, $1, $3); }
    | expr '>' expr     { $$ = operNode_('>', 2, $1, $3); }
    | expr GE expr      { $$ = operNode_(GE, 2, $1, $3); }
    | expr LE expr      { $$ = operNode_(LE, 2, $1, $3); }
    | expr NE expr      { $$ = operNode_(NE, 2, $1, $3); }
    | expr EQ expr      { $$ = operNode_(EQ, 2, $1, $3); }
    | '(' expr ')'      { $$ = $2; }
    ;

%%

#define SIZEOF_synTree_ ((char*)&p->constNode_ - (char*)p)

synTree_ *constNode_(int value) {
    synTree_ *syntaxTree;

    if((syntaxTree = malloc(sizeof(synTree_))) == NULL);

    syntaxTree->type = typeCo;
    syntaxTree->constNode_.value = value;

    return syntaxTree;
}

synTree_ *doubleNode_(double value) {
    synTree_ *syntaxTree;

    if((syntaxTree = malloc(sizeof(synTree_))) == NULL);

    syntaxTree->type = typeDouble;
    syntaxTree->doubleNode_.value = value;

    return syntaxTree;
}

synTree_ *idNode_(char* id){
    synTree_ *syntaxTree;
    int i = 0;
    
    if((syntaxTree = malloc(sizeof(synTree_))) == NULL);
        
    while(i < id_num){
        if(!(strcmp(id, sym_table[i].id))){
            i++; break;
        }
        i++;
    }

    if(i >= id_num){
        strcpy(sym_table[(id_num-1)].id, id);
        strcpy(syntaxTree->idNode_.id, sym_table[(id_num-1)].id);
        sym_table[id_num-1].isAssign = 0;
        syntaxTree->idNode_.tableNumber = id_num-1;

        id_num++;
    }else{
        strcpy(syntaxTree->idNode_.id, sym_table[(i-1)].id);
        syntaxTree->idNode_.tableNumber = i-1;
    }

    syntaxTree->type = typeId;
    strcpy(syntaxTree->idNode_.id, id);
    syntaxTree->idNode_.value = 0.0;

    return syntaxTree;
}

synTree_ *operNode_(int oper, int operNumber, ...){
    va_list ap;
    synTree_ *syntaxTree;
    int i;

    if((syntaxTree = malloc(sizeof(synTree_) + (operNumber-1)*sizeof(synTree_*) )) == NULL);
        
    syntaxTree->type = typePr;
    syntaxTree->operNode_.oper = oper;
    syntaxTree->operNode_.operNumber = operNumber;
    va_start(ap, operNumber);
    for(i = 0; i < operNumber; i++)
        syntaxTree->operNode_.op[i] = va_arg(ap, synTree_*);
    
    va_end(ap);

    return syntaxTree;
}

void freeNode(synTree_ *syntaxTree) {
    int i;

    if(!syntaxTree) return;
    if(syntaxTree->type == typePr) {
        for(i = 0; i < syntaxTree->operNode_.operNumber; i++)
            freeNode(syntaxTree->operNode_.op[i]);
    }
    free(syntaxTree);
}

double eval(synTree_ *syntaxTree) {
    if(!syntaxTree) return -1;
    switch (syntaxTree->type) {
        case typeCo:
            return syntaxTree->constNode_.value;
        case typeId:
            return symTable[syntaxTree->idNode_.tableNumber];
        case typeDouble:
            return syntaxTree->doubleNode_.value;
        case typePr:
            switch(syntaxTree->operNode_.oper) {
                case WHILE: while(eval(syntaxTree->operNode_.op[0]))
                                eval(syntaxTree->operNode_.op[1]);
                            printf("while\n?- ");
                            return -1;
                case IF: if (eval(syntaxTree->operNode_.op[0]))
                            eval(syntaxTree->operNode_.op[1]);
                         else if (syntaxTree->operNode_.operNumber > 2)
                            eval(syntaxTree->operNode_.op[2]);
                         printf("if\n?- ");
                         return -1;
                case ';':   eval(syntaxTree->operNode_.op[0]); return eval(syntaxTree->operNode_.op[1]);
                case '=':   return symTable[syntaxTree->operNode_.op[0]->idNode_.tableNumber] = eval(syntaxTree->operNode_.op[1]); 
                case UMINUS:    return -eval(syntaxTree->operNode_.op[0]);
                case '+':    return eval(syntaxTree->operNode_.op[0]) + eval(syntaxTree->operNode_.op[1]);
                case '-':    return eval(syntaxTree->operNode_.op[0]) - eval(syntaxTree->operNode_.op[1]);
                case '*':    return eval(syntaxTree->operNode_.op[0]) * eval(syntaxTree->operNode_.op[1]);
                case '/':    return eval(syntaxTree->operNode_.op[0]) / eval(syntaxTree->operNode_.op[1]);
                case '<':    return eval(syntaxTree->operNode_.op[0]) < eval(syntaxTree->operNode_.op[1]);
                case '>':    return eval(syntaxTree->operNode_.op[0]) > eval(syntaxTree->operNode_.op[1]);
                case GE :    return eval(syntaxTree->operNode_.op[0]) >= eval(syntaxTree->operNode_.op[1]);
                case LE :    return eval(syntaxTree->operNode_.op[0]) <= eval(syntaxTree->operNode_.op[1]);
                case NE :    return eval(syntaxTree->operNode_.op[0]) != eval(syntaxTree->operNode_.op[1]);
                case EQ :    return eval(syntaxTree->operNode_.op[0]) == eval(syntaxTree->operNode_.op[1]);
            }
    }
    return 0;
}

void yyerror(char *msg)
{
    fprintf(stderr, "%s\n" ,msg);
}
int main(void) {
    synTree_* syntaxTree;

    sym_table = (symtable*)malloc(20*sizeof(symtable));
    
    if((syntaxTree = malloc(sizeof(synTree_))) == NULL);
    printf("?- ");
    yyparse();

    return 0;
}