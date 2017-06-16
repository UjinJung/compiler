%{
extern char yylval[100];
extern char yylID[17];
extern char yylINT[11];
extern char syntaxError_ = 0;
extern char exit_ = 0;


#define LETTER 13
#define DIGIT 12
#define KEYWORDS 1
#define IDENTIFIERS 2
#define INTEGERS 3
#define FLOAT 4
#define STRINGS 5
#define OPERATORS 6
#define SP_CHAR 7
#define COMMENTS 8
#define DOUBLE_QUOT 9
#define ETC 10
#define EXIT    111

#define PLUS    21
#define MINUS   22
#define MULTI   23
#define DIV     24
#define ASSIGN  25
#define UNARY   26
#define LBRACE  27
#define RBRACE  28
#define EPSILON 29

int id_num = 1;
int str_num = 1;
int ind = 0;


#include <string.h>
#include <stdio.h>
#include <stdlib.h>
%}

blank [ \t]+
letter [a-zA-Z]
digit [0-9]
float {digit}"."{digit}+
comments (\/\*([^\*\/]\n|.)*\*\/)|(\/\*([^\*\/].|\n)*\*\/)
commentsOneline "//".*\n
keywords "int"|"char"|"double"|"void"|"if"|"else"|"for"|"while"|"return"
identifiers ({letter}|("_"({letter}|{digit})))("_"|{letter}|{digit})*
integers ([1-9][0-9]*)|0
sp_char ("\""|"\\"|"["|"]"|";"|",")
string \".*\"
string2 \".*\\\".*\"


%%
"+"     {strcpy(yylval, yytext); return PLUS; }
"-"     {strcpy(yylval, yytext); return MINUS; }
"*"     {strcpy(yylval, yytext); return MULTI; }
"/"     {strcpy(yylval, yytext); return DIV; }
"="     {strcpy(yylval, yytext); return ASSIGN; }
"("     {strcpy(yylval, yytext); return LBRACE; }
")"     {strcpy(yylval, yytext); return RBRACE; }
"\n"    {return EXIT;}

"exit"  {exit_ = 1; return EXIT;}
{float} {strcpy(yylval, yytext); return FLOAT;}
{comments} {strcpy(yylval, yytext); return COMMENTS;}
{commentsOneline} {strncpy(yylval, yytext, strlen(yytext)-1); return COMMENTS;}
{keywords} {strcpy(yylval, yytext); return KEYWORDS;}
{string2} {
    strcpy(yylval, yytext);
    while(ind < strlen(yytext)) {
        if(yylval[ind] == '\\' ) {
            yylval[ind] = '\0';
            strcat(yylval, yytext+ind+1);
        }
        ind++;
    }
    return STRINGS;
}
{string} {strcpy(yylval, yytext); return STRINGS;}
{sp_char} {strcpy(yylval, yytext); return OPERATORS;}
{identifiers} {strcpy(yylID, yytext); return IDENTIFIERS;}
{integers} {strcpy(yylINT, yytext); return INTEGERS;}
{blank} {}
%%

char yylval[100];
char yylID[17];
char yylINT[11];
int tok = 0;
char syntaxError_;
char exit_;

struct SyntaxTree_* exp();
struct SyntaxTree_* restexp();
struct SyntaxTree_* term();
struct SyntaxTree_* restterm();
struct SyntaxTree_* assign();
struct SyntaxTree_* restassign();
struct SyntaxTree_* factor();

typedef struct SyntaxTree_ {
    int  Type;
    //int  number;
    double  number;
    char id[17];
    struct SyntaxTree_ *left;
    struct SyntaxTree_ *right;
} st;

typedef struct SymTable_ {
    char id[17];
    double  value;
    //int value;
} symtable;

struct SymTable_* sym_table;
char str_table[10][100];

struct SyntaxTree_* parsing (void) {
    st* parsingR;

	parsingR = (st*)malloc(sizeof(st));

    tok = yylex();
    if(tok == EXIT){
        exit_ = 1;
        return parsingR;
    }else{
        printf("parsing\n");
        parsingR = assign();
        return parsingR;
    }
}

struct SyntaxTree_* assign() {
	st* expT;
	st* restassignT;
	st* assignR;

	expT = (st*)malloc(sizeof(st));
	restassignT = (st*)malloc(sizeof(st));
	assignR = (st*)malloc(sizeof(st));

    printf("assign\n");
	expT = exp();
	restassignT = restassign();

	assignR->Type = EPSILON;
	assignR->left = expT;
	assignR->right = restassignT;

	return assignR;
}

struct SyntaxTree_* restassign() {
	st* expT;
	st* restassignT;
	st* restassignR;

	expT = (st*)malloc(sizeof(st));
	restassignT = (st*)malloc(sizeof(st));
	restassignR = (st*)malloc(sizeof(st));

    printf("restassign\n");
    if(tok!=111){
    	if (tok == ASSIGN) {
    		tok = yylex();
    		expT = exp();
    		restassignT = restassign();

    		restassignR->Type = ASSIGN;
    		restassignR->left = expT;
    		restassignR->right = restassignT;

    		return restassignR;
    	}
        restassignR->Type = EPSILON;
        return restassignR;
    }else{
        restassignR->Type = EPSILON;
        printf("noToken%d\n",tok);
        return restassignR;
    }
}

struct SyntaxTree_* exp() {
	st* termT;
	st* restexpT;
	st* expR;

	termT = (st*)malloc(sizeof(st));
	restexpT = (st*)malloc(sizeof(st));
	expR = (st*)malloc(sizeof(st));

    printf("exp\n");
    termT = term();
    restexpT = restexp();
    expR->Type = EPSILON;
    expR->left = termT;
    expR->right = restexpT;

	return expR;
}

struct SyntaxTree_* restexp() {
	st* termT;
	st* restexpT;
	st* restexpR;

	termT = (st*)malloc(sizeof(st));
	restexpT = (st*)malloc(sizeof(st));
	restexpR = (st*)malloc(sizeof(st));

    printf("restexp%d\n",tok);
    if(tok!=111){
    	if (tok == PLUS) {
    		tok = yylex();
            printf("PLUS%d\n",tok);
    		termT = term();
    		//termT = exp();
            printf("PLUS%d\n",tok);
    		restexpT = restexp();

    		restexpR->Type = PLUS;
    		restexpR->left = termT;
    		restexpR->right = restexpT;

    		return restexpR;
    	}
    	else if (tok == MINUS) {
    		tok = yylex();
    		termT = term();
    		//termT = exp();
    		restexpT = restexp();

    		restexpR->Type = MINUS;
    		restexpR->left = termT;
    		restexpR->right = restexpT;

    		return restexpR;
    	}

        restexpR->Type = EPSILON;
        return restexpR;
    }else{
        restexpR->Type = EPSILON;
        printf("noToken%d\n",tok);
        return restexpR;
    }
}

struct SyntaxTree_* term() {
	st* factorT;
	st* resttermT;
	st* termR;

	factorT = (st*)malloc(sizeof(st));
	resttermT = (st*)malloc(sizeof(st));
	termR = (st*)malloc(sizeof(st));

    printf("term\n");
	factorT = factor();
	resttermT = restterm();

	termR->Type = EPSILON;
	termR->left = factorT;
	termR->right = resttermT;

	return termR;
}

struct SyntaxTree_* restterm() {
	st* factorT;
	st* resttermT;
	st* resttermR;

	factorT = (st*)malloc(sizeof(st));
	resttermT = (st*)malloc(sizeof(st));
	resttermR = (st*)malloc(sizeof(st));

    printf("restterm\n");
    if(tok!=111){
    	if (tok == MULTI) {
    		tok = yylex();
            printf("MULTI\n");
    		factorT = factor();
    		resttermT = restterm();

    		resttermR->Type = MULTI;
    		resttermR->left = factorT;
    		resttermR->right = resttermT;

    		return resttermR;
    	}
    	else if (tok == DIV) {
    		tok = yylex();
            printf("DIV\n");
    		factorT = factor();
    		resttermT = restterm();

    		resttermR->Type = DIV;
    		resttermR->left = factorT;
    		resttermR->right = resttermT;

    		return resttermR;
    	}
        resttermR->Type = EPSILON;
        return resttermR;
    }else{
        resttermR->Type = EPSILON;
        printf("noToken%d\n",tok);
        return resttermR;
    }
}



struct SyntaxTree_* factor() {
	st* expT;
	st* expR;
	int value;
    int i = 0;

	expT = (st*)malloc(sizeof(st));
	expR = (st*)malloc(sizeof(st));

    printf("factor%d\n",tok);
	if (tok == LBRACE) {
		tok = yylex();
		expT = exp();
        printf("expEnd%d\n",tok);
		if (tok == RBRACE) {
		    tok = yylex();
			return expT;
		}
		syntaxError_ = 1;
        return 0;
	}
	else if (tok == MINUS) {
        printf("UNARY!!!!\n");
		tok = yylex();
		expT = exp();

        expR->Type = UNARY;
		expR->left = expT;

		return expR;
	}
	else if (tok == INTEGERS) {
		value = atoi(yylINT);
		tok = yylex();

		expR->Type = INTEGERS;
		expR->number = value;

        printf("exprNUM %d\n", expR->number);
		return expR;
	}else if (tok == FLOAT) {
        value = atof(yylval);
		tok = yylex();

		expR->Type = FLOAT;
		expR->number = value;

        printf("exprNUM %d\n", expR->number);
		return expR;
	}else if (tok == IDENTIFIERS) {
        printf("id\n");
        i = 0;
        while(i < id_num){
            if(!(strcmp(yylID, sym_table[i].id))){
                i++; break;
            }
            i++;
        }

        if(i >= id_num){
            if(strlen(yylID) > 16)
                yylID[16] = '\0';
            strcpy(sym_table[(id_num-1)].id, yylID);
            strcpy(expR->id, sym_table[(id_num-1)].id);
            sym_table[id_num-1].value = -1;
            printf("%s = %d\n",sym_table[(id_num-1)].id, sym_table[(id_num-1)].value);

            id_num++;
        }else{
            strcpy(expR->id, sym_table[(i-1)].id);
            printf("%s = %d\n",sym_table[(i-1)].id, sym_table[(i-1)].value);
        }
        expR->Type = IDENTIFIERS;
        tok = yylex();

        return expR;
	}else{
        printf("ERROR!!!!\n");
        syntaxError_ = 1;
        return 0;
    }
}

struct SyntaxTree_* buildST(st* synTree) {
    printf("SynTree IN!!\n");

    if(synTree->Type == INTEGERS || synTree->Type == FLOAT){
        printf("INTEGERS!!\n");
        return synTree;
    }else if(synTree->Type == UNARY){
        printf("UNARY\n");
        synTree->left = buildST(synTree->left);
        return synTree;
    }else if(synTree->Type == IDENTIFIERS){
        printf("IDENTIFIERS\n");
        return synTree;
    }else if(synTree->right->Type == EPSILON || synTree->right->Type == 0){
        printf("rightEpsilon\n");
        synTree = buildST(synTree->left);
        printf("out!!\n");
        return synTree;
    }else if(synTree->right->Type == PLUS ||
            synTree->right->Type == MINUS ||
            synTree->right->Type == MULTI ||
            synTree->right->Type == DIV ||
            synTree->right->Type == ASSIGN
            )
    {
        printf("right%d\n",synTree->right->Type);
        synTree->Type = synTree->right->Type;
        synTree->right->Type = EPSILON;
        synTree->left = buildST(synTree->left);
        printf("%d\n",synTree->left->Type);
        synTree->right = buildST(synTree->right);
        return synTree;
    }else{
        printf("NO\n");
        synTree->left = buildST(synTree->left);
        synTree->right = buildST(synTree->right);
        return synTree;
    }

}

//int eval(st* synTree) {
double eval(st* synTree) {
	int v1;
	int v2;
    int assignI;
    static int i = 0;

	if (synTree->Type == INTEGERS) {
        printf("INTEGERS\n");
		return synTree->number;
	}
    else if (synTree->Type == IDENTIFIERS) {
        i = 0;
        printf("INDENTIFIERS\n");
        while(i < id_num){
            if(!(strcmp(synTree->id, sym_table[i].id))){
                i++; break;
            }
            i++;
        }
        if(i > id_num){
            // no id
            printf("NO ID!!!!!!!!!!!!!!!\n");
        }else{
            printf("identifier : %s = %d\n",sym_table[i-1].id, sym_table[i-1].value);
            return sym_table[i-1].value;
        }
    }
	else if (synTree->Type == UNARY) {
        printf("UNARY\n");
        v1 = eval(synTree->left);
        printf("-v1 = %d\n",-v1);
		return -v1;
	}else if (synTree->Type == ASSIGN) {
        printf("ASSIGN\n");
        if(synTree->left->Type != IDENTIFIERS){
            printf("syntax Error!!\n");
            syntaxError_ = 1;
            return 0;
        } else{
            i = 0;
            while(i < id_num){
                if(!(strcmp(synTree->left->id, sym_table[i].id))){
                    i++; break;
                }
                i++;
            }
            if(i > id_num){
                // no id error
            }else{
                assignI = i-1;
                printf("%d\n",assignI);
                sym_table[assignI].value = eval(synTree->right);
                printf("end Assign %s = %d\n",sym_table[assignI].id, sym_table[assignI].value);
                return sym_table[assignI].value;
            }
        }
        printf("v1=v2\n");
    }
	else {
		v1 = eval(synTree->left);
		v2 = eval(synTree->right);
		if (synTree->Type == PLUS) {
            printf("plus\n");
            printf("v1+v2 = %d\n",v1+v2);
			return v1 + v2;
		}else if (synTree->Type == MINUS) {
            printf("minus\n");
            printf("v1-v2 = %d\n",v1-v2);
			return v1 - v2;
		}else if (synTree->Type == MULTI) {
            printf("MUL\n");
            printf("v1*v2 = %d\n",v1*v2);
			return v1*v2;
		}else if (synTree->Type == DIV) {
            printf("div\n");
            printf("v1/v2 = %d\n",v1/v2);
			return v1/v2;
        }
	}
	return 0;
}

int main(void){
    int i = 0;
	st* parseTree;
	st* synTree;
	st* right;

    sym_table = (symtable*)malloc(20*sizeof(symtable));
	parseTree = (st*)malloc(sizeof(st));
	synTree = (st*)malloc(sizeof(st));
	right = (st*)malloc(sizeof(st));

	//tok = yylex();
	//left->number = 10;
	//left->Type = INTEGERS;
	//right->number = 20;
	//right->Type = INTEGERS;

	//synTree->left = left;
	//synTree->right = right;
	//synTree->Type = PLUS;

    while( !(syntaxError_ == 1)){

    	parseTree = parsing();
        printf("\n\n");
        if(exit_ == 1){
            break;
        }else if(syntaxError_ == 1){
            printf("syntaxError!!\n");
            break;
        }
        synTree = buildST(parseTree);
        printf("%d\n", synTree->Type);
        printf("\n\n\n");
    	i = eval(synTree);
    	printf("%d\n", i);
    }
}
