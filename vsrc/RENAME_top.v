`include "defines.v"
module RENAME_top (
  input       clock,
  input       reset,
  // 来自 IDU 的指令信息
  input                             idu_inst0_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rs1_0,
  input                             idu_rs1_0_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rs2_0,
  input                             idu_rs2_0_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rd_0,
  input                             idu_rd_0_valid,

  input                             idu_inst1_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rs1_1,
  input                             idu_rs1_1_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rs2_1,
  input                             idu_rs2_1_valid,
  input       [`REG_ADDR_WIDTH-1:0] idu_rd_1,
  input                             idu_rd_1_valid,

  // 物理寄存器编号
  output      [`PREG_ADDR_WIDTH-1:0]  rename_prs1_0,
  output      [`PREG_ADDR_WIDTH-1:0]  rename_prs2_0,
  output      [`PREG_ADDR_WIDTH-1:0]  rename_nprd_0,
  output      [`PREG_ADDR_WIDTH-1:0]  rename_prs1_1,
  output      [`PREG_ADDR_WIDTH-1:0]  rename_prs2_1,
  output      [`PREG_ADDR_WIDTH-1:0]  rename_nprd_1,
  output      [`PREG_ADDR_WIDTH-1:0]  rename_oprd_0,
  output      [`PREG_ADDR_WIDTH-1:0]  rename_oprd_1,

  // ROB
  input                               rob_retire_valid_0,
  input       [`REG_ADDR_WIDTH-1:0]   rob_retire_areg_0,
  input       [`PREG_ADDR_WIDTH-1:0]  rob_retire_preg_0,
  input       [`PREG_ADDR_WIDTH-1:0]  rob_retire_opreg_0,
  input                               rob_retire_valid_1,
  input       [`REG_ADDR_WIDTH-1:0]   rob_retire_areg_1,
  input       [`PREG_ADDR_WIDTH-1:0]  rob_retire_preg_1,
  input       [`PREG_ADDR_WIDTH-1:0]  rob_retire_opreg_1
);
  wire rd_0_valid = idu_inst0_valid && idu_rd_0_valid && (idu_rd_0 != 0);
  wire rd_1_valid = idu_inst1_valid && idu_rd_1_valid && (idu_rd_1 != 0);
  wire raw_rs1_1;
  wire raw_rs2_1;
  wire waw_rd_0;
  wire [`PREG_ADDR_WIDTH-1:0] prs1_0;
  wire [`PREG_ADDR_WIDTH-1:0] prs2_0;
  wire [`PREG_ADDR_WIDTH-1:0] oprd_0;
  wire [`PREG_ADDR_WIDTH-1:0] nprd_0;
  wire [`PREG_ADDR_WIDTH-1:0] prs1_1;
  wire [`PREG_ADDR_WIDTH-1:0] prs2_1;
  wire [`PREG_ADDR_WIDTH-1:0] oprd_1;
  wire [`PREG_ADDR_WIDTH-1:0] nprd_1;
  wire nprd_0_we = waw_rd_0 ? 1'b0 : rd_0_valid;
  wire nprd_1_we = rd_1_valid;
  RENAME_freelist #(
    .DATA_WIDTH(`PREG_ADDR_WIDTH),
    .DATA_DEPTH(`PREG_NUM)
  ) rename_freelist  (
    .clock(clock),
    .reset(reset),
    .pop0_valid(rd_0_valid),
    .pop1_valid(rd_1_valid),
    .push0(rob_retire_opreg_0),
    .push0_valid(rob_retire_valid_0 && rob_retire_opreg_0 != 0),
    .push1(rob_retire_opreg_1),
    .push1_valid(rob_retire_valid_1 && rob_retire_opreg_1 != 0),
    .pop0(nprd_0),
    .pop1(nprd_1),
    .empty()
  );

  RENAME_rat rename_rat ( // 在retire阶段，更新映射关系为Architecture state
    .clock(clock),
    .reset(reset),
    
    .idu_rs1_0(idu_rs1_0),
    .idu_rs2_0(idu_rs2_0),
    .idu_rd_0(idu_rd_0),
    .idu_rs1_1(idu_rs1_1),
    .idu_rs2_1(idu_rs2_1),
    .idu_rd_1(idu_rd_1),
    .prs1_0(prs1_0),
    .prs2_0(prs2_0),
    .oprd_0(oprd_0),
    .prs1_1(prs1_1),
    .prs2_1(prs2_1),
    .oprd_1(oprd_1),

    .nprd_0(nprd_0),
    .nprd_0_we(nprd_0_we),
    .nprd_1(nprd_1),
    .nprd_1_we(nprd_1_we),

    .retire_areg_0(rob_retire_areg_0),
    .retire_areg_1(rob_retire_areg_1),
    .retire_preg_0(rob_retire_preg_0),
    .retire_preg_1(rob_retire_preg_1),
    .retire_valid_0(rob_retire_valid_0),
    .retire_valid_1(rob_retire_valid_1)
  );

  RENAME_check rename_check (
    .idu_rs1_0(idu_rs1_0),
    .idu_rs1_0_valid(idu_rs1_0_valid),
    .idu_rs2_0(idu_rs2_0),
    .idu_rs2_0_valid(idu_rs2_0_valid),
    .idu_rd_0(idu_rd_0),
    .idu_rd_0_valid(rd_0_valid),
    
    .idu_rs1_1(idu_rs1_1),
    .idu_rs1_1_valid(idu_rs1_1_valid),
    .idu_rs2_1(idu_rs2_1),
    .idu_rs2_1_valid(idu_rs2_1_valid),
    .idu_rd_1(idu_rd_1),
    .idu_rd_1_valid(rd_1_valid),

    .raw_rs1_1(raw_rs1_1),
    .raw_rs2_1(raw_rs2_1),
    .waw_rd_0(waw_rd_0)
  );

  assign rename_nprd_0 = nprd_0;
  assign rename_nprd_1 = nprd_1;
  assign rename_prs1_0 = prs1_0;
  assign rename_prs2_0 = prs2_0;
  assign rename_prs1_1 = raw_rs1_1 ? nprd_0 : prs1_1;
  assign rename_prs2_1 = raw_rs2_1 ? nprd_0 : prs2_1;

  assign rename_oprd_0 = oprd_0;
  assign rename_oprd_1 = waw_rd_0 ? nprd_0 : oprd_1;

endmodule