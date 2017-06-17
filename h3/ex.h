typedef enum { typeCo,
               typeId,
               typePr,
               typeDouble } nodeEnum;

typedef struct SymTable_{
    char id[17];
    double value;
    char isAssign;
} symtable;

typedef struct
{
    int value;
} constNode;

typedef struct
{
    int value;
} functionNode;

typedef struct
{
    double value;
} doubleNode;

typedef struct
{
    char id[17];
    int tableNumber; 
    double value;
} idNode;

typedef struct
{
    int oper;
    int operNumber;
    struct nodeType *op[1];
} oprNode;

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

extern struct SymTable_* sym_table;
extern int symTable[100];
extern char controlStmt;
