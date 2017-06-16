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

int id_num = 1;
int str_num = 1;
int ind = 0;

char sym_table[10][17];
char str_table[10][100];

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
%}

blank [ \t\n]+
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
{operators} {strcpy(yylval, yytext); return OPERATORS;}
{sp_char} {strcpy(yylval, yytext); return OPERATORS;}
{identifiers} {strcpy(yylID, yytext); return IDENTIFIERS;}
{integers} {strcpy(yylINT, yytext); return INTEGERS;}
{blank} {}
%%

char yylval[100];
char yylID[17];
char yylINT[11];

typedef struct SyntaxTree_ {
    char*   Type    = NULL;
    double  number  = 0;
    st*     left    = NULL;
    st*     right   = NULL;
} st;

st* parsing (void) {
    int tok;

    tok = yylex();

    return expression();
}

st* exp(){
    st* termT       = term();
    st* restexpT    = restexp();
    st* expR        = NULL;

    expR.Type       = "PLUS";
    expR.left       = termT;
    expR.right      = restexp();

    return expR;
}

st* restexp(){
    st* termT;
    st* restexpT;
    st* restexpR;

    if(tok == PLUS){
        tok         = yylex();
        termT       = term();
        restexpT    = restexp();

        restexpR.Type   = "PLUS";
        restexpR.left   = termT;
        restexpR.right  = restexpT;

        return restexpR;
    }else if(tok == MINUS){
        tok         = yylex();
        termT       = term();
        restexpT    = restexp();

        restexpR.Type   = "PLUS";
        restexpR.left   = termT;
        restexpR.right  = restexpT;

        return restexpR;
    }

}
 st* term(){
    st* factorT     = factor();
    st* resttermT   = restterm();
    st* termR;

    termR.Type      = "MULTI";
    termR.left      = factorT;
    termR.right     = resttermT;

    return termR;
}

st* restterm() {
    st* factorT;
    st* resttermT;
    st* resttermR;

    if(tok == MULTI){
        tok         = yylex();
        factorT       = factor();
        resttermT    = restterm();

        resttermR.Type   = "MULTI";
        resttermR.left   = factorT;
        resttermR.right  = resttermT;

        return resttermR;
    }else if(tok == DIV){
        tok         = yylex();
        factorT     = factor();
        resttermT   = restterm();

        resttermR.Type   = "DIV";
        resttermR.left   = factorT;
        resttermR.right  = resttermT;

        return resttermR;
    }

}

st* factor(){
    st* expT;
    st* expR;
    double value;

    if(tok == LBRACE){
        tok     = yylex();
        expT    = exp();
        tok     = yylex();
        if(tok == RBRACE){
            return expT;
        }
        ///// error
    } else if (tok == MINUS) {
        tok     = yylex();
        expT    = exp();

        expR.Type   = "UNARY";
        expR.left   = expT;

        return expR;
    } else if(tok == INTEGERS){
        value   = atoi(yylINT);
        tok     = yylex();

        expR.Type   = "INTEGERS";
        expR.number = value;

        return expR;
    }
}

int main(void){
    int tok;
    int i = 0;
    printf("TOKEN\t\t\t\tLEXEME\n");
    while((tok=yylex())!=0){
        if(tok==KEYWORDS){
            printf("<%s>\t\t\t",strupr(yylval));
            if(strlen(yylval) < 6 )
                printf("\t");
            printf("%s\n",strlwr(yylval));
        } else if(tok==IDENTIFIERS){
            i = 0;
            while(i < id_num){
                if(!(strcmp(yylID, sym_table[i]))){
                    i++; break;
                }
                i++;
            }

            if(i >= id_num){
                if(strlen(yylID) > 16)
                    yylID[16] = '\0';
                strcpy(sym_table[(id_num-1)], yylID);
                id_num++;
            }
            printf("<ID, %3d>\t\t\t",i);
            printf("%s\n",yylID);

        }else if(tok==INTEGERS){
            if(strlen(yylINT) > 10)
                yylINT[10] = '\0';

            printf("<INUM, %s>\t\t",yylINT);
            if(strlen(yylINT) < 5 )
                printf("\t");
            else if(strlen(yylINT) < 9)
                printf("\t");
            printf("%s\n",yylINT);

        }  else if(tok == FLOAT){
            if(strlen(yylval) > 8)
                yylval[8] = '\0';

            printf("<FLOAT, %s>\t\t",yylval);
            if(strlen(yylval) < 7)
                printf("\t");
            printf("%s\n",yylval);

        }
        else if(tok==OPERATORS){
        // ( ) + - * / ++ -- < > = ! <= >= ==
        // != += -= *= /= %= && ||
        // " \ [ ] ; ,
            if(!strcmp(yylval, "(" ))
                printf("<%s>\t","LBRAC");
            else if(!strcmp(yylval, ")" ))
                printf("<%s>\t","RBRAC");
            else if(!strcmp(yylval, "{" ))
                printf("<%s>","LCBRAC");
            else if(!strcmp(yylval, "}" ))
                printf("<%s>","RCBRAC");
            else if(!strcmp(yylval, "+" ))
                printf("<%s>\t","ADD");
            else if(!strcmp(yylval, "-" ))
                printf("<%s>\t","SUB");
            else if(!strcmp(yylval, "*" ))
                printf("<%s>","MULTIPLE");
            else if(!strcmp(yylval, "/" ))
                printf("<%s>","DIVIDE");
            else if(!strcmp(yylval, "%" ))
                printf("<%s>\t","MOD");
            else if(!strcmp(yylval, "++" ))
                printf("<%s>\t","INCRE");
            else if(!strcmp(yylval, "--" ))
                printf("<%s>\t","DECRE");
            else if(!strcmp(yylval, "<" ))
                printf("<%s>","LESSTHAN");
            else if(!strcmp(yylval, ">" ))
                printf("<%s>","MORETHAN");
            else if(!strcmp(yylval, "=" ))
                printf("<%s>","ASSIGN");
            else if(!strcmp(yylval, "!" ))
                printf("<%s>\t","NOT");
            else if(!strcmp(yylval, "<=" ))
                printf("<%s>","EQULES");
            else if(!strcmp(yylval, ">=" ))
                printf("<%s>","EQUMOR");
            else if(!strcmp(yylval, "==" ))
                printf("<%s>\t","SAME");
            else if(!strcmp(yylval, "!=" ))
                printf("<%s>","NOTSAME");
            else if(!strcmp(yylval, "+=" ))
                printf("<%s>","ADDASSIGN");
            else if(!strcmp(yylval, "-=" ))
                printf("<%s>","SUBASSIGN");
            else if(!strcmp(yylval, "*=" ))
                printf("<%s>","MULASSIGN");
            else if(!strcmp(yylval, "/=" ))
                printf("<%s>","DIVASSIGN");
            else if(!strcmp(yylval, "%=" ))
                printf("<%s>","MODASSIGN");
            else if(!strcmp(yylval, "&&" ))
                printf("<%s>\t","AND");
            else if(!strcmp(yylval, "||" ))
                printf("<%s>\t","OR");
        // " \ [ ] ; ,
            else if(!strcmp(yylval, "\""))
                printf("<%s>","DOUBLEQUOUT");
            else if(!strcmp(yylval, "\\"))
                printf("<%s>","BACKSLASH");
            else if(!strcmp(yylval, "["))
                printf("<%s>","LSBRAC");
            else if(!strcmp(yylval, "]"))
                printf("<%s>","RSBRAC");
            else if(!strcmp(yylval, ";"))
                printf("<%s>","SEMICOLON");
            else if(!strcmp(yylval, ","))
                printf("<%s>\t","COMMA");

            printf("\t\t\t%s\n",yylval);
        }else if(tok==STRINGS){
            i = 0;
            strcpy(str_table[(str_num-1)], yylval);
            printf("<STRING, %d>\t\t\t%s\n",str_num,str_table[(str_num-1)]);
            str_num++;
        }else if(tok==COMMENTS)
            printf("<COMMENT>\t\t\t%s\n",yylval);
        else if(tok==EXIT)
            break;
        else {
            printf("<?>\t\t\t%s\n",yylval);
        }
    }

    i = 0;
    printf("\n\n");
    printf("index\t\tsymbols\n");
    while(i < id_num-1){
        printf("%d\t\t%s\n",i+1,sym_table[i]);
        i++;
    }
    printf("\n\n");
    i = 0;
    printf("index\t\tstrings\n");
    while(i < str_num-1){
        printf("%d\t\t%s\n",i+1,str_table[i]);
        i++;
    }

}
