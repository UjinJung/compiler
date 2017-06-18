%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdarg.h>
    #include "ex.h"
    #include "y.tab.h"

    synTree_ *operNode_(int oper, int operNumber, ...);
    synTree_ *idNode_(int type, int operNumber, char* id, ...);
    synTree_ *constNode_(int value);
    synTree_ *doubleNode_(double value);
    synTree_ *functionNode_();
    double evalFunc(char* funcName, synTree_ *syntaxTree);
    void generateFuncNode(char* funcName, int operNumber, synTree_* param, synTree_* stmt_list, char* returnId, ...);
    void freeNode(synTree_ *syntaxTree);
    double eval(synTree_ *syntaxTree);
    int yylex(void);

    double temp;
    char controlState = 0;
    char funcState = 0;
    char funcEvalState = 0;
    int id_num = 1;
    int func_num = 1;
    int func_current_num = 0;
    int param_index = 0;
    void yyerror(char *msg);

    symtable* sym_table;
    functable* param_table;
    functable* local_table;
    synTree_* func_table[20];
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
%token WHILE IF END DEF LOCAL RETURN
%nonassoc IFX
%nonassoc ELSE

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type <nPtr> stmt expr stmt_list var param param_alloc
%type <ival> function

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
                controlState = 0;
            }
            freeNode($2); 
        }
    | eval_print function     {  } 
    |
    ;

stmt:
    ';'                 {
                            if(controlState == 1 || funcState == 1)
                            printf("> ");  $$ = operNode_(';', 2, NULL, NULL); 
                        }
    | expr ';'          {
                            if(controlState == 1 || funcState == 1)
                            printf("> ");  $$ = $1; 
                        }
    | VARIABLE '=' expr ';'     { 
                                    if(controlState == 1 || funcState == 1)
                                        printf("> ");  
                                    $$ = operNode_('=', 2, idNode_(normalId, 0, $1), $3);  
                                }
    | WHILE '(' expr ')' stmt END                       { controlState = 1; $$ = operNode_(WHILE, 2, $3, $5); }
    | IF '(' expr ')' stmt_list %prec IFX END           { $$ = operNode_(IF, 2, $3, $5); }
    | IF '(' expr ')' stmt_list ELSE stmt_list END      { $$ = operNode_(IF, 3, $3, $5, $7); }
    ;

 
function:
    DEF VARIABLE '(' param ')' stmt_list RETURN VARIABLE ';' END  { printf("1\n");generateFuncNode($2, 0, $4, $6, $8); } 
    | DEF VARIABLE '(' param ')' LOCAL var ';' stmt_list RETURN VARIABLE ';' END  { generateFuncNode($2, 1, $4, $9, $11, $7); } 
    | VARIABLE'(' param_alloc ')' ';'     { printf("11\n"); evalFunc($1, $3); }
    ;

var:
    VARIABLE                        { $$ = idNode_(localId, 0, $1);  }
    | var ',' VARIABLE              { $$ = idNode_(localId, 1, $3, $1); }
    ;

param:
    VARIABLE                        { $$ = idNode_(paramId, 0, $1); }
    | param ',' VARIABLE            { $$ = idNode_(paramId, 1, $3, $1);  }
    ;

param_alloc:
    INTEGER                         { $$ = constNode_($1); }
    | DOUBLE                        { $$ = doubleNode_($1); }
    | param_alloc ',' INTEGER       { $$ = operNode_(',', 2, $1, constNode_($3)); }
    | param_alloc ',' DOUBLE        { $$ = operNode_(',', 2, $1,  doubleNode_($3)); }
    ;

stmt_list:
    stmt                { $$ = $1; }
    | stmt_list stmt    { $$ = operNode_(';', 2, $1, $2); }
    ;

expr:
    INTEGER             { $$ = constNode_($1); }
    | DOUBLE            { $$ = doubleNode_($1); }
    | VARIABLE          { $$ = idNode_(normalId, 0, $1); }
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

    syntaxTree->type = intVal;
    syntaxTree->constNode_.value = value;

    return syntaxTree;
}

synTree_ *doubleNode_(double value) {
    synTree_ *syntaxTree;

    if((syntaxTree = malloc(sizeof(synTree_))) == NULL);

    syntaxTree->type = doubleVal;
    syntaxTree->doubleNode_.value = value;

    return syntaxTree;
}

synTree_ *idNode_(int type, int operNumber, char* id, ...){
    synTree_ *syntaxTree;
    va_list ap;
    int i = 0;
    int param_num = 1;
    int local_num = 1;

    if((syntaxTree = malloc(sizeof(synTree_) + (operNumber-1)*sizeof(synTree_*) )) == NULL);
        
    switch(type){
        case normalId: 
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
        break;
        
        case paramId:
        if(operNumber == 0)
            param_table[(func_num)-1].top = 0;
        param_num = param_table[(func_num-1)].top + 1; 
        // printf("pa : %d\n", param_num);
        while(i < param_num){
            if(!(strcmp(id, param_table[func_num-1].table[i].id))){
                i++; break;
            }
            i++;
        }
        if(i >= param_num){
            strcpy(param_table[(func_num-1)].table[param_num-1].id, id);
            strcpy(syntaxTree->idNode_.id, id);
        }
        // printf("pa_id : %s\n", param_table[(func_num-1)].table[param_num-1].id);
        va_start(ap, operNumber);
        syntaxTree->idNode_.op[0] = va_arg(ap, synTree_*);
        va_end(ap); 
        param_table[(func_num-1)].top++; 
        break;
        
        case localId:
        if(operNumber == 0)
            local_table[(func_num)-1].top = 0;
        local_num = local_table[(func_num-1)].top + 1; 
        while(i < local_num){
            if(!(strcmp(id, local_table[func_num].table[i].id))){
                i++; break;
            }
            i++;
        }
        if(i >= local_num){
            strcpy(local_table[(func_num-1)].table[local_num-1].id, id);
            strcpy(syntaxTree->idNode_.id, id);

            local_num++;
        }
        va_start(ap, operNumber);
        syntaxTree->idNode_.op[0] = va_arg(ap, synTree_*);
        va_end(ap);
        local_table[(func_num-1)].top++; 
    }

    syntaxTree->type = type;
    strcpy(syntaxTree->idNode_.id, id);

    return syntaxTree;
}

synTree_ *operNode_(int oper, int operNumber, ...){
    va_list ap;
    synTree_ *syntaxTree;
    int i;

    if((syntaxTree = malloc(sizeof(synTree_) + (operNumber-1)*sizeof(synTree_*) )) == NULL);
        
    syntaxTree->type = operatorVal;
    syntaxTree->operNode_.oper = oper;
    syntaxTree->operNode_.operNumber = operNumber;
    va_start(ap, operNumber);
    for(i = 0; i < operNumber; i++)
        syntaxTree->operNode_.op[i] = va_arg(ap, synTree_*);
    
    va_end(ap);

    return syntaxTree;
}


// generateFuncNode(funcName, param, stmt_list, returnVal)
// generateFuncNode(funcName, param, stmt_list, returnVal, local)
void generateFuncNode(char* funcName, int operNumber, synTree_* param, synTree_* stmt_list, char* returnId, ...) {
    va_list ap;
    synTree_ *syntaxTree;
    int i = 0;

    if((syntaxTree = malloc(sizeof(synTree_) + (operNumber)*sizeof(synTree_*) )) == NULL);
        
    while(i < func_num){
        if(!(strcmp(funcName, func_table[i]->functionNode_.funcName))){
            yyerror("Exist same Function\n");
            return;
        }
        i++;
    }

    func_num--;

    // strcpy(func_table[(func_num-1)]->functionNode_.funcName, funcName);
    // strcpy(func_table[(func_num-1)]->functionNode_.returnId, returnId);
    strcpy(syntaxTree->functionNode_.funcName, funcName);
    strcpy(syntaxTree->functionNode_.returnId, returnId);
    
    syntaxTree->type = Func;
    syntaxTree->functionNode_.op[0] = param;
    syntaxTree->functionNode_.op[1] = stmt_list;
    syntaxTree->functionNode_.funcNumber = func_num;

    va_start(ap, operNumber);
        syntaxTree->functionNode_.op[2] = va_arg(ap, synTree_*);
    va_end(ap);

    func_table[func_num] = syntaxTree;
    // func_num++;
}

double evalFunc(char* funcName, synTree_* paramTree){
    synTree_ *functionTree;
    int i = 0;
    double result = 0;

    while(i < func_num){
        if(!(strcmp(funcName, func_table[i]->functionNode_.funcName))){
            break;
        }
        i++;
    }

    if(i > func_num){
        printf("No Function\n");
        return 0.0;
    }

    func_current_num = i;
    functionTree = func_table[i];
    funcEvalState = paramState;
    param_index = param_table[i].top;
    // printf("YES\n");
    i = eval(paramTree);

    funcEvalState = evalFuncState;

    // printf("func123 %d, %s, %s\n", Func, func_table[func_current_num]->functionNode_.funcName ,func_table[func_current_num]->functionNode_.returnId);
    // printf("wow: %f\n",eval(func_table[func_current_num]));
    // printf("YES: %s\n", func_table[func_current_num]->functionNode_.returnId);

    i = 0;
    // printf("func double: %s\n", local_table[func_current_num].table[0].id);
    while(i < local_table[func_current_num].top){
        // printf("func double1\n");
        if(!(strcmp(func_table[func_current_num]->functionNode_.returnId, local_table[func_current_num].table[i].id))){
            result = local_table[func_current_num].table[i].value;
            break;
        }
        i++;
    }

    if(i > local_table[func_current_num].top){
        printf("no,,,,,,,,\n");
    }
    // printf("local_top: %d, %s, %f\n",local_table[func_current_num].top, local_table[func_current_num].table[i].id, local_table[func_current_num].table[i].value);
    // printf("result: %f\n", result);

    return 0.0;
    
}

void freeNode(synTree_ *syntaxTree) {
    int i;

    if(!syntaxTree) return;
    if(syntaxTree->type == operatorVal) {
        for(i = 0; i < syntaxTree->operNode_.operNumber; i++)
            freeNode(syntaxTree->operNode_.op[i]);
    }
    free(syntaxTree);
}

double eval(synTree_ *syntaxTree) {
    int i = 0;

    if(!syntaxTree) return -1;
    switch (syntaxTree->type) {
        case Func:
            // printf("ffffffffffunc\n");
            
            return eval(syntaxTree->functionNode_.op[1]);
        case intVal:
            // printf("int1 \n");
            if(funcEvalState == notFuncState || param_index > 1){
                // printf("int\n");
                return syntaxTree->constNode_.value;
            }
            else if(funcEvalState == paramState) {
                param_table[func_current_num].table[0].value = syntaxTree->constNode_.value; 
                // printf("pa2 : %d, %s, %f \n", param_index, param_table[func_current_num].table[param_index-1].id, param_table[func_current_num].table[param_index-1].value);
                return 0.0;
            } else if(funcEvalState == evalFuncState) {
                // printf("func int %d\n", syntaxTree->constNode_.value );
                return syntaxTree->constNode_.value;
            }
        case doubleVal:
            if(funcEvalState == notFuncState || param_index > 1)
                return syntaxTree->doubleNode_.value;
            else if(funcEvalState == paramState) {
                param_table[func_current_num].table[0].value = syntaxTree->doubleNode_.value; 
                return 0.0;
            } else if(funcEvalState == evalFuncState) {
                // printf("func double\n");
                return syntaxTree->doubleNode_.value;
            }
        case normalId:
                if(funcEvalState == evalFuncState){
                   i = 0;
                        // printf("func double: %s\n", local_table[func_current_num].table[0].id);
                    while(i < local_table[func_current_num].top){
                        // printf("func double1\n");
                        if(!(strcmp(syntaxTree->idNode_.id, local_table[func_current_num].table[i].id))){
                            return local_table[func_current_num].table[i].value;
                        }
                        i++;
                    } 
                    i = 0;
                    while(i < param_table[func_current_num].top){
                        if(!(strcmp(syntaxTree->idNode_.id, param_table[func_current_num].table[i].id))){
                        // printf("func double find!!!!! %s, %f\n",param_table[func_current_num].table[i].id, param_table[func_current_num].table[i].value );
                            return param_table[func_current_num].table[i].value;
                        }
                        i++;
                    }
                }
                return sym_table[syntaxTree->idNode_.tableNumber].value;
        case operatorVal:
            switch(syntaxTree->operNode_.oper) {
                case WHILE: while(eval(syntaxTree->operNode_.op[0]))
                                eval(syntaxTree->operNode_.op[1]);
                            printf("while\n?- ");
                            return -1;
                case IF: printf("in IF\n");
                         if (eval(syntaxTree->operNode_.op[0])){
                            printf("thats truuuuue\n\n");
                            eval(syntaxTree->operNode_.op[1]);
                         }
                         else if (syntaxTree->operNode_.operNumber > 2)
                            eval(syntaxTree->operNode_.op[2]);
                         printf("if\n?- ");
                         return -1;
                case ';':   eval(syntaxTree->operNode_.op[0]); return eval(syntaxTree->operNode_.op[1]);
                case '=':  
                    if(funcEvalState == evalFuncState) {
                        i = 0;
                        while(i < local_table[func_current_num].top){
                            if(!(strcmp(syntaxTree->operNode_.op[0]->idNode_.id, local_table[func_current_num].table[i].id))){
                                break;
                            }
                            i++;
                        }
                        
                        local_table[func_current_num].table[i].value = eval(syntaxTree->operNode_.op[1]);
                        printf("local_top111: %d, %s, %f\n",local_table[func_current_num].top, local_table[func_current_num].table[i].id, local_table[func_current_num].table[i].value);
                        return local_table[func_current_num].table[i].value;
                    }else{
                        printf("notFunc\n");
                        return sym_table[syntaxTree->operNode_.op[0]->idNode_.tableNumber].value = eval(syntaxTree->operNode_.op[1]); 
                    }
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
                case ',':    {
                    printf("YES\n");
                    param_table[func_current_num].table[param_index-1].value = eval(syntaxTree->operNode_.op[1]); 
                    printf("pa1 : %d, %s, %f \n", param_index, param_table[func_current_num].table[param_index-1].id, param_table[func_current_num].table[param_index-1].value);
                    param_index--;
                    eval(syntaxTree->operNode_.op[0]);
                }
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
    int i = 0;

    sym_table = (symtable*)malloc(20*sizeof(symtable));
    param_table = (functable*)malloc(20*sizeof(functable));
    local_table = (functable*)malloc(20*sizeof(functable));

    for(i = 0; i<20; i++){
        func_table[i] = (synTree_*)malloc(20*sizeof(synTree_));
    }

    
    if((syntaxTree = malloc(sizeof(synTree_))) == NULL);
    printf("?- ");
    yyparse();

    return 0;
}