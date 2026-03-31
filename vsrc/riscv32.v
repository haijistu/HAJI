`include "defines.v"

module riscv32(
  input clock,
  input reset,

  output                    icache_arvalid,
  input                     icache_arready,
  output [`PADDR_WIDTH-1:0] icache_araddr,
  output [7:0]              icache_arlen,
  output [2:0]              icache_arsize,
  output [3:0]              icache_arid,
  output [1:0]              icache_arburst,

  input                     icache_rvalid,
  output                    icache_rready,
  input [`WORD_WIDTH-1:0]   icache_rdata,
  input [1:0]               icache_rresp,
  input                     icache_rlast,
  input [3:0]               icache_rid,

  output                    icache_awvalid,
  input                     icache_awready,
  output [`PADDR_WIDTH-1:0] icache_awaddr,
  output [7:0]              icache_awlen,
  output [2:0]              icache_awsize,
  output [3:0]              icache_awid,
  output [1:0]              icache_awburst,

  output                    icache_wvalid,
  input                     icache_wready,
  output [`WORD_WIDTH-1:0]  icache_wdata,
  output [3:0]              icache_wstrb,
  output                    icache_wlast,

  input                     icache_bvalid,
  output                    icache_bready,
  input  [1:0]              icache_bresp,
  input  [3:0]              icache_bid,

  output                    lsu_arvalid,
  input                     lsu_arready,
  output [`PADDR_WIDTH-1:0] lsu_araddr,
  output [7:0]              lsu_arlen,
  output [2:0]              lsu_arsize,
  output [3:0]              lsu_arid,
  output [1:0]              lsu_arburst,

  input                     lsu_rvalid,
  output                    lsu_rready,
  input [`WORD_WIDTH-1:0]   lsu_rdata,
  input [1:0]               lsu_rresp,
  input                     lsu_rlast,
  input [3:0]               lsu_rid,

  output                    lsu_awvalid,
  input                     lsu_awready,
  output [`PADDR_WIDTH-1:0] lsu_awaddr,
  output [7:0]              lsu_awlen,
  output [2:0]              lsu_awsize,
  output [3:0]              lsu_awid,
  output [1:0]              lsu_awburst,

  output                    lsu_wvalid,
  input                     lsu_wready,
  output [`WORD_WIDTH-1:0]  lsu_wdata,
  output [3:0]              lsu_wstrb,
  output                    lsu_wlast,

  input                     lsu_bvalid,
  output                    lsu_bready,
  input  [1:0]              lsu_bresp,
  input  [3:0]              lsu_bid
);

  // icache - ifu
  wire                              ifu_arvalid;
  wire [`PADDR_WIDTH-1:0]           ifu_araddr;
  wire                              ifu_rready;
  wire                              icache_iarready;
  wire                              icache_ivalid;
  wire [`ISSUE_NUM*`WORD_WIDTH-1:0] icache_idata;

  // ifu: jump target
  wire [`PADDR_WIDTH-1:0] jump_addr;
  wire                    jump_flag;
  wire [`PADDR_WIDTH-1:0] exc_jump_addr;
  wire                    exc_jump_flag;

  // ifu - idu
  wire [`PADDR_WIDTH-1:0]     ifu_pc_0;
  wire [`WORD_WIDTH-1:0 ]     ifu_inst_0;
  wire                        ifu_valid_0;
  wire [`PADDR_WIDTH-1:0]     ifu_pc_1;
  wire [`WORD_WIDTH-1:0 ]     ifu_inst_1;
  wire                        ifu_valid_1;

  wire [`PADDR_WIDTH-1:0]     ifu_idu_pc_0;
  wire [`WORD_WIDTH-1:0 ]     ifu_idu_inst_0;
  wire                        ifu_idu_valid_0;
  wire [`PADDR_WIDTH-1:0]     ifu_idu_pc_1;
  wire [`WORD_WIDTH-1:0 ]     ifu_idu_inst_1;
  wire                        ifu_idu_valid_1;

  // idu: dispatch
  wire [`WORD_WIDTH-1:0]      idu_inst_0;
  wire                        idu_valid_0;
  wire [`REG_ADDR_WIDTH-1:0]  idu_rs1_0;
  wire [`PREG_ADDR_WIDTH-1:0] idu_prs1_0;
  wire                        idu_rs1_0_valid;
  wire [`REG_ADDR_WIDTH-1:0]  idu_rs2_0;
  wire [`PREG_ADDR_WIDTH-1:0] idu_prs2_0;
  wire                        idu_rs2_0_valid;
  wire [`REG_ADDR_WIDTH-1:0]  idu_rd_0;
  wire [`PREG_ADDR_WIDTH-1:0] idu_prd_0;
  wire [`PREG_ADDR_WIDTH-1:0] idu_oprd_0;
  wire                        idu_rd_0_valid;
  wire [`WORD_WIDTH-1:0]      idu_imm_0;
  wire                        idu_imm_0_valid;
  wire [`OP_WIDTH-1:0]        idu_op_0;
  wire [`FU_TYPE_WIDTH-1:0]   idu_fu_type_0;
  wire [`PADDR_WIDTH-1:0]     idu_pc_0;

  wire [`WORD_WIDTH-1:0]      idu_inst_1;
  wire                        idu_valid_1;
  wire [`REG_ADDR_WIDTH-1:0]  idu_rs1_1;
  wire [`PREG_ADDR_WIDTH-1:0] idu_prs1_1;
  wire                        idu_rs1_1_valid;
  wire [`REG_ADDR_WIDTH-1:0]  idu_rs2_1;
  wire [`PREG_ADDR_WIDTH-1:0] idu_prs2_1;
  wire                        idu_rs2_1_valid;
  wire [`REG_ADDR_WIDTH-1:0]  idu_rd_1;
  wire [`PREG_ADDR_WIDTH-1:0] idu_prd_1;
  wire [`PREG_ADDR_WIDTH-1:0] idu_oprd_1;
  wire                        idu_rd_1_valid;
  wire [`WORD_WIDTH-1:0]      idu_imm_1;
  wire                        idu_imm_1_valid;
  wire [`OP_WIDTH-1:0]        idu_op_1;
  wire [`FU_TYPE_WIDTH-1:0]   idu_fu_type_1;
  wire [`PADDR_WIDTH-1:0]     idu_pc_1;

  // rob - dispatch
  wire [`ROB_ADDR_WIDTH-1:0]  rob_idx_0;
  wire [`ROB_ADDR_WIDTH-1:0]  rob_idx_1;

  // rename - rob
  wire                        rob_commit_0_valid;
  wire [`PREG_ADDR_WIDTH-1:0] rob_commit_0_prd;
  wire                        rob_commit_1_valid;
  wire [`PREG_ADDR_WIDTH-1:0] rob_commit_1_prd;
  wire [`PREG_ADDR_WIDTH-1:0] rename_oprd_0;
  wire                        rename_oprd_0_valid;
  wire [`PREG_ADDR_WIDTH-1:0] rename_oprd_1;
  wire                        rename_oprd_1_valid;
  wire [`REG_ADDR_WIDTH-1:0]  rename_rd_0;
  wire [`REG_ADDR_WIDTH-1:0]  rename_rd_1;

  // rename
  wire      [`PREG_ADDR_WIDTH-1:0]  rename_prs1_0;
  wire      [`PREG_ADDR_WIDTH-1:0]  rename_prs2_0;
  wire      [`PREG_ADDR_WIDTH-1:0]  rename_nprd_0;
  wire      [`PREG_ADDR_WIDTH-1:0]  rename_prs1_1;
  wire      [`PREG_ADDR_WIDTH-1:0]  rename_prs2_1;
  wire      [`PREG_ADDR_WIDTH-1:0]  rename_nprd_1;

  // issue
  wire [`WORD_WIDTH-1:0]      issue_inst_0;
  wire                        issue_valid_0;
  wire [`OP_WIDTH-1:0]        issue_op_0;
  wire [`FU_TYPE_WIDTH-1:0]   issue_fu_type_0;
  wire [`WORD_WIDTH-1:0]      issue_imm_0;
  wire                        issue_imm_valid_0;
  wire [`PREG_ADDR_WIDTH-1:0] issue_prs1_0;
  wire                        issue_prs1_valid_0;
  wire [`PREG_ADDR_WIDTH-1:0] issue_prs2_0;
  wire                        issue_prs2_valid_0;
  wire [`PREG_ADDR_WIDTH-1:0] issue_prd_0;
  wire [`PREG_ADDR_WIDTH-1:0] issue_oprd_0;
  wire                        issue_prd_valid_0;
  wire [`REG_ADDR_WIDTH-1:0]  issue_rd_0;
  wire [`PADDR_WIDTH-1:0]     issue_pc_0;

  wire [`WORD_WIDTH-1:0]      issue_inst_1;
  wire                        issue_valid_1;
  wire [`OP_WIDTH-1:0]        issue_op_1;
  wire [`FU_TYPE_WIDTH-1:0]   issue_fu_type_1;
  wire [`WORD_WIDTH-1:0]      issue_imm_1;
  wire                        issue_imm_valid_1;
  wire [`PREG_ADDR_WIDTH-1:0] issue_prs1_1;
  wire                        issue_prs1_valid_1;
  wire [`PREG_ADDR_WIDTH-1:0] issue_prs2_1;
  wire                        issue_prs2_valid_1;
  wire [`PREG_ADDR_WIDTH-1:0] issue_prd_1;
  wire [`PREG_ADDR_WIDTH-1:0] issue_oprd_1;
  wire                        issue_prd_valid_1;
  wire [`REG_ADDR_WIDTH-1:0]  issue_rd_1;
  wire [`PADDR_WIDTH-1:0]     issue_pc_1;
  // issue 发射的有效指令
  wire                        alu_issue_valid;
  wire [`OP_WIDTH-1:0]        alu_issue_op;
  wire [`WORD_WIDTH-1:0]      alu_issue_imm;
  wire                        alu_issue_imm_valid;
  wire [`PADDR_WIDTH-1:0]     alu_issue_pc;
  wire [`PREG_ADDR_WIDTH-1:0] alu_issue_prs1;
  wire [`PREG_ADDR_WIDTH-1:0] alu_issue_prs2;
  wire [`PREG_ADDR_WIDTH-1:0] alu_issue_prd;
  wire [`ROB_ADDR_WIDTH-1:0]  alu_issue_rob_idx;

  wire                        lsu_issue_valid;
  wire [`OP_WIDTH-1:0]        lsu_issue_op;
  wire [`WORD_WIDTH-1:0]      lsu_issue_imm;
  wire                        lsu_issue_imm_valid;
  wire [`PADDR_WIDTH-1:0]     lsu_issue_pc;
  wire [`PREG_ADDR_WIDTH-1:0] lsu_issue_prs1;
  wire [`PREG_ADDR_WIDTH-1:0] lsu_issue_prs2;
  wire [`PREG_ADDR_WIDTH-1:0] lsu_issue_prd;
  wire [`ROB_ADDR_WIDTH-1:0]  lsu_issue_rob_idx;

  wire                        bru_issue_valid;
  wire [`OP_WIDTH-1:0]        bru_issue_op;
  wire [`WORD_WIDTH-1:0]      bru_issue_imm;
  wire                        bru_issue_imm_valid;
  wire [`PADDR_WIDTH-1:0]     bru_issue_pc;
  wire [`PREG_ADDR_WIDTH-1:0] bru_issue_prs1;
  wire [`PREG_ADDR_WIDTH-1:0] bru_issue_prs2;
  wire [`PREG_ADDR_WIDTH-1:0] bru_issue_prd;
  wire [`ROB_ADDR_WIDTH-1:0]  bru_issue_rob_idx;
  // 一并发送到EXU单元
  wire                        alu_valid;
  wire [`OP_WIDTH-1:0]        alu_op;
  wire [`WORD_WIDTH-1:0]      alu_imm;
  wire                        alu_imm_valid;
  wire [`PADDR_WIDTH-1:0]     alu_pc;
  wire [`PREG_ADDR_WIDTH-1:0] alu_prs1;
  wire [`PREG_ADDR_WIDTH-1:0] alu_prs2;
  wire [`PREG_ADDR_WIDTH-1:0] alu_prd;
  wire [`ROB_ADDR_WIDTH-1:0]  alu_rob_idx;

  wire                        lsu_valid;
  wire [`OP_WIDTH-1:0]        lsu_op;
  wire [`WORD_WIDTH-1:0]      lsu_imm;
  wire                        lsu_imm_valid;
  wire [`PADDR_WIDTH-1:0]     lsu_pc;
  wire [`PREG_ADDR_WIDTH-1:0] lsu_prs1;
  wire [`PREG_ADDR_WIDTH-1:0] lsu_prs2;
  wire [`PREG_ADDR_WIDTH-1:0] lsu_prd;
  wire [`ROB_ADDR_WIDTH-1:0]  lsu_rob_idx;

  wire                        bru_valid;
  wire [`OP_WIDTH-1:0]        bru_op;
  wire [`WORD_WIDTH-1:0]      bru_imm;
  wire                        bru_imm_valid;
  wire [`PADDR_WIDTH-1:0]     bru_pc;
  wire [`PREG_ADDR_WIDTH-1:0] bru_prs1;
  wire [`PREG_ADDR_WIDTH-1:0] bru_prs2;
  wire [`PREG_ADDR_WIDTH-1:0] bru_prd;
  wire [`ROB_ADDR_WIDTH-1:0]  bru_rob_idx;

  wire [`WORD_WIDTH-1:0]      alu_psrc1;
  wire [`WORD_WIDTH-1:0]      alu_psrc2;
  wire [`WORD_WIDTH-1:0]      lsu_psrc1;
  wire [`WORD_WIDTH-1:0]      lsu_psrc2;
  wire [`WORD_WIDTH-1:0]      bru_psrc1;
  wire [`WORD_WIDTH-1:0]      bru_psrc2;

  // exu 计算结果
  wire                        alu_wb_valid;
  wire [`WORD_WIDTH-1:0]      alu_wb_wd;
  wire [`ROB_ADDR_WIDTH-1:0]  alu_wb_rob_idx;

  wire                        lsu_wb_load_valid;
  wire                        lsu_wb_store_valid;
  wire [`WORD_WIDTH-1:0]      lsu_wb_wd;
  wire [`PADDR_WIDTH-1:0]     lsu_store_addr;
  wire [`WORD_WIDTH-1:0]      lsu_store_data;
  wire [2:0]                  lsu_store_op;
  wire [`ROB_ADDR_WIDTH-1:0]  lsu_wb_rob_idx;
  
  wire                        bru_wb_valid;
  wire [`PADDR_WIDTH-1:0]     bru_wb_jump_addr;
  wire                        bru_wb_jump_flag;
  wire [`WORD_WIDTH-1:0]      bru_wb_wd;
  wire [`ROB_ADDR_WIDTH-1:0]  bru_wb_rob_idx;
  
  // WB
  wire                        wb_alu_valid;
  wire [`WORD_WIDTH-1:0]      wb_alu_wd;
  wire [`ROB_ADDR_WIDTH-1:0]  wb_alu_rob_idx;

  wire                        wb_lsu_valid;
  wire [`WORD_WIDTH-1:0]      wb_lsu_wd;
  wire [`ROB_ADDR_WIDTH-1:0]  wb_lsu_rob_idx;

  wire                        wb_bru_valid;
  wire [`PADDR_WIDTH-1:0]     wb_bru_jump_addr;
  wire                        wb_bru_jump_flag;
  wire [`WORD_WIDTH-1:0]      wb_bru_wd;
  wire [`ROB_ADDR_WIDTH-1:0]  wb_bru_rob_idx;

  // rob - retire
  wire                        retire_valid_0;
  wire                        retire_valid_1;
  wire                        retire_store_valid_0;
  wire                        retire_store_valid_1;
  wire                        retire_rd_valid_0;
  wire                        retire_rd_valid_1;
  wire [`PREG_ADDR_WIDTH-1:0] retire_opreg_0;
  wire [`PREG_ADDR_WIDTH-1:0] retire_opreg_1;
  wire [`REG_ADDR_WIDTH-1:0]  retire_areg_0;
  wire [`REG_ADDR_WIDTH-1:0]  retire_areg_1;
  wire [`PREG_ADDR_WIDTH-1:0] retire_preg_0;
  wire [`PREG_ADDR_WIDTH-1:0] retire_preg_1;
  wire [`ROB_ADDR_WIDTH-1:0]  retire_rob_idx_0;
  wire [`ROB_ADDR_WIDTH-1:0]  retire_rob_idx_1;
  wire [`PREG_ADDR_WIDTH-1:0] retire_wa_0;
  wire [`WORD_WIDTH-1:0]      retire_wd_0;
  wire [`PREG_ADDR_WIDTH-1:0] retire_wa_1;
  wire [`WORD_WIDTH-1:0]      retire_wd_1;

  ICACHE_top ICACHE0(
    .clock(clock),
    .reset(reset),
    // IFU与icache的握手接口
    .ifu_arvalid(ifu_arvalid),
    .ifu_araddr(ifu_araddr),
    .ifu_rready(ifu_rready),
    .icache_iarready(icache_iarready),
    .icache_ivalid(icache_ivalid),
    .icache_idata(icache_idata),
    // IROM AXI BUS
    .icache_arvalid(icache_arvalid),
    .icache_arready(icache_arready),
    .icache_araddr(icache_araddr),
    .icache_arlen(icache_arlen),
    .icache_arsize(icache_arsize),
    .icache_arid(icache_arid),
    .icache_arburst(icache_arburst),
    .icache_rvalid(icache_rvalid),
    .icache_rready(icache_rready),
    .icache_rdata(icache_rdata),
    .icache_rresp(icache_rresp),
    .icache_rlast(icache_rlast),
    .icache_rid(icache_rid),
    .icache_awvalid(icache_awvalid),
    .icache_awready(icache_awready),
    .icache_awaddr(icache_awaddr),
    .icache_awlen(icache_awlen),
    .icache_awsize(icache_awsize),
    .icache_awid(icache_awid),
    .icache_awburst(icache_awburst),
    .icache_wvalid(icache_wvalid),
    .icache_wready(icache_wready),
    .icache_wdata(icache_wdata),
    .icache_wstrb(icache_wstrb),
    .icache_wlast(icache_wlast),
    .icache_bvalid(icache_bvalid),
    .icache_bready(icache_bready),
    .icache_bresp(icache_bresp),
    .icache_bid(icache_bid)
  );

  IFU_top IFU0(
    .clock(clock),
    .reset(reset),

    // IFU与icache的握手接口
    .icache_ivalid(icache_ivalid),
    .icache_idata(icache_idata),
    .icache_iarready(icache_iarready),
    .ifu_arvalid(ifu_arvalid),
    .ifu_araddr(ifu_araddr),
    .ifu_rready(ifu_rready),

    // 传输至idu的数据
    .ifu_inst0(ifu_inst_0),
    .ifu_pc0(ifu_pc_0),
    .ifu_valid_0(ifu_valid_0),
    .ifu_inst1(ifu_inst_1),
    .ifu_pc1(ifu_pc_1),
    .ifu_valid_1(ifu_valid_1),

    // Jump Target
    .jump_addr(jump_addr),
    .jump_flag(jump_flag),
    .exc_jump_addr(exc_jump_addr),
    .exc_jump_flag(exc_jump_flag)
  );

  IFU_IDU_pipeline IFU_IDU_pipeline0(
    .clock(clock),
    .reset(reset),

    .ifu_inst_0(ifu_inst_0),
    .ifu_pc_0(ifu_pc_0),
    .ifu_valid_0(ifu_valid_0),
    .ifu_inst_1(ifu_inst_1),
    .ifu_pc_1(ifu_pc_1),
    .ifu_valid_1(ifu_valid_1),

    .idu_pc_0(ifu_idu_pc_0),
    .idu_inst_0(ifu_idu_inst_0),
    .idu_valid_0(ifu_idu_valid_0),
    .idu_pc_1(ifu_idu_pc_0),
    .idu_inst_1(ifu_idu_inst_0),
    .idu_valid_1(ifu_idu_valid_0)
  );

  IDU_top IDU0(
    .clock(clock),
    .reset(reset),
    // 来自ifu
    .ifu_valid_0(ifu_idu_valid_0),
    .ifu_pc_0(ifu_idu_pc_0),
    .ifu_inst_0(ifu_idu_inst_0),
    .ifu_valid_1(ifu_idu_valid_1),
    .ifu_pc_1(ifu_idu_pc_1),
    .ifu_inst_1(ifu_idu_inst_1),
    // 输出到RENAME和ISSUE的指令有效信号
    .idu_valid_0(idu_valid_0),
    .idu_valid_1(idu_valid_1),
    .idu_rs1_0_valid(idu_rs1_0_valid),
    .idu_rs2_0_valid(idu_rs2_0_valid),
    .idu_rd_0_valid(idu_rd_0_valid),
    .idu_rs1_1_valid(idu_rs1_1_valid),
    .idu_rs2_1_valid(idu_rs2_1_valid),
    .idu_rd_1_valid(idu_rd_1_valid),
    .idu_rd_0(idu_rd_0),
    .idu_rd_1(idu_rd_1),
    // 输出到rename
    .idu_rs1_0(idu_rs1_0),
    .idu_rs2_0(idu_rs2_0),
    .idu_rs1_1(idu_rs1_1),
    .idu_rs2_1(idu_rs2_1),
    // 来自rename
    .rename_prs1_0(rename_prs1_0),
    .rename_prs2_0(rename_prs2_0),
    .rename_nprd_0(rename_nprd_0),
    .rename_oprd_0(rename_oprd_0),
    .rename_prs1_1(rename_prs1_1),
    .rename_prs2_1(rename_prs2_1),
    .rename_nprd_1(rename_nprd_1),
    .rename_oprd_1(rename_oprd_1),
    // 输出到issue
    .idu_prs1_0(idu_prs1_0),
    .idu_prs2_0(idu_prs2_0),
    .idu_prd_0(idu_prd_0),
    .idu_oprd_0(idu_oprd_0),
    .idu_pc_0(idu_pc_0),
    .idu_imm_0(idu_imm_0),
    .idu_imm_0_valid(idu_imm_0_valid),
    .idu_op_0(idu_op_0),
    .idu_fu_type_0(idu_fu_type_0),
    
    .idu_prs1_1(idu_prs1_1),
    .idu_prs2_1(idu_prs2_1),
    .idu_prd_1(idu_prd_1),
    .idu_oprd_1(idu_oprd_1),
    .idu_pc_1(idu_pc_1),
    .idu_imm_1(idu_imm_1),
    .idu_imm_1_valid(idu_imm_1_valid),
    .idu_op_1(idu_op_1),
    .idu_fu_type_1(idu_fu_type_1),

    .idu_inst_0(idu_inst_0),
    .idu_inst_1(idu_inst_1)
  );

  IDU_ISSUE_pipeline IDU_ISSUE_pipeline0(
    .clock(clock),
    .reset(reset),

    // idu
    .idu_inst_0(idu_inst_0),
    .idu_valid_0(idu_valid_0),
    .idu_rs1_0_valid(idu_rs1_0_valid),
    .idu_rs2_0_valid(idu_rs2_0_valid),
    .idu_rd_0_valid(idu_rd_0_valid),
    .idu_rd_0(idu_rd_0),
    .idu_prs1_0(idu_prs1_0),
    .idu_prs2_0(idu_prs2_0),
    .idu_prd_0(idu_prd_0),
    .idu_oprd_0(idu_oprd_0),
    .idu_pc_0(idu_pc_0),
    .idu_imm_0(idu_imm_0),
    .idu_imm_0_valid(idu_imm_0_valid),
    .idu_op_0(idu_op_0),
    .idu_fu_type_0(idu_fu_type_0),
    
    .idu_inst_1(idu_inst_1),
    .idu_valid_1(idu_valid_1),
    .idu_rs1_1_valid(idu_rs1_1_valid),
    .idu_rs2_1_valid(idu_rs2_1_valid),
    .idu_rd_1_valid(idu_rd_1_valid),
    .idu_rd_1(idu_rd_1),
    .idu_prs1_1(idu_prs1_1),
    .idu_prs2_1(idu_prs2_1),
    .idu_prd_1(idu_prd_1),
    .idu_oprd_1(idu_oprd_1),
    .idu_pc_1(idu_pc_1),
    .idu_imm_1(idu_imm_1),
    .idu_imm_1_valid(idu_imm_1_valid),
    .idu_op_1(idu_op_1),
    .idu_fu_type_1(idu_fu_type_1),

    .issue_inst_0(issue_inst_0),
    .issue_valid_0(issue_valid_0),
    .issue_prs1_0_valid(issue_prs1_valid_0),
    .issue_prs2_0_valid(issue_prs2_valid_0),
    .issue_prd_0_valid(issue_prd_valid_0),
    .issue_rd_0(issue_rd_0),
    .issue_prs1_0(issue_prs1_0),
    .issue_prs2_0(issue_prs2_0),
    .issue_prd_0(issue_prd_0),
    .issue_oprd_0(issue_oprd_0),
    .issue_pc_0(issue_pc_0),
    .issue_imm_0(issue_imm_0),
    .issue_imm_0_valid(issue_imm_valid_0),
    .issue_op_0(issue_op_0),
    .issue_fu_type_0(issue_fu_type_0),
    
    .issue_inst_1(issue_inst_1),
    .issue_valid_1(issue_valid_1),
    .issue_prs1_1_valid(issue_prs1_valid_1),
    .issue_prs2_1_valid(issue_prs2_valid_1),
    .issue_prd_1_valid(issue_prd_valid_1),
    .issue_rd_1(issue_rd_1),
    .issue_prs1_1(issue_prs1_1),
    .issue_prs2_1(issue_prs2_1),
    .issue_prd_1(issue_prd_1),
    .issue_oprd_1(issue_oprd_1),
    .issue_pc_1(issue_pc_1),
    .issue_imm_1(issue_imm_1),
    .issue_imm_1_valid(issue_imm_valid_1),
    .issue_op_1(issue_op_1),
    .issue_fu_type_1(issue_fu_type_1)
  );

  // Dispatch - iq
  ISSUE_top ISSUE0(
    .clock(clock),
    .reset(reset),

    // 来自idu
    .idu_valid_0(issue_valid_0),
    .idu_prs1_valid_0(issue_prs1_valid_0),
    .idu_prs2_valid_0(issue_prs2_valid_0),
    .idu_prd_valid_0(issue_prd_valid_0),
    .idu_prs1_0(issue_prs1_0),
    .idu_prs2_0(issue_prs2_0),
    .idu_prd_0(issue_prd_0),
    .idu_pc_0(issue_pc_0),
    .idu_imm_0(issue_imm_0),
    .idu_imm_valid_0(issue_imm_valid_0),
    .idu_op_0(issue_op_0),
    .idu_fu_type_0(issue_fu_type_0),

    .idu_valid_1(issue_valid_1),
    .idu_prs1_valid_1(issue_prs1_valid_1),
    .idu_prs2_valid_1(issue_prs2_valid_1),
    .idu_prd_valid_1(issue_prd_valid_1),
    .idu_prs1_1(issue_prs1_1),
    .idu_prs2_1(issue_prs2_1),
    .idu_prd_1(issue_prd_1),
    .idu_pc_1(issue_pc_1),
    .idu_imm_1(issue_imm_1),
    .idu_imm_valid_1(issue_imm_valid_1),
    .idu_op_1(issue_op_1),
    .idu_fu_type_1(issue_fu_type_1),

    // rob
    .rob_idx_0(rob_idx_0),
    .rob_idx_1(rob_idx_1),

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
    .lsu_issue_imm(lsu_issue_imm),
    .lsu_issue_imm_valid(lsu_issue_imm_valid),
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
    .bru_issue_rob_idx(bru_issue_rob_idx),

    // retire
    .retire_valid_0(retire_valid_0),
    .retire_prd_0(retire_preg_0),
    .retire_valid_1(retire_valid_1),
    .retire_prd_1(retire_preg_1)
  );

  ISSUE_EXU_pipeline ISSUE_EXU_pipeline0(
    .clock(clock),
    .reset(reset),
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
    .lsu_issue_imm(lsu_issue_imm),
    .lsu_issue_imm_valid(lsu_issue_imm_valid),
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
    .bru_issue_rob_idx(bru_issue_rob_idx),

    .alu_valid(alu_valid),
    .alu_op(alu_op),
    .alu_imm(alu_imm),
    .alu_imm_valid(alu_imm_valid),
    .alu_pc(alu_pc),
    .alu_prs1(alu_prs1),
    .alu_prs2(alu_prs2),
    .alu_prd(alu_prd),
    .alu_rob_idx(alu_rob_idx),

    .lsu_valid(lsu_valid),
    .lsu_op(lsu_op),
    .lsu_imm(lsu_imm),
    .lsu_imm_valid(lsu_imm_valid),
    .lsu_pc(lsu_pc),
    .lsu_prs1(lsu_prs1),
    .lsu_prs2(lsu_prs2),
    .lsu_prd(lsu_prd),
    .lsu_rob_idx(lsu_rob_idx),

    .bru_valid(bru_valid),
    .bru_op(bru_op),
    .bru_imm(bru_imm),
    .bru_imm_valid(bru_imm_valid),
    .bru_pc(bru_pc),
    .bru_prs1(bru_prs1),
    .bru_prs2(bru_prs2),
    .bru_prd(bru_prd),
    .bru_rob_idx(bru_rob_idx)
  );

  EXU_top EXU0(
    .clock(clock),
    .reset(reset),

    .alu_psrc1(alu_psrc1),
    .alu_psrc2(alu_psrc2),
    .lsu_psrc1(lsu_psrc1),
    .lsu_psrc2(lsu_psrc2),
    .bru_psrc1(bru_psrc1),
    .bru_psrc2(bru_psrc2),

    .alu_issue_valid(alu_valid),
    .alu_issue_op(alu_op),
    .alu_issue_imm(alu_imm),
    .alu_issue_imm_valid(alu_imm_valid),
    .alu_issue_pc(alu_pc),
    .alu_issue_rob_idx(alu_rob_idx),

    .lsu_issue_valid(lsu_valid),
    .lsu_issue_op(lsu_op),
    .lsu_issue_imm(lsu_imm),
    .lsu_issue_imm_valid(lsu_imm_valid),
    .lsu_issue_pc(lsu_pc),
    .lsu_issue_rob_idx(lsu_rob_idx),

    .bru_issue_valid(bru_valid),
    .bru_issue_op(bru_op),
    .bru_issue_imm(bru_imm),
    .bru_issue_imm_valid(bru_imm_valid),
    .bru_issue_pc(bru_pc),
    .bru_issue_rob_idx(bru_rob_idx),

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

    .alu_valid(alu_wb_valid),
    .alu_wd(alu_wb_wd),
    .alu_rob_idx(alu_wb_rob_idx),

    .lsu_load_valid(lsu_wb_load_valid),
    .lsu_store_valid(lsu_wb_store_valid),
    .lsu_wd(lsu_wb_wd),
    .lsu_store_addr(lsu_store_addr),
    .lsu_store_data(lsu_store_data),
    .lsu_store_op(lsu_store_op),
    .lsu_rob_idx(lsu_wb_rob_idx),

    .bru_valid(bru_wb_valid),
    .bru_jump_addr(bru_wb_jump_addr),
    .bru_jump_flag(bru_wb_jump_flag),
    .bru_wd(bru_wb_wd),
    .bru_rob_idx(bru_wb_rob_idx)
  );

  EXU_WB_pipeline EXU_WB_pipeline0(
    .clock(clock),
    .reset(reset),

    .alu_valid(alu_wb_valid),
    .alu_wd(alu_wb_wd),
    .alu_rob_idx(alu_wb_rob_idx),
    .lsu_valid(lsu_wb_load_valid && lsu_wb_store_valid),
    .lsu_wd(lsu_wb_wd),
    .lsu_rob_idx(lsu_wb_rob_idx),
    .bru_valid(bru_wb_valid),
    .bru_jump_addr(bru_wb_jump_addr),
    .bru_jump_flag(bru_wb_jump_flag),
    .bru_wd(bru_wb_wd),
    .bru_rob_idx(bru_wb_rob_idx),

    .wb_alu_valid(wb_alu_valid),
    .wb_alu_wd(wb_alu_wd),
    .wb_alu_rob_idx(wb_alu_rob_idx),
    .wb_lsu_valid(wb_lsu_valid),
    .wb_lsu_wd(wb_lsu_wd),
    .wb_lsu_rob_idx(wb_lsu_rob_idx),
    .wb_bru_valid(wb_bru_valid),
    .wb_bru_jump_addr(wb_bru_jump_addr),
    .wb_bru_jump_flag(wb_bru_jump_flag),
    .wb_bru_wd(wb_bru_wd),
    .wb_bru_rob_idx(wb_bru_rob_idx)
  );

  ROB ROB0(
    .clock(clock),
    .reset(reset),

    .idu_valid_0(issue_valid_0),
    .idu_fu_type_0(issue_fu_type_0),
    .idu_rd_0_valid(issue_prd_valid_0),
    .idu_rd_0(issue_rd_0),
    .idu_pc_0(issue_pc_0),
    .idu_preg_0(issue_prd_0),
    .idu_opreg_0(issue_oprd_0),

    .idu_valid_1(issue_valid_1),
    .idu_fu_type_1(issue_fu_type_1),
    .idu_rd_1_valid(issue_prd_valid_1),
    .idu_rd_1(issue_rd_1),
    .idu_pc_1(issue_pc_1),
    .idu_preg_1(issue_prd_1),
    .idu_opreg_1(issue_oprd_1),

    .rob_idx_0(rob_idx_0),
    .rob_idx_1(rob_idx_1),

    .wb_rob_valid_0(wb_alu_valid),
    .wb_rob_idx_0(wb_alu_rob_idx),
    .wb_rob_wd_0(wb_alu_wd),
    .wb_rob_valid_1(wb_lsu_valid),
    .wb_rob_idx_1(wb_lsu_rob_idx),
    .wb_rob_wd_1(wb_lsu_wd),
    .wb_rob_valid_2(wb_bru_valid),
    .wb_rob_idx_2(wb_bru_rob_idx),
    .wb_rob_wd_2(wb_bru_wd),
    .wb_rob_jump_addr(wb_bru_jump_addr),
    .wb_rob_jump_flag(wb_bru_jump_flag),

    // 释放物理寄存器
    .retire_valid_0(retire_valid_0),
    .retire_valid_1(retire_valid_1),
    .retire_store_valid_0(retire_store_valid_0),
    .retire_store_valid_1(retire_store_valid_1),
    .retire_rd_valid_0(retire_rd_valid_0),
    .retire_rd_valid_1(retire_rd_valid_1),
    .retire_opreg_0(retire_opreg_0),
    .retire_opreg_1(retire_opreg_1),
    .retire_areg_0(retire_areg_0),
    .retire_areg_1(retire_areg_1),
    .retire_preg_0(retire_preg_0),
    .retire_preg_1(retire_preg_1),
    .retire_rob_idx_0(retire_rob_idx_0),
    .retire_rob_idx_1(retire_rob_idx_1),

    .retire_wa_0(retire_wa_0),
    .retire_wd_0(retire_wd_0),
    .retire_wa_1(retire_wa_1),
    .retire_wd_1(retire_wd_1),

    .idu_inst_0(issue_inst_0),
    .idu_inst_1(issue_inst_1)
  );

  RENAME_top RENAME0(
    .clock(clock),
    .reset(reset),
    // idu - rename
    .idu_inst0_valid(idu_valid_0),
    .idu_rs1_0(idu_rs1_0),
    .idu_rs1_0_valid(idu_rs1_0_valid),
    .idu_rs2_0(idu_rs2_0),
    .idu_rs2_0_valid(idu_rs2_0_valid),
    .idu_rd_0(idu_rd_0),
    .idu_rd_0_valid(idu_rd_0_valid),
    .idu_inst1_valid(idu_valid_1),
    .idu_rs1_1(idu_rs1_1),
    .idu_rs1_1_valid(idu_rs1_1_valid),
    .idu_rs2_1(idu_rs2_1),
    .idu_rs2_1_valid(idu_rs2_1_valid),
    .idu_rd_1(idu_rd_1),
    .idu_rd_1_valid(idu_rd_1_valid),
    .rename_prs1_0(rename_prs1_0),
    .rename_prs2_0(rename_prs2_0),
    .rename_nprd_0(rename_nprd_0),
    .rename_prs1_1(rename_prs1_1),
    .rename_prs2_1(rename_prs2_1),
    .rename_nprd_1(rename_nprd_1),
    .rename_oprd_0(rename_oprd_0),
    .rename_oprd_1(rename_oprd_1),
    // retire 释放物理寄存器
    .rob_retire_valid_0(retire_rd_valid_0 & retire_valid_0),
    .rob_retire_opreg_0(retire_opreg_0),
    .rob_retire_valid_1(retire_rd_valid_1 & retire_valid_1),
    .rob_retire_opreg_1(retire_opreg_1),
    .rob_retire_areg_0(retire_areg_0),
    .rob_retire_areg_1(retire_areg_1),
    .rob_retire_preg_0(retire_preg_0),
    .rob_retire_preg_1(retire_preg_1)
  );

  STORE_BUFFER STORE_BUFFER0(
    .clock(clock),
    .reset(reset),
    .store_valid(lsu_wb_store_valid),
    .store_addr(lsu_store_addr),
    .store_data(lsu_store_data),
    .store_op(lsu_store_op),
    .store_rob_idx(lsu_wb_rob_idx),

    // retire
    .retire_valid_0(retire_store_valid_0),
    .retire_rob_idx_0(retire_rob_idx_0),
    .retire_valid_1(retire_store_valid_1),
    .retire_rob_idx_1(retire_rob_idx_1),
    
    .store_awvalid(lsu_awvalid),
    .store_awready(lsu_awready),
    .store_awaddr(lsu_awaddr),
    .store_awlen(lsu_awlen),
    .store_awsize(lsu_awsize),
    .store_awid(lsu_awid),
    .store_awburst(lsu_awburst),
    .store_wvalid(lsu_wvalid),
    .store_wready(lsu_wready),
    .store_wdata(lsu_wdata),
    .store_wstrb(lsu_wstrb),
    .store_wlast(lsu_wlast),
    .store_bvalid(lsu_bvalid),
    .store_bready(lsu_bready),
    .store_bresp(lsu_bresp),
    .store_bid(lsu_bid)
  );

  PRF preg_file(
    .clock(clock),
    .reset(reset),
    .pra0_0(alu_prs1),
    .pra0_1(alu_prs2),
    .pra1_0(lsu_prs1),
    .pra1_1(lsu_prs2),
    .pra2_0(bru_prs1),
    .pra2_1(bru_prs2),

    .prd0_0(alu_psrc1),
    .prd0_1(alu_psrc2),
    .prd1_0(lsu_psrc1),
    .prd1_1(lsu_psrc2),
    .prd2_0(bru_psrc1),
    .prd2_1(bru_psrc2),
    
    // wb
    .we_0(retire_rd_valid_0 && retire_valid_0),
    .wa_0(retire_wa_0),  
    .wd_0(retire_wd_0),
    .we_1(retire_rd_valid_1 && retire_valid_1),
    .wa_1(retire_wa_1),
    .wd_1(retire_wd_1)
  );

endmodule 