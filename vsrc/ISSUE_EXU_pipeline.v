`include "defines.v"
module ISSUE_EXU_pipeline (
  input clock,
  input reset,

  input                        alu_issue_valid,
  input [`OP_WIDTH-1:0]        alu_issue_op,
  input [`WORD_WIDTH-1:0]      alu_issue_imm,
  input                        alu_issue_imm_valid,
  input [`PADDR_WIDTH-1:0]     alu_issue_pc,
  input [`PREG_ADDR_WIDTH-1:0] alu_issue_prs1,
  input [`PREG_ADDR_WIDTH-1:0] alu_issue_prs2,
  input [`PREG_ADDR_WIDTH-1:0] alu_issue_prd,
  input [`ROB_ADDR_WIDTH-1:0]  alu_issue_rob_idx,
  input [`CSR_ADDR_WIDTH-1:0]  alu_issue_csr_addr,
  input [`CSR_OP_WIDTH-1:0]    alu_issue_csr_op,
  input [4:0]                  alu_issue_zimm,

  input                        lsu_issue_valid,
  input [`OP_WIDTH-1:0]        lsu_issue_op,
  input [`WORD_WIDTH-1:0]      lsu_issue_imm,
  input                        lsu_issue_imm_valid,
  input [`PADDR_WIDTH-1:0]     lsu_issue_pc,
  input [`PREG_ADDR_WIDTH-1:0] lsu_issue_prs1,
  input [`PREG_ADDR_WIDTH-1:0] lsu_issue_prs2,
  input [`PREG_ADDR_WIDTH-1:0] lsu_issue_prd,
  input [`ROB_ADDR_WIDTH-1:0]  lsu_issue_rob_idx,

  input                        bru_issue_valid,
  input [`OP_WIDTH-1:0]        bru_issue_op,
  input [`WORD_WIDTH-1:0]      bru_issue_imm,
  input                        bru_issue_imm_valid,
  input [`PADDR_WIDTH-1:0]     bru_issue_pc,
  input [`PREG_ADDR_WIDTH-1:0] bru_issue_prs1,
  input [`PREG_ADDR_WIDTH-1:0] bru_issue_prs2,
  input [`PREG_ADDR_WIDTH-1:0] bru_issue_prd,
  input [`ROB_ADDR_WIDTH-1:0]  bru_issue_rob_idx,

  input                        exc_issue_valid,
  input [`OP_WIDTH-1:0]        exc_issue_op,
  input [`PADDR_WIDTH-1:0]     exc_issue_pc,
  input [`ROB_ADDR_WIDTH-1:0]  exc_issue_rob_idx,

  output reg                        alu_valid,
  output reg [`OP_WIDTH-1:0]        alu_op,
  output reg [`WORD_WIDTH-1:0]      alu_imm,
  output reg                        alu_imm_valid,
  output reg [`PADDR_WIDTH-1:0]     alu_pc,
  output reg [`PREG_ADDR_WIDTH-1:0] alu_prs1,
  output reg [`PREG_ADDR_WIDTH-1:0] alu_prs2,
  output reg [`PREG_ADDR_WIDTH-1:0] alu_prd,
  output reg [`ROB_ADDR_WIDTH-1:0]  alu_rob_idx,
  output reg [`CSR_ADDR_WIDTH-1:0]  alu_csr_addr,
  output reg [`CSR_OP_WIDTH-1:0]    alu_csr_op,
  output reg [4:0]                  alu_zimm,

  output reg                        lsu_valid,
  output reg [`OP_WIDTH-1:0]        lsu_op,
  output reg [`WORD_WIDTH-1:0]      lsu_imm,
  output reg                        lsu_imm_valid,
  output reg [`PADDR_WIDTH-1:0]     lsu_pc,
  output reg [`PREG_ADDR_WIDTH-1:0] lsu_prs1,
  output reg [`PREG_ADDR_WIDTH-1:0] lsu_prs2,
  output reg [`PREG_ADDR_WIDTH-1:0] lsu_prd,
  output reg [`ROB_ADDR_WIDTH-1:0]  lsu_rob_idx,

  output reg                        bru_valid,
  output reg [`OP_WIDTH-1:0]        bru_op,
  output reg [`WORD_WIDTH-1:0]      bru_imm,
  output reg                        bru_imm_valid,
  output reg [`PADDR_WIDTH-1:0]     bru_pc,
  output reg [`PREG_ADDR_WIDTH-1:0] bru_prs1,
  output reg [`PREG_ADDR_WIDTH-1:0] bru_prs2,
  output reg [`PREG_ADDR_WIDTH-1:0] bru_prd,
  output reg [`ROB_ADDR_WIDTH-1:0]  bru_rob_idx,
  
  output reg                        exc_valid,
  output reg [`OP_WIDTH-1:0]        exc_op,
  output reg [`PADDR_WIDTH-1:0]     exc_pc,
  output reg [`ROB_ADDR_WIDTH-1:0]  exc_rob_idx
);
  
  always @(posedge clock) begin
    if(reset) begin
      alu_valid <= 0;
      alu_op <= 0;
      alu_imm <= 0;
      alu_imm_valid <= 0;
      alu_pc <= 0;
      alu_prs1 <= 0;
      alu_prs2 <= 0;
      alu_prd <= 0;
      alu_rob_idx <= 0;
      alu_csr_addr <= 0;
      alu_csr_op <= 0;
      alu_zimm <= 0;

      lsu_valid <= 0;
      lsu_op <= 0;
      lsu_imm <= 0;
      lsu_imm_valid <= 0;
      lsu_pc <= 0;
      lsu_prs1 <= 0;
      lsu_prs2 <= 0;
      lsu_prd <= 0;
      lsu_rob_idx <= 0;

      bru_valid <= 0;
      bru_op <= 0;
      bru_imm <= 0;
      bru_imm_valid <= 0;
      bru_pc <= 0;
      bru_prs1 <= 0;
      bru_prs2 <= 0;
      bru_prd <= 0;
      bru_rob_idx <= 0;

      exc_valid <= 0;
      exc_op <= 0;
      exc_pc <= 0;
      exc_rob_idx <= 0;
    end
    else begin
      if(alu_issue_valid) begin
        alu_valid <= 1;
        alu_op <= alu_issue_op;
        alu_imm <= alu_issue_imm;
        alu_imm_valid <= alu_issue_imm_valid;
        alu_pc <= alu_issue_pc;
        alu_prs1 <= alu_issue_prs1;
        alu_prs2 <= alu_issue_prs2;
        alu_prd <= alu_issue_prd;
        alu_rob_idx <= alu_issue_rob_idx;
        alu_csr_addr <= alu_issue_csr_addr;
        alu_csr_op <= alu_issue_csr_op;
        alu_zimm <= alu_issue_zimm;
      end
      else alu_valid <= 0;

      if(lsu_issue_valid) begin
        lsu_valid <= 1;
        lsu_op <= lsu_issue_op;
        lsu_imm <= lsu_issue_imm;
        lsu_imm_valid <= lsu_issue_imm_valid;
        lsu_pc <= lsu_issue_pc;
        lsu_prs1 <= lsu_issue_prs1;
        lsu_prs2 <= lsu_issue_prs2;
        lsu_prd <= lsu_issue_prd;
        lsu_rob_idx <= lsu_issue_rob_idx;
      end
      else lsu_valid <= 0;
      
      if(bru_issue_valid) begin
        bru_valid <= 1;
        bru_op <= bru_issue_op;
        bru_imm <= bru_issue_imm;
        bru_imm_valid <= bru_issue_imm_valid;
        bru_pc <= bru_issue_pc;
        bru_prs1 <= bru_issue_prs1;
        bru_prs2 <= bru_issue_prs2;
        bru_prd <= bru_issue_prd;
        bru_rob_idx <= bru_issue_rob_idx;
      end
      else bru_valid <= 0;

      if(exc_issue_valid) begin
        exc_valid <= 1;
        exc_op <= exc_issue_op;
        exc_pc <= exc_issue_pc;
        exc_rob_idx <= exc_issue_rob_idx;
      end
      else exc_valid <= 0;
    end
  end
endmodule