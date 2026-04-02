`include "defines.v"
module EXU_top (
  input                             clock,
  input                             reset,

  // PRF
  input [`WORD_WIDTH-1:0]           alu_psrc1,
  input [`WORD_WIDTH-1:0]           alu_psrc2,
  input [`WORD_WIDTH-1:0]           lsu_psrc1,
  input [`WORD_WIDTH-1:0]           lsu_psrc2,
  input [`WORD_WIDTH-1:0]           bru_psrc1,
  input [`WORD_WIDTH-1:0]           bru_psrc2,

  // 发射到执行单元的指令信息
  input                             alu_issue_valid,
  input [`ROB_ADDR_WIDTH-1:0]       alu_issue_rob_idx,
  input [`OP_WIDTH-1:0]             alu_issue_op,
  input [`WORD_WIDTH-1:0]           alu_issue_imm,
  input                             alu_issue_imm_valid,
  input [`PADDR_WIDTH-1:0]          alu_issue_pc,

  input                             lsu_issue_valid,
  input [`ROB_ADDR_WIDTH-1:0]       lsu_issue_rob_idx,
  input [`OP_WIDTH-1:0]             lsu_issue_op,
  input [`WORD_WIDTH-1:0]           lsu_issue_imm,
  input                             lsu_issue_imm_valid,
  input [`PADDR_WIDTH-1:0]          lsu_issue_pc,

  input                             bru_issue_valid,
  input [`ROB_ADDR_WIDTH-1:0]       bru_issue_rob_idx,
  input [`OP_WIDTH-1:0]             bru_issue_op,
  input [`WORD_WIDTH-1:0]           bru_issue_imm,
  input                             bru_issue_imm_valid,
  input [`PADDR_WIDTH-1:0]          bru_issue_pc,
  
  // AXI
  output                            lsu_arvalid,
  input                             lsu_arready,
  output [`PADDR_WIDTH-1:0]         lsu_araddr,
  output [7:0]                      lsu_arlen,
  output [2:0]                      lsu_arsize,
  output [3:0]                      lsu_arid,
  output [1:0]                      lsu_arburst,
  input                             lsu_rvalid,
  output                            lsu_rready,
  input  [`WORD_WIDTH-1:0]          lsu_rdata,
  input  [1:0]                      lsu_rresp,
  input                             lsu_rlast,
  input  [3:0]                      lsu_rid,

  // alu
  output                            alu_valid,
  output [`WORD_WIDTH-1:0]          alu_wd,
  output [`ROB_ADDR_WIDTH-1:0]      alu_rob_idx,

  // lsu - load
  output                            lsu_load_valid,
  output                            lsu_store_valid,
  output [`PADDR_WIDTH-1:0]         lsu_store_addr,
  output [`WORD_WIDTH-1:0]          lsu_store_data,
  output [2:0]                      lsu_store_op,
  output [`WORD_WIDTH-1:0]          lsu_wd,
  output [`ROB_ADDR_WIDTH-1:0]      lsu_rob_idx,

  // bru
  output                            bru_valid,
  output [`PADDR_WIDTH-1:0]         bru_jump_addr,
  output                            bru_jump_flag,
  output [`ROB_ADDR_WIDTH-1:0]      bru_rob_idx,
  output [`WORD_WIDTH-1:0]          bru_wd,

  // lsu - busy
  output                            lsu_busy

);
  FU_alu alu(
    .alu_psrc1(alu_psrc1),
    .alu_psrc2(alu_psrc2),
    .alu_issue_op(alu_issue_op),
    .alu_issue_imm(alu_issue_imm),
    .alu_issue_imm_valid(alu_issue_imm_valid),
    .alu_issue_pc(alu_issue_pc),

    .alu_wd(alu_wd)
  );

  FU_lsu lsu(
    .clock(clock),
    .reset(reset),
    // issue 信号
    .lsu_psrc1(lsu_psrc1),
    .lsu_psrc2(lsu_psrc2),
    .lsu_issue_valid(lsu_issue_valid),
    .lsu_issue_op(lsu_issue_op),
    .lsu_issue_imm(lsu_issue_imm),
    .lsu_issue_imm_valid(lsu_issue_imm_valid),
    .lsu_issue_pc(lsu_issue_pc),
    // AXI
    .lsu_arvalid(lsu_arvalid),
    .lsu_arready(lsu_arready),
    .lsu_araddr(lsu_araddr),
    .lsu_arlen(lsu_arlen),
    .lsu_arsize(lsu_arsize),
    .lsu_arid(lsu_arid),
    .lsu_arburst(lsu_arburst),
    .lsu_rvalid(lsu_rvalid),
    .lsu_rready(lsu_rready),
    .lsu_rdata(lsu_rdata),
    .lsu_rresp(lsu_rresp),
    .lsu_rlast(lsu_rlast),
    .lsu_rid(lsu_rid),

    .lsu_load_valid(lsu_load_valid),
    .lsu_store_valid(lsu_store_valid),
    .lsu_wd(lsu_wd),
    .lsu_store_addr(lsu_store_addr),
    .lsu_store_data(lsu_store_data),
    .lsu_store_op(lsu_store_op),
    
    .lsu_busy(lsu_busy)
  );

  FU_bru bru(
    .bru_psrc1(bru_psrc1),
    .bru_psrc2(bru_psrc2),
    .bru_issue_valid(bru_issue_valid),
    .bru_issue_op(bru_issue_op),
    .bru_issue_imm(bru_issue_imm),
    .bru_issue_pc(bru_issue_pc),
    .jump_addr(bru_jump_addr),
    .jump_flag(bru_jump_flag),
    .bru_wd(bru_wd)
  );
  assign alu_valid = alu_issue_valid;
  assign bru_valid = bru_issue_valid;
  assign alu_rob_idx = alu_issue_rob_idx;
  assign lsu_rob_idx = lsu_issue_rob_idx;
  assign bru_rob_idx = bru_issue_rob_idx;
endmodule