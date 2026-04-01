`include "defines.v"
module IDU_top (
  input       clock,
  input       reset,

  // 来自 IFU 的指令和 PC
  input                         ifu_valid_0,
  input      [`PADDR_WIDTH-1:0] ifu_pc_0,
  input      [`WORD_WIDTH-1:0 ] ifu_inst_0,
  input                         ifu_valid_1,
  input      [`PADDR_WIDTH-1:0] ifu_pc_1,
  input      [`WORD_WIDTH-1:0 ] ifu_inst_1,

  // 输出到RENAME和ISSUE的指令有效信号
  output                            idu_valid_0,
  output                            idu_valid_1,
  output                            idu_rs1_0_valid,
  output                            idu_rs2_0_valid,
  output                            idu_rd_0_valid,
  output                            idu_rs1_1_valid,
  output                            idu_rs2_1_valid,
  output                            idu_rd_1_valid,

  // 输出到 Rename Unit 的架构寄存器信息
  output     [`REG_ADDR_WIDTH-1:0]  idu_rs1_0,
  output     [`REG_ADDR_WIDTH-1:0]  idu_rs2_0,
  output     [`REG_ADDR_WIDTH-1:0]  idu_rd_0,
  
  output     [`REG_ADDR_WIDTH-1:0]  idu_rs1_1,
  output     [`REG_ADDR_WIDTH-1:0]  idu_rs2_1,
  output     [`REG_ADDR_WIDTH-1:0]  idu_rd_1,
  // 重命名后的物理寄存器编号
  input     [`PREG_ADDR_WIDTH-1:0]  rename_prs1_0,
  input     [`PREG_ADDR_WIDTH-1:0]  rename_prs2_0,
  input     [`PREG_ADDR_WIDTH-1:0]  rename_nprd_0,
  input     [`PREG_ADDR_WIDTH-1:0]  rename_oprd_0,
  input     [`PREG_ADDR_WIDTH-1:0]  rename_prs1_1,
  input     [`PREG_ADDR_WIDTH-1:0]  rename_prs2_1,
  input     [`PREG_ADDR_WIDTH-1:0]  rename_nprd_1,
  input     [`PREG_ADDR_WIDTH-1:0]  rename_oprd_1,

  // 输出到ISSUE模块
  output     [`WORD_WIDTH-1:0]      idu_inst_0,
  output     [`PREG_ADDR_WIDTH-1:0] idu_prs1_0,
  output     [`PREG_ADDR_WIDTH-1:0] idu_prs2_0,
  output     [`PREG_ADDR_WIDTH-1:0] idu_prd_0,
  output     [`PREG_ADDR_WIDTH-1:0] idu_oprd_0,
  output     [`WORD_WIDTH-1:0]      idu_imm_0,
  output                            idu_imm_0_valid,
  output     [`OP_WIDTH-1:0]        idu_op_0,
  output     [`FU_TYPE_WIDTH-1:0]   idu_fu_type_0,
  output     [`PADDR_WIDTH-1:0]     idu_pc_0,
  
  output     [`WORD_WIDTH-1:0]      idu_inst_1,
  output     [`PREG_ADDR_WIDTH-1:0] idu_prs1_1,
  output     [`PREG_ADDR_WIDTH-1:0] idu_prs2_1,
  output     [`PREG_ADDR_WIDTH-1:0] idu_prd_1,
  output     [`PREG_ADDR_WIDTH-1:0] idu_oprd_1,
  output     [`WORD_WIDTH-1:0]      idu_imm_1,
  output                            idu_imm_1_valid,
  output     [`OP_WIDTH-1:0]        idu_op_1,
  output     [`FU_TYPE_WIDTH-1:0]   idu_fu_type_1,
  output     [`PADDR_WIDTH-1:0]     idu_pc_1,

  output                            idu_bru_valid
);

// 遇到分支指令就暂停取指
assign idu_valid_0 = ifu_valid_0;
assign idu_valid_1 = (idu_fu_type_0 == `FU_BRU || idu_fu_type_0 == `FU_JUMP) ? 1'b0 : ifu_valid_1;

assign idu_bru_valid = ((ifu_valid_0 && (idu_fu_type_0 == `FU_BRU || idu_fu_type_0 == `FU_JUMP)) || (ifu_valid_1 && (idu_fu_type_1 == `FU_BRU || idu_fu_type_1 == `FU_JUMP)));

assign idu_pc_0 = ifu_pc_0;
assign idu_pc_1 = ifu_pc_1;
assign idu_prs1_0 = rename_prs1_0;
assign idu_prs2_0 = rename_prs2_0;
assign idu_prd_0  = rename_nprd_0;
assign idu_oprd_0 = rename_oprd_0;
assign idu_prs1_1 = rename_prs1_1;
assign idu_prs2_1 = rename_prs2_1;
assign idu_prd_1  = rename_nprd_1;
assign idu_oprd_1 = rename_oprd_1;
assign idu_inst_0 = ifu_inst_0;
assign idu_inst_1 = ifu_inst_1;

IDU_decode idu_decode_0 (
  .pc(ifu_pc_0),
  .inst(ifu_inst_0),
  .rs1(idu_rs1_0),
  .rs1_valid(idu_rs1_0_valid),
  .rs2(idu_rs2_0),
  .rs2_valid(idu_rs2_0_valid),
  .rd(idu_rd_0),
  .rd_valid(idu_rd_0_valid),
  .imm(idu_imm_0),
  .imm_valid(idu_imm_0_valid),
  .op(idu_op_0),
  .fu_type(idu_fu_type_0)
);

IDU_decode idu_decode_1 (
  .pc(ifu_pc_1),
  .inst(ifu_inst_1),
  .rs1(idu_rs1_1),
  .rs1_valid(idu_rs1_1_valid),
  .rs2(idu_rs2_1),
  .rs2_valid(idu_rs2_1_valid),
  .rd(idu_rd_1),
  .rd_valid(idu_rd_1_valid),
  .imm(idu_imm_1),
  .imm_valid(idu_imm_1_valid),
  .op(idu_op_1),
  .fu_type(idu_fu_type_1)
);

endmodule