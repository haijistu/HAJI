`include "defines.v"
module IDU_ISSUE_pipeline (
  input clock,
  input reset,

  input [`WORD_WIDTH-1:0]      idu_inst_0,
  input                        idu_valid_0,
  input [`PREG_ADDR_WIDTH-1:0] idu_prs1_0,
  input                        idu_rs1_0_valid,
  input [`PREG_ADDR_WIDTH-1:0] idu_prs2_0,
  input                        idu_rs2_0_valid,
  input [`REG_ADDR_WIDTH-1:0]  idu_rd_0,
  input [`PREG_ADDR_WIDTH-1:0] idu_prd_0,
  input [`PREG_ADDR_WIDTH-1:0] idu_oprd_0,
  input                        idu_rd_0_valid,
  input [`WORD_WIDTH-1:0]      idu_imm_0,
  input                        idu_imm_0_valid,
  input [`OP_WIDTH-1:0]        idu_op_0,
  input [`FU_TYPE_WIDTH-1:0]   idu_fu_type_0,
  input [`PADDR_WIDTH-1:0]     idu_pc_0,

  input [`WORD_WIDTH-1:0]      idu_inst_1,
  input                        idu_valid_1,
  input [`PREG_ADDR_WIDTH-1:0] idu_prs1_1,
  input                        idu_rs1_1_valid,
  input [`PREG_ADDR_WIDTH-1:0] idu_prs2_1,
  input                        idu_rs2_1_valid,
  input [`REG_ADDR_WIDTH-1:0]  idu_rd_1,
  input [`PREG_ADDR_WIDTH-1:0] idu_prd_1,
  input [`PREG_ADDR_WIDTH-1:0] idu_oprd_1,
  input                        idu_rd_1_valid,
  input [`WORD_WIDTH-1:0]      idu_imm_1,
  input                        idu_imm_1_valid,
  input [`OP_WIDTH-1:0]        idu_op_1,
  input [`FU_TYPE_WIDTH-1:0]   idu_fu_type_1,
  input [`PADDR_WIDTH-1:0]     idu_pc_1,

  output reg [`WORD_WIDTH-1:0]      issue_inst_0,
  output reg                        issue_valid_0,
  output reg [`PREG_ADDR_WIDTH-1:0] issue_prs1_0,
  output reg                        issue_prs1_0_valid,
  output reg [`PREG_ADDR_WIDTH-1:0] issue_prs2_0,
  output reg                        issue_prs2_0_valid,
  output reg [`REG_ADDR_WIDTH-1:0]  issue_rd_0,
  output reg [`PREG_ADDR_WIDTH-1:0] issue_prd_0,
  output reg [`PREG_ADDR_WIDTH-1:0] issue_oprd_0,
  output reg                        issue_prd_0_valid,
  output reg [`WORD_WIDTH-1:0]      issue_imm_0,
  output reg                        issue_imm_0_valid,
  output reg [`OP_WIDTH-1:0]        issue_op_0,
  output reg [`FU_TYPE_WIDTH-1:0]   issue_fu_type_0,
  output reg [`PADDR_WIDTH-1:0]     issue_pc_0,

  output reg [`WORD_WIDTH-1:0]      issue_inst_1,
  output reg                        issue_valid_1,
  output reg [`PREG_ADDR_WIDTH-1:0] issue_prs1_1,
  output reg                        issue_prs1_1_valid,
  output reg [`PREG_ADDR_WIDTH-1:0] issue_prs2_1,
  output reg                        issue_prs2_1_valid,
  output reg [`REG_ADDR_WIDTH-1:0]  issue_rd_1,
  output reg [`PREG_ADDR_WIDTH-1:0] issue_prd_1,
  output reg [`PREG_ADDR_WIDTH-1:0] issue_oprd_1,
  output reg                        issue_prd_1_valid,
  output reg [`WORD_WIDTH-1:0]      issue_imm_1,
  output reg                        issue_imm_1_valid,
  output reg [`OP_WIDTH-1:0]        issue_op_1,
  output reg [`FU_TYPE_WIDTH-1:0]   issue_fu_type_1,
  output reg [`PADDR_WIDTH-1:0]     issue_pc_1
);

always @(posedge clock) begin
  if(reset) begin
    issue_inst_0 <= 0;
    issue_valid_0 <= 0;
    issue_prs1_0 <= 0;
    issue_prs1_0_valid <= 0;
    issue_prs2_0 <= 0;
    issue_prs2_0_valid <= 0;
    issue_rd_0 <= 0;
    issue_prd_0 <= 0;
    issue_oprd_0 <= 0;
    issue_prd_0_valid <= 0;
    issue_imm_0 <= 0;
    issue_imm_0_valid <= 0;
    issue_op_0 <= 0;
    issue_fu_type_0 <= 0;
    issue_pc_0 <= 0;

    issue_inst_1 <= 0;
    issue_valid_1 <= 0;
    issue_prs1_1 <= 0;
    issue_prs1_1_valid <= 0;
    issue_prs2_1 <= 0;
    issue_prs2_1_valid <= 0;
    issue_rd_1 <= 0;
    issue_prd_1 <= 0;
    issue_oprd_1 <= 0;
    issue_prd_1_valid <= 0;
    issue_imm_1 <= 0;
    issue_imm_1_valid <= 0;
    issue_op_1 <= 0;
    issue_fu_type_1 <= 0;
    issue_pc_1 <= 0;
  end
  else begin
    if(idu_valid_0) begin
      issue_inst_0 <= idu_inst_0;
      issue_valid_0 <= 1;
      issue_prs1_0 <= idu_prs1_0;
      issue_prs1_0_valid <= idu_rs1_0_valid;
      issue_prs2_0 <= idu_prs2_0;
      issue_prs2_0_valid <= idu_rs2_0_valid;
      issue_rd_0 <= idu_rd_0;
      issue_prd_0 <= idu_prd_0;
      issue_oprd_0 <= idu_oprd_0;
      issue_prd_0_valid <= idu_rd_0_valid;
      issue_imm_0 <= idu_imm_0;
      issue_imm_0_valid <= idu_imm_0_valid;
      issue_op_0 <= idu_op_0;
      issue_fu_type_0 <= idu_fu_type_0;
      issue_pc_0 <= idu_pc_0;
    end
    else issue_valid_0 <= 0;

    if(idu_valid_1) begin
      issue_inst_1 <= idu_inst_1;
      issue_valid_1 <= 1;
      issue_prs1_1 <= idu_prs1_1;
      issue_prs1_1_valid <= idu_rs1_1_valid;
      issue_prs2_1 <= idu_prs2_1;
      issue_prs2_1_valid <= idu_rs2_1_valid;
      issue_rd_1 <= idu_rd_1;
      issue_prd_1 <= idu_prd_1;
      issue_oprd_1 <= idu_oprd_1;
      issue_prd_1_valid <= idu_rd_1_valid;
      issue_imm_1 <= idu_imm_1;
      issue_imm_1_valid <= idu_imm_1_valid;
      issue_op_1 <= idu_op_1;
      issue_fu_type_1 <= idu_fu_type_1;
      issue_pc_1 <= idu_pc_1;
    end
    else issue_valid_1 <= 0;
  end
end
  
endmodule