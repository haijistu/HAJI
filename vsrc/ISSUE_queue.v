`include "defines.v"
module ISSUE_queue (
  input clock,
  input reset,
  input [`PREG_ADDR_WIDTH-1:0] prs1_0,
  input [`PREG_ADDR_WIDTH-1:0] prs2_0,
  input [`PREG_ADDR_WIDTH-1:0] prd_0,
  input [`PREG_ADDR_WIDTH-1:0] prs1_1,
  input [`PREG_ADDR_WIDTH-1:0] prs2_1,
  input [`PREG_ADDR_WIDTH-1:0] prd_1,

  input                        bru_fu_ready,
  input                        lsu_fu_ready,
  input                        alu_fu_ready,
  input                        prs1_ready_0,
  input                        prs2_ready_0,
  input                        prs1_ready_1,
  input                        prs2_ready_1,

  input                       inst0_valid,
  input [`OP_WIDTH-1:0]       op_0,
  input [4:0]                 fu_type_0,
  input [`WORD_WIDTH-1:0]     imm_0,
  input                       imm_0_valid,
  input [`PADDR_WIDTH-1:0]    pc_0,
  input                       inst1_valid,
  input [`OP_WIDTH-1:0]       op_1,
  input [4:0]                 fu_type_1,
  input [`WORD_WIDTH-1:0]     imm_1,
  input                       imm_1_valid,
  input [`PADDR_WIDTH-1:0]    pc_1,

  input [`ROB_ADDR_WIDTH-1:0]   rob_idx_0,
  input [`ROB_ADDR_WIDTH-1:0]   rob_idx_1,

  // wakeup
  input                             retire_valid_0,
  input [`PREG_ADDR_WIDTH-1:0]      retire_prd_0,
  input                             retire_valid_1,
  input [`PREG_ADDR_WIDTH-1:0]      retire_prd_1,

  // issue
  output                        alu_issue_valid,
  output [`OP_WIDTH-1:0]        alu_issue_op,
  output [`WORD_WIDTH-1:0]      alu_issue_imm,
  output                        alu_issue_imm_valid,
  output [`PADDR_WIDTH-1:0]     alu_issue_pc,
  output [`PREG_ADDR_WIDTH-1:0] alu_issue_prs1,
  output [`PREG_ADDR_WIDTH-1:0] alu_issue_prs2,
  output [`PREG_ADDR_WIDTH-1:0] alu_issue_prd,
  output [`ROB_ADDR_WIDTH-1:0]  alu_issue_rob_idx,

  output                        lsu_issue_valid,
  output [`OP_WIDTH-1:0]        lsu_issue_op,
  output [`WORD_WIDTH-1:0]      lsu_issue_imm,
  output                        lsu_issue_imm_valid,
  output [`PADDR_WIDTH-1:0]     lsu_issue_pc,
  output [`PREG_ADDR_WIDTH-1:0] lsu_issue_prs1,
  output [`PREG_ADDR_WIDTH-1:0] lsu_issue_prs2,
  output [`PREG_ADDR_WIDTH-1:0] lsu_issue_prd,
  output [`ROB_ADDR_WIDTH-1:0]  lsu_issue_rob_idx,

  output                        bru_issue_valid,
  output [`OP_WIDTH-1:0]        bru_issue_op,
  output [`WORD_WIDTH-1:0]      bru_issue_imm,
  output                        bru_issue_imm_valid,
  output [`PADDR_WIDTH-1:0]     bru_issue_pc,
  output [`PREG_ADDR_WIDTH-1:0] bru_issue_prs1,
  output [`PREG_ADDR_WIDTH-1:0] bru_issue_prs2,
  output [`PREG_ADDR_WIDTH-1:0] bru_issue_prd,
  output [`ROB_ADDR_WIDTH-1:0]  bru_issue_rob_idx
);
  // 为每个FU维护一个独立的队列，简化调度逻辑: ALU LSU BRU(包含跳转指令)
  // | op | imm | prs1 | prs1_valid | prs2 | prs2_valid | prd | rob_idx |

  wire [1:0] dispatch_valid [0:2];
  assign dispatch_valid[0][0] = inst0_valid & (fu_type_0 == `FU_ALU);
  assign dispatch_valid[0][1] = inst1_valid & (fu_type_1 == `FU_ALU);
  assign dispatch_valid[1][0] = inst0_valid & (fu_type_0 == `FU_LOAD || fu_type_0 == `FU_STORE);
  assign dispatch_valid[1][1] = inst1_valid & (fu_type_1 == `FU_LOAD || fu_type_1 == `FU_STORE);
  assign dispatch_valid[2][0] = inst0_valid & (fu_type_0 == `FU_BRU  || fu_type_0 == `FU_JUMP);
  assign dispatch_valid[2][1] = inst1_valid & (fu_type_1 == `FU_BRU  || fu_type_1 == `FU_JUMP);

  ISSUE_outoforder_queue alu_queue(
    .clock(clock),
    .reset(reset),
    // dispatch
    .dispatch_valid_0(dispatch_valid[0][0]),
    .dispatch_op_0(op_0),
    .dispatch_imm_0(imm_0),
    .dispatch_imm_valid_0(imm_0_valid),
    .dispatch_pc_0(pc_0),
    .dispatch_prs1_0(prs1_0),
    .dispatch_prs2_0(prs2_0),
    .dispatch_prd_0(prd_0),
    .dispatch_rob_idx_0(rob_idx_0),

    .dispatch_valid_1(dispatch_valid[0][1]),
    .dispatch_op_1(op_1),
    .dispatch_imm_1(imm_1),
    .dispatch_imm_valid_1(imm_1_valid),
    .dispatch_pc_1(pc_1),
    .dispatch_prs1_1(prs1_1),
    .dispatch_prs2_1(prs2_1),
    .dispatch_prd_1(prd_1),
    .dispatch_rob_idx_1(rob_idx_1),

    .dispatch_prs1_ready_0(prs1_ready_0),
    .dispatch_prs2_ready_0(prs2_ready_0),
    .dispatch_prs1_ready_1(prs1_ready_1),
    .dispatch_prs2_ready_1(prs2_ready_1),

    .issue_valid(alu_issue_valid),
    .fu_ready(alu_fu_ready),
    .issue_op(alu_issue_op),
    .issue_imm(alu_issue_imm),
    .issue_imm_valid(alu_issue_imm_valid),
    .issue_pc(alu_issue_pc),
    .issue_prs1(alu_issue_prs1),
    .issue_prs2(alu_issue_prs2),
    .issue_prd(alu_issue_prd),
    .issue_rob_idx(alu_issue_rob_idx),

    .retire_valid_0(retire_valid_0),
    .retire_prd_0(retire_prd_0),
    .retire_valid_1(retire_valid_1),
    .retire_prd_1(retire_prd_1)
  );

  ISSUE_inorder_queue lsu_queue(
    .clock(clock),
    .reset(reset),
    // dispatch
    .dispatch_valid_0(dispatch_valid[1][0]),
    .dispatch_op_0(op_0),
    .dispatch_imm_0(imm_0),
    .dispatch_imm_valid_0(imm_0_valid),
    .dispatch_pc_0(pc_0),
    .dispatch_prs1_0(prs1_0),
    .dispatch_prs2_0(prs2_0),
    .dispatch_prd_0(prd_0),
    .dispatch_rob_idx_0(rob_idx_0),

    .dispatch_valid_1(dispatch_valid[1][1]),
    .dispatch_op_1(op_1),
    .dispatch_imm_1(imm_1),
    .dispatch_imm_valid_1(imm_1_valid),
    .dispatch_pc_1(pc_1),
    .dispatch_prs1_1(prs1_1),
    .dispatch_prs2_1(prs2_1),
    .dispatch_prd_1(prd_1),
    .dispatch_rob_idx_1(rob_idx_1),

    .dispatch_prs1_ready_0(prs1_ready_0),
    .dispatch_prs2_ready_0(prs2_ready_0),
    .dispatch_prs1_ready_1(prs1_ready_1),
    .dispatch_prs2_ready_1(prs2_ready_1),

    .issue_valid(lsu_issue_valid),
    .fu_ready(lsu_fu_ready),
    .issue_op(lsu_issue_op),
    .issue_imm(lsu_issue_imm),
    .issue_imm_valid(lsu_issue_imm_valid),
    .issue_pc(lsu_issue_pc),
    .issue_prs1(lsu_issue_prs1),
    .issue_prs2(lsu_issue_prs2),
    .issue_prd(lsu_issue_prd),
    .issue_rob_idx(lsu_issue_rob_idx),

    // wakeup
    .retire_valid_0(retire_valid_0),
    .retire_prd_0(retire_prd_0),
    .retire_valid_1(retire_valid_1),
    .retire_prd_1(retire_prd_1)
  );
  
  ISSUE_inorder_queue bru_queue(
    .clock(clock),
    .reset(reset),
    // dispatch
    .dispatch_valid_0(dispatch_valid[2][0]),
    .dispatch_op_0(op_0),
    .dispatch_imm_0(imm_0),
    .dispatch_imm_valid_0(imm_0_valid),
    .dispatch_pc_0(pc_0),
    .dispatch_prs1_0(prs1_0),
    .dispatch_prs2_0(prs2_0),
    .dispatch_prd_0(prd_0),
    .dispatch_rob_idx_0(rob_idx_0),

    .dispatch_valid_1(dispatch_valid[2][1]),
    .dispatch_op_1(op_1),
    .dispatch_imm_1(imm_1),
    .dispatch_imm_valid_1(imm_1_valid),
    .dispatch_pc_1(pc_1),
    .dispatch_prs1_1(prs1_1),
    .dispatch_prs2_1(prs2_1),
    .dispatch_prd_1(prd_1),
    .dispatch_rob_idx_1(rob_idx_1),

    .dispatch_prs1_ready_0(prs1_ready_0),
    .dispatch_prs2_ready_0(prs2_ready_0),
    .dispatch_prs1_ready_1(prs1_ready_1),
    .dispatch_prs2_ready_1(prs2_ready_1),

    .issue_valid(bru_issue_valid),
    .fu_ready(bru_fu_ready),
    .issue_op(bru_issue_op),
    .issue_imm(bru_issue_imm),
    .issue_imm_valid(bru_issue_imm_valid),
    .issue_pc(bru_issue_pc),
    .issue_prs1(bru_issue_prs1),
    .issue_prs2(bru_issue_prs2),
    .issue_prd(bru_issue_prd),
    .issue_rob_idx(bru_issue_rob_idx),

    // wakeup
    .retire_valid_0(retire_valid_0),
    .retire_prd_0(retire_prd_0),
    .retire_valid_1(retire_valid_1),
    .retire_prd_1(retire_prd_1)
  );
  
endmodule