%{
#include <stdio.h>
#include <ctype.h>
%}

%token NUMBER

%%

line    :   expr '\n'       { printf("%d\n", $1); }
        ;

expr    :   expr '+' term   { $$ = $1 + $3; }
        |   expr '-' term   { $$ = $1 - $3; }
        |   term
        ;

term    : term '*' factor   { $$ = $1 * $3; }
        | term '/' factor   { $$ = $1 / $3; }
        | factor
        ;

factor  : '(' expr ')'      { $$ = $2; }
        | NUMBER            { $$ = $1; }
        ;

%%

int yylex()
{
    int c;
    while (1) {
        c = getchar();
        if(c == '' || c == '\t');
        else if(isdigit(c)) {
            yylval = c - '0';
            return DIGIT;
        }
        else return c;
    }
}

int main()
{
    if(yyparse() == 0) printf("파싱 성공!! \n\n");
    else printf("파싱 실패!! \n\n");
}
