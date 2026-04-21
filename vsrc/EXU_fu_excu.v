`include "defines.v"
module FU_excu (
  input [`WORD_WIDTH-1:0] excu_mepc,
  input [`WORD_WIDTH-1:0] excu_mtvec,
  input [`OP_WIDTH-1:0] excu_op,

  output [`EXC_EVENT_WIDTH-1:0] excu_event,
  output [`PADDR_WIDTH-1:0] excu_jump_addr
);
  assign excu_event = (excu_op == `EXCEPTION_ECALL) ? `EXC_ECALL : (excu_op == `EXCEPTION_MRET) ? `EXC_MRET : 0;
  assign excu_jump_addr = (excu_op == `EXCEPTION_ECALL) ? excu_mtvec : (excu_op == `EXCEPTION_MRET) ? excu_mepc : 0;

endmodule