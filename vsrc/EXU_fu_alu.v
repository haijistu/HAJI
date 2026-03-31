`include "defines.v"
module FU_alu (
  input [`WORD_WIDTH-1:0]   alu_psrc1,
  input [`WORD_WIDTH-1:0]   alu_psrc2,
  input [`OP_WIDTH-1:0]     alu_issue_op,
  input [`PADDR_WIDTH-1:0]  alu_issue_pc,
  input [`WORD_WIDTH-1:0]   alu_issue_imm,
  input                     alu_issue_imm_valid,

  output [`WORD_WIDTH-1:0]  alu_wd
);

  // 内部信号定义
  wire [`WORD_WIDTH-1:0]  alu_src1;
  wire [`WORD_WIDTH-1:0]  alu_src2;
  wire [`WORD_WIDTH-1:0]  alu_add_result;
  wire [`WORD_WIDTH-1:0]  alu_sub_result;
  wire [`WORD_WIDTH-1:0]  alu_sll_result;
  wire [`WORD_WIDTH-1:0]  alu_srl_result;
  wire [`WORD_WIDTH-1:0]  alu_sra_result;
  wire [`WORD_WIDTH-1:0]  alu_and_result;
  wire [`WORD_WIDTH-1:0]  alu_or_result;
  wire [`WORD_WIDTH-1:0]  alu_xor_result;
  wire [`WORD_WIDTH-1:0]  alu_slt_result;
  wire [`WORD_WIDTH-1:0]  alu_sltu_result;
  wire [`WORD_WIDTH-1:0]  alu_lui_result;
  wire [`WORD_WIDTH-1:0]  alu_auipc_result;
  wire                    alu_src1_lt_src2;
  wire                    alu_src1_lt_src2_unsigned;
  
  // 操作数选择
  assign alu_src1 = alu_psrc1;
  assign alu_src2 = alu_issue_imm_valid ? alu_issue_imm : alu_psrc2;
  
  // 基本算术运算
  assign alu_add_result  = alu_src1 + alu_src2;
  assign alu_sub_result  = alu_src1 - alu_src2;
  
  // 移位运算
  assign alu_sll_result  = alu_src1 << alu_src2[4:0];
  assign alu_srl_result  = alu_src1 >> alu_src2[4:0];
  assign alu_sra_result  = $signed(alu_src1) >>> alu_src2[4:0];
  
  // 逻辑运算
  assign alu_and_result  = alu_src1 & alu_src2;
  assign alu_or_result   = alu_src1 | alu_src2;
  assign alu_xor_result  = alu_src1 ^ alu_src2;
  
  // 比较运算
  assign alu_src1_lt_src2         = ($signed(alu_src1) < $signed(alu_src2));
  assign alu_src1_lt_src2_unsigned= (alu_src1 < alu_src2);
  assign alu_slt_result  = {{(`WORD_WIDTH-1){1'b0}}, alu_src1_lt_src2};
  assign alu_sltu_result = {{(`WORD_WIDTH-1){1'b0}}, alu_src1_lt_src2_unsigned};
  
  // LUI和AUIPC
  assign alu_lui_result  = alu_issue_imm;
  assign alu_auipc_result= alu_issue_pc + alu_issue_imm;
  
  // ALU结果选择
  reg [`WORD_WIDTH-1:0] alu_result;
  
  always @(*) begin
    case (alu_issue_op)
      `ALU_ADD:   alu_result = alu_add_result;
      `ALU_SUB:   alu_result = alu_sub_result;
      `ALU_SLL:   alu_result = alu_sll_result;
      `ALU_SLT:   alu_result = alu_slt_result;
      `ALU_SLTU:  alu_result = alu_sltu_result;
      `ALU_XOR:   alu_result = alu_xor_result;
      `ALU_SRL:   alu_result = alu_srl_result;
      `ALU_SRA:   alu_result = alu_sra_result;
      `ALU_OR:    alu_result = alu_or_result;
      `ALU_AND:   alu_result = alu_and_result;
      `ALU_AUIPC: alu_result = alu_issue_imm + alu_issue_pc;
      default:    alu_result = alu_add_result;
    endcase
  end
  
  assign alu_wd = alu_result;
endmodule