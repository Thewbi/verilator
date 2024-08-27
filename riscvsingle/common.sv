package common;

parameter WIDTH = 4;

typedef enum logic [1:0] {
     add     = 2'h0,
     sub     = 2'h1,
     nop     = 2'h2
} operation_t /*verilator public*/;

endpackage;