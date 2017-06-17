%{
    #include <stdlib.h>
    #include "ex.h"
    #include "y.tab.h"
    #include <string.h>
    #include <stdio.h>
%}

blank           [ \t\n]+
letter          [a-zA-Z]
digit           [0-9]
float           {digit}"."{digit}*
comments        (\/\*([^\*\/]\n|.)*\*\/)|(\/\*([^\*\/].|\n)*\*\/)
commentsOneline "//".*\n
keywords        "int"|"char"|"double"|"void"|"if"|"else"|"for"|"while"|"return"
identifiers     ({letter}|("_"({letter}|{digit})))("_"|{letter}|{digit})*
integers        ([1-9][0-9]*)|0
sp_char         ("\""|"\\"|"["|"]"|";"|",")
string          \".*\"
string2         \".*\\\".*\"
lexi            .*\n

%%

{letter}    { 
    yylval.sIndex = *yytext - 'a'; 
    return VARIABLE; 
}
{float}     {
    yylval.iValue = atof(yytext);
    return FLOAT;
}
{integers}   {
    yylval.iValue = atoi(yytext);
    return INTEGER;
}


">="        return GE;
"<="        return LE;
"=="        return EQ;
"!="        return NE;

{blank}     ;

.           return *yytext;
%%

int yywrap(void){
    return 1;
}