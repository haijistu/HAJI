`include "defines.v"
module RENAME_check (
  input       [`REG_ADDR_WIDTH-1:0] idu_rs1_0,
  input       idu_rs1_0_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rs2_0,
  input       idu_rs2_0_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rd_0,
  input       idu_rd_0_valid,

  input       [`REG_ADDR_WIDTH-1:0] idu_rs1_1,
  input       idu_rs1_1_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rs2_1,
  input       idu_rs2_1_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rd_1,
  input       idu_rd_1_valid,

  output      raw_rs1_1,
  output      raw_rs2_1,
  output      waw_rd_0
);
  // RAW
  assign raw_rs1_1 = idu_rd_0_valid && idu_rs1_1_valid && (idu_rs1_1 == idu_rd_0);
  assign raw_rs2_1 = idu_rd_0_valid && idu_rs2_1_valid && (idu_rs2_1 == idu_rd_0);
  // WAW hazard: 同一周期内，指令1和指令0的目的寄存器相同，且两条指令都写回寄存器
  assign waw_rd_0 = idu_rd_0_valid && idu_rd_1_valid && (idu_rd_1 == idu_rd_0);
endmodule