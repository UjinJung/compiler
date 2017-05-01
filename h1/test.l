%{
extern char yylval[100];
extern char yylID[17];
extern char yylINT[11];

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

char sym_table[10][17];
char str_table[10][100];

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

"exit"  {return EXIT;}
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

struct SyntaxTree_* exp();
struct SyntaxTree_* restexp();
struct SyntaxTree_* term();
struct SyntaxTree_* restterm();
struct SyntaxTree_* factor();

typedef struct SyntaxTree_ {
    int  Type;
    int  number;
    struct SyntaxTree_ *left;
    struct SyntaxTree_ *right;
} st;

struct SyntaxTree_* parsing (void) {
    st* parsingR;

	parsingR = (st*)malloc(sizeof(st));

    tok = yylex();
    printf("parsing\n");
    parsingR = exp();
    return parsingR;
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

    if(restexpT->right->Type == EPSILON){
        expR->Type = restexpT->Type;
        expR->left = termT;
        expR->right = restexpT->left;
    } else{
        expR->Type = PLUS;
        expR->left = termT;
        expR->right = restexpT;
    }
    return expR;
}

struct SyntaxTree_* restexp() {
	st* termT;
	st* restexpT;
	st* restexpR;

	termT = (st*)malloc(sizeof(st));
	restexpT = (st*)malloc(sizeof(st));
	restexpR = (st*)malloc(sizeof(st));

    printf("restTokenpre%d\n",tok);
    //if((tok=yylex())!=111){
    if(tok!=111){
        printf("restTokenafter%d\n",tok);
    	if (tok == PLUS) {
    		tok = yylex();
            printf("PLUS%d\n",tok);
    		termT = term();
    		//termT = factor();
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
    		//termT = factor();
    		restexpT = restexp();

    		restexpR->Type = PLUS;
    		restexpR->left = termT;
    		restexpR->right = restexpT;

    		return restexpR;
    	}
    }else{
        printf("noToken%d\n",tok);
        restexpR->Type = EPSILON;
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

	factorT = factor();
	resttermT = restterm();

    if(resttermT->right->Type == EPSILON){
        termR->Type = resttermT->Type;
        termR->left = factorT;
        termR->right = resttermT->left;
    } else{
        termR->Type = MULTI;
    	termR->left = factorT;
    	termR->right = resttermT;
    }

    return termR;
}

struct SyntaxTree_* restterm() {
	st* factorT;
	st* resttermT;
	st* resttermR;

	factorT = (st*)malloc(sizeof(st));
	resttermT = (st*)malloc(sizeof(st));
	resttermR = (st*)malloc(sizeof(st));

    //if((tok=yylex())!=111){
    if(tok!=111){
    	if (tok == MULTI) {
    		tok = yylex();
    		factorT = factor();
    		resttermT = restterm();

    		resttermR->Type = MULTI;
    		resttermR->left = factorT;
    		resttermR->right = resttermT;

    		return resttermR;
    	}
    	else if (tok == DIV) {
    		tok = yylex();
    		factorT = factor();
    		resttermT = restterm();

    		resttermR->Type = DIV;
    		resttermR->left = factorT;
    		resttermR->right = resttermT;

    		return resttermR;
    	}
    }else{
        printf("noToken%d\n",tok);
        resttermR->Type = EPSILON;
        return resttermR;
    }
}

struct SyntaxTree_* factor() {
	st* expT;
	st* expR;
	int value;

	expT = (st*)malloc(sizeof(st));
	expR = (st*)malloc(sizeof(st));

    printf("factor%d\n",tok);
	if (tok == LBRACE) {
		tok = yylex();
		expT = exp();
        printf("expEnd%d\n",tok);
		//tok = yylex();
		if (tok == RBRACE) {
		    tok = yylex();
			return expT;
		}
		///// error
	}
	else if (tok == MINUS) {
		tok = yylex();
		expT = exp();

		expR->Type = UNARY;
		expR->left = expT;

		return expR;
	}
	else if (tok == INTEGERS) {
        printf("integer\n");
		value = atoi(yylINT);
		tok = yylex();

        printf("integer2\n");
		expR->Type = INTEGERS;
		expR->number = value;

        printf("exprNUM %d\n", expR->number);
		return expR;
	}
	return expR;
}

int eval(st* st) {
	int v1;
	int v2;

	if (st->Type == INTEGERS) {
		return st->number;
	}
	else if (st->Type == UNARY) {
		return -eval(st->left);
	}
	else {
		v1 = eval(st->left);
		v2 = eval(st->right);
		if (st->Type == PLUS) {
			return v1 + v2;
		}
		else if (st->Type == MINUS) {
			return v1 - v2;
		}
		else if (st->Type == MULTI) {
			return v2*v2;
		}
		else if (st->Type == DIV) {
			return v1 / v2;
		}
	}
	return 0;
}

int main(void){
//    int tok;
    int i = 0;
	st* syntaxTreeT;
	st* left;
	st* right;

	syntaxTreeT = (st*)malloc(sizeof(st));
	left = (st*)malloc(sizeof(st));
	right = (st*)malloc(sizeof(st));

	//tok = yylex();
	left->number = 10;
	left->Type = INTEGERS;
	right->number = 20;
	right->Type = INTEGERS;

	syntaxTreeT->left = left;
	syntaxTreeT->right = right;
	syntaxTreeT->Type = PLUS;

	syntaxTreeT = parsing();
//	i = eval(syntaxTreeT);
	printf("%d", i);
}
