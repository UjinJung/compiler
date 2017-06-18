typedef enum { intVal,
               doubleVal,
               operatorVal,
               normalId,
               paramId,
               localId,
               Func} nodeEnum;

typedef enum {  notFuncState, 
                paramState,
                evalFuncState 
             } funcStateEnum;

typedef struct {
    char id[17];
    double value;
    char isAssign;
} symtable;

typedef struct {
    char funcName[17];
    int top;
    symtable table[20];
} functable;

typedef struct
{
    int value;
} constNode;

typedef struct
{
    double value;
} doubleNode;

typedef struct
{
    char id[17];
    int tableNumber; 
    struct nodeType *op[1];
    // double value;
} idNode;

typedef struct
{
    int oper;
    int operNumber;
    struct nodeType *condition[1];
    struct nodeType *op[1];
} oprNode;

typedef struct
{
    int operNumber;
    char funcName[17];
    char returnId[17];
    int funcNumber;
    struct nodeType *op[1];
} functionNode;

typedef struct nodeType
{
    nodeEnum type;

    union {
        constNode constNode_;
        doubleNode doubleNode_;
        idNode idNode_;
        oprNode operNode_;
        functionNode functionNode_;
    };
} synTree_;

extern char controlState;
extern char funcState;
extern symtable* sym_table;
extern functable* param_table;
extern functable* local_table;

extern synTree_* func_table[20];
