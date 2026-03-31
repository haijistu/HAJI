`include "defines.v"
module ISSUE_top (
  input      clock,
  input      reset,

  // 来自IDU的指令信息
  input                        idu_valid_0,
  input [`OP_WIDTH-1:0]        idu_op_0,
  input [`FU_TYPE_WIDTH-1:0]   idu_fu_type_0,
  input [`WORD_WIDTH-1:0]      idu_imm_0,
  input                        idu_imm_valid_0,
  input [`PREG_ADDR_WIDTH-1:0] idu_prs1_0,
  input                        idu_prs1_valid_0,
  input [`PREG_ADDR_WIDTH-1:0] idu_prs2_0,
  input                        idu_prs2_valid_0,
  input [`PREG_ADDR_WIDTH-1:0] idu_prd_0,
  input                        idu_prd_valid_0,
  input [`PADDR_WIDTH-1:0]     idu_pc_0,

  input                        idu_valid_1,
  input [`OP_WIDTH-1:0]        idu_op_1,
  input [`FU_TYPE_WIDTH-1:0]   idu_fu_type_1,
  input [`WORD_WIDTH-1:0]      idu_imm_1,
  input                        idu_imm_valid_1,
  input [`PREG_ADDR_WIDTH-1:0] idu_prs1_1,
  input                        idu_prs1_valid_1,
  input [`PREG_ADDR_WIDTH-1:0] idu_prs2_1,
  input                        idu_prs2_valid_1,
  input [`PREG_ADDR_WIDTH-1:0] idu_prd_1,
  input                        idu_prd_valid_1,
  input [`PADDR_WIDTH-1:0]     idu_pc_1,

  // rob - idx
  input [`ROB_ADDR_WIDTH-1:0]   rob_idx_0,
  input [`ROB_ADDR_WIDTH-1:0]   rob_idx_1,

  // 发射到执行单元的指令信息
  output reg                         alu_issue_valid,
  output wire [`OP_WIDTH-1:0]        alu_issue_op,
  output wire [`WORD_WIDTH-1:0]      alu_issue_imm,
  output wire                        alu_issue_imm_valid,
  output wire [`PADDR_WIDTH-1:0]     alu_issue_pc,
  output wire [`PREG_ADDR_WIDTH-1:0] alu_issue_prs1,
  output wire [`PREG_ADDR_WIDTH-1:0] alu_issue_prs2,
  output wire [`PREG_ADDR_WIDTH-1:0] alu_issue_prd,
  output wire [`ROB_ADDR_WIDTH-1:0]  alu_issue_rob_idx,

  output reg                         lsu_issue_valid,
  output wire [`OP_WIDTH-1:0]        lsu_issue_op,
  output wire [`WORD_WIDTH-1:0]      lsu_issue_imm,
  output wire                        lsu_issue_imm_valid,
  output wire [`PADDR_WIDTH-1:0]     lsu_issue_pc,
  output wire [`PREG_ADDR_WIDTH-1:0] lsu_issue_prs1,
  output wire [`PREG_ADDR_WIDTH-1:0] lsu_issue_prs2,
  output wire [`PREG_ADDR_WIDTH-1:0] lsu_issue_prd,
  output wire [`ROB_ADDR_WIDTH-1:0]  lsu_issue_rob_idx,

  output reg                         bru_issue_valid,
  output wire [`OP_WIDTH-1:0]        bru_issue_op,
  output wire [`WORD_WIDTH-1:0]      bru_issue_imm,
  output wire                        bru_issue_imm_valid,
  output wire [`PADDR_WIDTH-1:0]     bru_issue_pc,
  output wire [`PREG_ADDR_WIDTH-1:0] bru_issue_prs1,
  output wire [`PREG_ADDR_WIDTH-1:0] bru_issue_prs2,
  output wire [`PREG_ADDR_WIDTH-1:0] bru_issue_prd,
  output wire [`ROB_ADDR_WIDTH-1:0]  bru_issue_rob_idx,

  // 写回广播(唤醒电路)
  input                             retire_valid_0,
  input [`PREG_ADDR_WIDTH-1:0]      retire_prd_0,
  input                             retire_valid_1,
  input [`PREG_ADDR_WIDTH-1:0]      retire_prd_1
);
  wire src1_ready_0;
  wire src2_ready_0;
  wire src1_ready_1;
  wire src2_ready_1;
  
  ISSUE_scoreboard scoreboard(
    .clock(clock),
    .reset(reset),

    .idu_alloc_valid_0(idu_prd_valid_0 & idu_valid_0),
    .idu_prd_0(idu_prd_0),
    .idu_alloc_valid_1(idu_prd_valid_1 & idu_valid_1),
    .idu_prd_1(idu_prd_1),

    .retire_valid_0(retire_valid_0),
    .retire_prd_0(retire_prd_0),
    .retire_valid_1(retire_valid_1),
    .retire_prd_1(retire_prd_1),

    .query_psrc1_0(idu_prs1_0),
    .query_psrc2_0(idu_prs2_0),
    .query_psrc1_1(idu_prs1_0),
    .query_psrc2_1(idu_prs2_0),
    .src1_ready_0(src1_ready_0),
    .src2_ready_0(src2_ready_0),
    .src1_ready_1(src1_ready_1),
    .src2_ready_1(src2_ready_1)
  );

  wire alu_fu_ready;
  wire lsu_fu_ready;
  wire bru_fu_ready;
  ISSUE_queue queue(
    .clock(clock),
    .reset(reset),
    // dispatch
    .prs1_0(idu_prs1_0),
    .prs2_0(idu_prs2_0),
    .prd_0(idu_prd_0),
    .inst0_valid(idu_valid_0),
    .op_0(idu_op_0),
    .fu_type_0(idu_fu_type_0),
    .imm_0(idu_imm_0),
    .imm_0_valid(idu_imm_valid_0),
    .pc_0(idu_pc_0),

    .prs1_1(idu_prs1_1),
    .prs2_1(idu_prs2_1),
    .prd_1(idu_prd_1),
    .inst1_valid(idu_valid_0),
    .op_1(idu_op_1),
    .fu_type_1(idu_fu_type_1),
    .imm_1(idu_imm_1),
    .imm_1_valid(idu_imm_valid_1),
    .pc_1(idu_pc_1),

    .rob_idx_0(rob_idx_0),
    .rob_idx_1(rob_idx_1),

    .prs1_ready_0(src1_ready_0),
    .prs2_ready_0(src2_ready_0),
    .prs1_ready_1(src1_ready_1),
    .prs2_ready_1(src2_ready_1),
    .alu_fu_ready(alu_fu_ready),
    .lsu_fu_ready(lsu_fu_ready),
    .bru_fu_ready(bru_fu_ready),

    .retire_valid_0(retire_valid_0),
    .retire_prd_0(retire_prd_0),
    .retire_valid_1(retire_valid_1),
    .retire_prd_1(retire_prd_1),
    
    // issue
    .alu_issue_valid(alu_issue_valid),
    .alu_issue_op(alu_issue_op),
    .alu_issue_imm(alu_issue_imm),
    .alu_issue_imm_valid(alu_issue_imm_valid),
    .alu_issue_pc(alu_issue_pc),
    .alu_issue_prs1(alu_issue_prs1),
    .alu_issue_prs2(alu_issue_prs2),
    .alu_issue_prd(alu_issue_prd),
    .alu_issue_rob_idx(alu_issue_rob_idx),

    .lsu_issue_valid(lsu_issue_valid),
    .lsu_issue_op(lsu_issue_op),
    .lsu_issue_imm_valid(lsu_issue_imm_valid),  
    .lsu_issue_imm(lsu_issue_imm),
    .lsu_issue_pc(lsu_issue_pc),
    .lsu_issue_prs1(lsu_issue_prs1),
    .lsu_issue_prs2(lsu_issue_prs2),
    .lsu_issue_prd(lsu_issue_prd),
    .lsu_issue_rob_idx(lsu_issue_rob_idx),

    .bru_issue_valid(bru_issue_valid),
    .bru_issue_op(bru_issue_op),
    .bru_issue_imm(bru_issue_imm),
    .bru_issue_imm_valid(bru_issue_imm_valid),
    .bru_issue_pc(bru_issue_pc),
    .bru_issue_prs1(bru_issue_prs1),
    .bru_issue_prs2(bru_issue_prs2),
    .bru_issue_prd(bru_issue_prd),
    .bru_issue_rob_idx(bru_issue_rob_idx)
  );
endmodule