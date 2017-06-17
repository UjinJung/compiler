%{
#include <stdlib.h>
#include "ex.h"
#include "y.tab.h"
void yyerror(char *);
%}

blank [ \t\n]+
letter [a-zA-Z]
digit [0-9]
float {digit}"."{digit}*
integers ([1-9][0-9]*)|0
sp_char ("\""|"\\"|"["|"]"|";"|",")
identifiers ({letter}|("_"({letter}|{digit})))("_"|{letter}|{digit})*
operator ("+"|"-"|"*"|"/"|"("|")"|"<"|">"|"="|"{"|"}"|".")
string \".*\"
string2 \".*\\\".*\"
lexi .*\n

%%

{integers} {
    yylval.ival = atoi(yytext);
    return INTEGER;
}

{float} {
    yylval.dval = atof(yytext);
    return DOUBLE;
}

{sp_char} {
    return *yytext;
}

{operator} {
    return *yytext;
}

">="    return GE;
"<="    return LE;
"=="    return EQ;
"!="    return NE;
"while" { controlStmt = 1; return WHILE; }
"if"    { printf("> "); controlStmt = 1; return IF; }
"else"  { printf("> "); return ELSE; }
"end"   { controlStmt = 0; return END; }
"def"   return DEF;

{identifiers} {
    strcpy(yylval.sIndex, yytext);
    return VARIABLE;
}

{blank} ; /* ignore whitespace */

. yyerror("lexical error");
%%
int yywrap(void) {
 return 1;
}


