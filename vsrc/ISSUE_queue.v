`include "defines.v"
module ISSUE_queue (
  input clock,
  input reset,
  input [`PREG_ADDR_WIDTH-1:0] prs1_0,
  input                        prs1_valid_0,
  input [`PREG_ADDR_WIDTH-1:0] prs2_0,
  input                        prs2_valid_0,
  input [`PREG_ADDR_WIDTH-1:0] prd_0,
  input                        prd_valid_0,

  input [`PREG_ADDR_WIDTH-1:0] prs1_1,
  input                        prs1_valid_1,
  input [`PREG_ADDR_WIDTH-1:0] prs2_1,
  input                        prs2_valid_1,
  input [`PREG_ADDR_WIDTH-1:0] prd_1,
  input                        prd_valid_1,

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
  input [`CSR_ADDR_WIDTH-1:0] csr_addr_0,
  input [`CSR_OP_WIDTH-1:0]   csr_op_0,
  input [4:0]                 zimm_0,

  input                       inst1_valid,
  input [`OP_WIDTH-1:0]       op_1,
  input [4:0]                 fu_type_1,
  input [`WORD_WIDTH-1:0]     imm_1,
  input                       imm_1_valid,
  input [`PADDR_WIDTH-1:0]    pc_1,
  input [`CSR_ADDR_WIDTH-1:0] csr_addr_1,
  input [`CSR_OP_WIDTH-1:0]   csr_op_1,
  input [4:0]                 zimm_1,

  input [`ROB_ADDR_WIDTH-1:0]   rob_idx_0,
  input [`ROB_ADDR_WIDTH-1:0]   rob_idx_1,
  
  input                         issue_csr_ready_0,
  input                         issue_csr_ready_1,

  input                         issue_mtvec_ready,
  input                         issue_mepc_ready,

  // wakeup
  input                             retire_valid_0,
  input [`PREG_ADDR_WIDTH-1:0]      retire_prd_0,
  input                             retire_valid_1,
  input [`PREG_ADDR_WIDTH-1:0]      retire_prd_1,

  input                             retire_csr_valid_0,
  input [`CSR_ADDR_WIDTH-1:0]       retire_csr_addr_0,
  input                             retire_csr_valid_1,
  input [`CSR_ADDR_WIDTH-1:0]       retire_csr_addr_1,

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
  output [`CSR_ADDR_WIDTH-1:0]  alu_issue_csr_addr,
  output [`CSR_OP_WIDTH-1:0]    alu_issue_csr_op,
  output [4:0]                  alu_issue_zimm,

  input                         load_busy,
  input                         store_busy,

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
  output [`ROB_ADDR_WIDTH-1:0]  bru_issue_rob_idx,
  
  output                        exc_issue_valid,
  output [`OP_WIDTH-1:0]        exc_issue_op,
  output [`PADDR_WIDTH-1:0]     exc_issue_pc,
  output [`ROB_ADDR_WIDTH-1:0]  exc_issue_rob_idx
);
  // 为每个FU维护一个独立的队列，简化调度逻辑: ALU LSU BRU(包含跳转指令)
  // | op | imm | prs1 | prs1_valid | prs2 | prs2_valid | prd | rob_idx |

  wire [1:0] dispatch_valid [0:3];
  assign dispatch_valid[0][0] = inst0_valid & (fu_type_0 == `FU_ALU || fu_type_0 == `FU_CSR);
  assign dispatch_valid[0][1] = inst1_valid & (fu_type_1 == `FU_ALU || fu_type_1 == `FU_CSR);
  assign dispatch_valid[1][0] = inst0_valid & (fu_type_0 == `FU_LOAD || fu_type_0 == `FU_STORE);
  assign dispatch_valid[1][1] = inst1_valid & (fu_type_1 == `FU_LOAD || fu_type_1 == `FU_STORE);
  assign dispatch_valid[2][0] = inst0_valid & (fu_type_0 == `FU_BRU  || fu_type_0 == `FU_JUMP);
  assign dispatch_valid[2][1] = inst1_valid & (fu_type_1 == `FU_BRU  || fu_type_1 == `FU_JUMP);
  assign dispatch_valid[3][0] = inst0_valid & (fu_type_0 == `FU_EXCU);
  assign dispatch_valid[3][1] = inst0_valid & (fu_type_1 == `FU_EXCU);
  
  ISSUE_alu_queue alu_queue(
    .clock(clock),
    .reset(reset),
    // dispatch
    .dispatch_valid_0(dispatch_valid[0][0]),
    .dispatch_op_0(op_0),
    .dispatch_imm_0(imm_0),
    .dispatch_imm_valid_0(imm_0_valid),
    .dispatch_pc_0(pc_0),
    .dispatch_prs1_0(prs1_0),
    .dispatch_prs1_valid_0(prs1_valid_0),
    .dispatch_prs2_0(prs2_0),
    .dispatch_prs2_valid_0(prs2_valid_0),
    .dispatch_prd_0(prd_0),
    .dispatch_rob_idx_0(rob_idx_0),
    .dispatch_csr_addr_0(csr_addr_0),
    .dispatch_csr_ready_0(issue_csr_ready_0),
    .dispatch_csr_op_0(csr_op_0),
    .dispatch_zimm_0(zimm_0),

    .dispatch_valid_1(dispatch_valid[0][1]),
    .dispatch_op_1(op_1),
    .dispatch_imm_1(imm_1),
    .dispatch_imm_valid_1(imm_1_valid),
    .dispatch_pc_1(pc_1),
    .dispatch_prs1_1(prs1_1),
    .dispatch_prs1_valid_1(prs1_valid_1),
    .dispatch_prs2_1(prs2_1),
    .dispatch_prs2_valid_1(prs2_valid_1),
    .dispatch_prd_1(prd_1),
    .dispatch_rob_idx_1(rob_idx_1),
    .dispatch_csr_addr_1(csr_addr_1),
    .dispatch_csr_ready_1(issue_csr_ready_1),
    .dispatch_csr_op_1(csr_op_1),
    .dispatch_zimm_1(zimm_1),

    .dispatch_prs1_ready_0(prs1_ready_0),
    .dispatch_prs2_ready_0(prs2_ready_0),
    .dispatch_prs1_ready_1(prs1_ready_1),
    .dispatch_prs2_ready_1(prs2_ready_1),

    .issue_valid(alu_issue_valid),
    .issue_op(alu_issue_op),
    .issue_imm(alu_issue_imm),
    .issue_imm_valid(alu_issue_imm_valid),
    .issue_pc(alu_issue_pc),
    .issue_prs1(alu_issue_prs1),
    .issue_prs2(alu_issue_prs2),
    .issue_prd(alu_issue_prd),
    .issue_rob_idx(alu_issue_rob_idx),
    .issue_csr_addr(alu_issue_csr_addr),
    .issue_csr_op(alu_issue_csr_op),
    .issue_zimm(alu_issue_zimm),

    .retire_valid_0(retire_valid_0),
    .retire_prd_0(retire_prd_0),
    .retire_valid_1(retire_valid_1),
    .retire_prd_1(retire_prd_1),

    .retire_csr_valid_0(retire_csr_valid_0),
    .retire_csr_addr_0(retire_csr_addr_0),
    .retire_csr_valid_1(retire_csr_valid_1),
    .retire_csr_addr_1(retire_csr_addr_1),
    
    .queue_full()
  );

  ISSUE_lsu_queue lsu_queue(
    .clock(clock),
    .reset(reset),
    // dispatch
    .dispatch_valid_0(dispatch_valid[1][0]),
    .dispatch_op_0(op_0),
    .dispatch_imm_0(imm_0),
    .dispatch_imm_valid_0(imm_0_valid),
    .dispatch_pc_0(pc_0),
    .dispatch_prs1_0(prs1_0),
    .dispatch_prs1_valid_0(prs1_valid_0),
    .dispatch_prs2_0(prs2_0),
    .dispatch_prs2_valid_0(prs2_valid_0),
    .dispatch_prd_0(prd_0),
    .dispatch_rob_idx_0(rob_idx_0),

    .dispatch_valid_1(dispatch_valid[1][1]),
    .dispatch_op_1(op_1),
    .dispatch_imm_1(imm_1),
    .dispatch_imm_valid_1(imm_1_valid),
    .dispatch_pc_1(pc_1),
    .dispatch_prs1_1(prs1_1),
    .dispatch_prs1_valid_1(prs1_valid_1),
    .dispatch_prs2_1(prs2_1),
    .dispatch_prs2_valid_1(prs2_valid_1),
    .dispatch_prd_1(prd_1),
    .dispatch_rob_idx_1(rob_idx_1),

    .dispatch_prs1_ready_0(prs1_ready_0),
    .dispatch_prs2_ready_0(prs2_ready_0),
    .dispatch_prs1_ready_1(prs1_ready_1),
    .dispatch_prs2_ready_1(prs2_ready_1),

    .load_busy(load_busy),
    .store_busy(store_busy),

    .issue_valid(lsu_issue_valid),
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
    .retire_prd_1(retire_prd_1),
    
    .queue_full()
  );
  
  ISSUE_bru_queue bru_queue(
    .clock(clock),
    .reset(reset),
    // dispatch
    .dispatch_valid_0(dispatch_valid[2][0]),
    .dispatch_op_0(op_0),
    .dispatch_imm_0(imm_0),
    .dispatch_imm_valid_0(imm_0_valid),
    .dispatch_pc_0(pc_0),
    .dispatch_prs1_0(prs1_0),
    .dispatch_prs1_valid_0(prs1_valid_0),
    .dispatch_prs2_0(prs2_0),
    .dispatch_prs2_valid_0(prs2_valid_0),
    .dispatch_prd_0(prd_0),
    .dispatch_rob_idx_0(rob_idx_0),

    .dispatch_valid_1(dispatch_valid[2][1]),
    .dispatch_op_1(op_1),
    .dispatch_imm_1(imm_1),
    .dispatch_imm_valid_1(imm_1_valid),
    .dispatch_pc_1(pc_1),
    .dispatch_prs1_1(prs1_1),
    .dispatch_prs1_valid_1(prs1_valid_1),
    .dispatch_prs2_1(prs2_1),
    .dispatch_prs2_valid_1(prs2_valid_1),
    .dispatch_prd_1(prd_1),
    .dispatch_rob_idx_1(rob_idx_1),

    .dispatch_prs1_ready_0(prs1_ready_0),
    .dispatch_prs2_ready_0(prs2_ready_0),
    .dispatch_prs1_ready_1(prs1_ready_1),
    .dispatch_prs2_ready_1(prs2_ready_1),

    .issue_valid(bru_issue_valid),
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
    .retire_prd_1(retire_prd_1),
    
    .queue_full()
  );
  
  ISSUE_exc_queue exc_queue(
    .clock(clock),
    .reset(reset),

    .dispatch_valid_0(dispatch_valid[3][0]),
    .dispatch_op_0(op_0),
    .dispatch_pc_0(pc_0),
    .dispatch_rob_idx_0(rob_idx_0),

    .dispatch_valid_1(dispatch_valid[3][1]),
    .dispatch_op_1(op_1),
    .dispatch_pc_1(pc_1),
    .dispatch_rob_idx_1(rob_idx_1),

    .mtvec_ready(issue_mtvec_ready),
    .mepc_ready(issue_mepc_ready),

    .retire_csr_valid_0(retire_csr_valid_0),
    .retire_csr_addr_0(retire_csr_addr_0),
    .retire_csr_valid_1(retire_csr_valid_1),
    .retire_csr_addr_1(retire_csr_addr_1),

    .issue_valid(exc_issue_valid),
    .issue_op(exc_issue_op),
    .issue_pc(exc_issue_pc),
    .issue_rob_idx(exc_issue_rob_idx),

    .queue_full()
  );
endmodule