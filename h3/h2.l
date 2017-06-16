%{
#include <stdlib.h>
#include "h2.tab.h"
%}

%%

[ \t]+              ;
[0-9]+              { yylval = atoi(yytext); return NUMBER; }
[+\-\*\/\(\)\n]     return yytext[0];
