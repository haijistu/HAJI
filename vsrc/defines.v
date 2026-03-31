`define ALU_ADD     4'b0000
`define ALU_SUB     4'b1000
`define ALU_SLL     4'b0001
`define ALU_SLT     4'b0010
`define ALU_SLTU    4'b1010
`define ALU_B       4'b0011
`define ALU_XOR     4'b0100
`define ALU_SRL     4'b0101
`define ALU_SRA     4'b1101
`define ALU_OR      4'b0110
`define ALU_AND     4'b0111
`define ALU_AUIPC   4'b1001

`define LOAD_LB     4'b0000
`define LOAD_LH     4'b0001
`define LOAD_LW     4'b0010
`define LOAD_LBU    4'b0100
`define LOAD_LHU    4'b0101

`define STORE_SB    4'b1000
`define STORE_SH    4'b1001
`define STORE_SW    4'b1010

`define BRANCH_BEQ  4'b0000
`define BRANCH_BNE  4'b0001
`define BRANCH_BLT  4'b0010
`define BRANCH_BGE  4'b0011
`define BRANCH_BLTU 4'b0100
`define BRANCH_BGEU 4'b0101

`define JUMP_JAL    4'b1000
`define JUMP_JALR   4'b1001

// 数据宽度
`define WORD_WIDTH      32
`define PADDR_WIDTH     32
`define OP_WIDTH        4
`define FU_TYPE_WIDTH   5
`define REG_ADDR_WIDTH  5
`define REG_NUM         32
`define PREG_ADDR_WIDTH 7
`define PREG_NUM        128
`define CSR_ADDR_WIDTH  12
`define EXC_EVENT_WIDTH 2

`define ZERO_WORD       32'h0
`define NOP_INST        32'b00000000000000000000000000010011

`define INIT_PC         32'h30000000

`define CSR_MCYCLE      12'hb00
`define CSR_MCYCLEH     12'hb80
`define CSR_MVENDORID   12'hf11
`define CSR_ARCHID      12'hf12
`define CSR_MSTATUS     12'h300
`define CSR_MEPC        12'h341
`define CSR_MCAUSE      12'h342
`define CSR_MTVEC       12'h305

`define EXC_ECALL       2'b01
`define EXC_MRET        2'b10

`define SRAM_ADDR_START 32'h80000000
`define SRAM_ADDR_END   32'h87ffffff

`define UART_ADDR_START 32'h10000000
`define UART_ADDR_END   32'h10000fff

`define CLINT_ADDR_START 32'h0200_0000
`define CLINT_ADDR_END   32'h0200_ffff

// 超标量
`define ISSUE_NUM         2 // 发射数量
`define QUEUE_ADDR_WIDTH  4 // Issue 队列大小
`define QUEUE_SIZE  16 // Issue 队列大小

`define FU_ALU  5'b00001
`define FU_LOAD  5'b00010
`define FU_STORE  5'b00100
`define FU_BRU  5'b01000
`define FU_JUMP  5'b10000

`define ROB_SIZE 16
`define ROB_ADDR_WIDTH 4