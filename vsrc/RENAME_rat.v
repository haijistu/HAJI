`include "defines.v"
module RENAME_rat (
  input       clock,
  input       reset,
  // 读取物理寄存器编号
  input       [`REG_ADDR_WIDTH-1:0 ]  idu_rs1_0,
  input       [`REG_ADDR_WIDTH-1:0 ]  idu_rs2_0,
  input       [`REG_ADDR_WIDTH-1:0 ]  idu_rd_0,
  input       [`REG_ADDR_WIDTH-1:0 ]  idu_rs1_1,
  input       [`REG_ADDR_WIDTH-1:0 ]  idu_rs2_1,
  input       [`REG_ADDR_WIDTH-1:0 ]  idu_rd_1,
  output      [`PREG_ADDR_WIDTH-1:0]  prs1_0,
  output      [`PREG_ADDR_WIDTH-1:0]  prs2_0,
  output      [`PREG_ADDR_WIDTH-1:0]  oprd_0,
  output      [`PREG_ADDR_WIDTH-1:0]  prs1_1,
  output      [`PREG_ADDR_WIDTH-1:0]  prs2_1,
  output      [`PREG_ADDR_WIDTH-1:0]  oprd_1,

  // 更新映射关系
  input       [`PREG_ADDR_WIDTH-1:0]  nprd_0,
  input                               nprd_0_we,
  input       [`PREG_ADDR_WIDTH-1:0]  nprd_1,
  input                               nprd_1_we,

  input                               retire_valid_0,
  input                               retire_valid_1,
  input       [`REG_ADDR_WIDTH-1:0]   retire_areg_0,
  input       [`REG_ADDR_WIDTH-1:0]   retire_areg_1,
  input       [`PREG_ADDR_WIDTH-1:0]  retire_preg_0,
  input       [`PREG_ADDR_WIDTH-1:0]  retire_preg_1
);
  
  // 基于 SRAM 实现重命名寄存器映射表
  reg [`PREG_ADDR_WIDTH-1:0] rat [`REG_NUM-1:0]; // 逻辑寄存器到物理寄存器的映射表
  reg [`PREG_ADDR_WIDTH-1:0] retire_rat [`REG_NUM-1:0];

  // 重命名逻辑
  // 1. 读取源寄存器的物理寄存器编号
  assign prs1_0 = rat[idu_rs1_0];
  assign prs2_0 = rat[idu_rs2_0];
  assign prs1_1 = rat[idu_rs1_1];
  assign prs2_1 = rat[idu_rs2_1];
  assign oprd_0 = rat[idu_rd_0];
  assign oprd_1 = rat[idu_rd_1];
  
  integer i;
  // 2. 更新目的寄存器的映射关系
  always @(posedge clock) begin
    if(reset) begin
      // 重置时，所有逻辑寄存器映射到物理寄存器0
      for (i = 0; i < `REG_NUM; i = i + 1) begin
        rat[i] <= 0;
      end
    end else begin
      // 更新映射关系
      if (nprd_0_we && (idu_rd_0 != 0)) begin
        rat[idu_rd_0] <= nprd_0; // 将逻辑寄存器idu_rd_0映射到新的物理寄存器nprd_0
      end
      if (nprd_1_we && (idu_rd_1 != 0)) begin
        rat[idu_rd_1] <= nprd_1; // 将逻辑寄存器idu_rd_1映射到新的物理寄存器nprd_1
      end
    end
  end

  always @(posedge clock) begin
    if(reset) begin
      for (i = 0; i < `REG_NUM; i = i + 1) begin
        retire_rat[i] <= 0; // 对应0号物理寄存器
      end
    end
    else begin
      if(retire_valid_0) begin
        retire_rat[retire_areg_0] <= retire_preg_0;
      end
      if(retire_valid_1) begin
        retire_rat[retire_areg_1] <= retire_preg_1;
      end
    end
  end

endmodule