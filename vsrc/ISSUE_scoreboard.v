`include "defines.v"
module ISSUE_scoreboard (
  input clock,
  input reset,
  // update
  input                         idu_alloc_valid_0,
  input [`PREG_ADDR_WIDTH-1:0]  idu_prd_0,
  input                         idu_alloc_valid_1,
  input [`PREG_ADDR_WIDTH-1:0]  idu_prd_1,

  input                         retire_valid_0,
  input [`PREG_ADDR_WIDTH-1:0]  retire_prd_0,
  input                         retire_valid_1,
  input [`PREG_ADDR_WIDTH-1:0]  retire_prd_1,

  // query
  input  [`PREG_ADDR_WIDTH-1:0] query_psrc1_0,
  input  [`PREG_ADDR_WIDTH-1:0] query_psrc2_0,
  input  [`PREG_ADDR_WIDTH-1:0] query_psrc1_1,
  input  [`PREG_ADDR_WIDTH-1:0] query_psrc2_1,
  output                        src1_ready_0,
  output                        src2_ready_0,
  output                        src1_ready_1,
  output                        src2_ready_1
);
  reg [`PREG_NUM-1:0] preg_ready;
  reg [`PREG_NUM-1:0] preg_ready_next;
  integer i;
  always @(*) begin
    // 默认保持
    for (i = 0; i < `PREG_NUM; i = i + 1)
      preg_ready_next[i] = preg_ready[i];

    // wb → 置1（覆盖）
    if (retire_valid_0 && retire_prd_0 != 0)
      preg_ready_next[retire_prd_0] = 1'b1;

    if (retire_valid_1 && retire_prd_1 != 0)
      preg_ready_next[retire_prd_1] = 1'b1;

    // rename → 置0
    if (idu_alloc_valid_0 && idu_prd_0 != 0)
      preg_ready_next[idu_prd_0] = 1'b0;

    if (idu_alloc_valid_1 && idu_prd_1 != 0)
      preg_ready_next[idu_prd_1] = 1'b0;
    
    preg_ready_next[0] = 1'b1; // 0号物理寄存器始终保持ready
  end

  always @(posedge clock) begin
    if(reset) begin 
      for(i = 0; i < `PREG_NUM; i = i + 1) begin
        preg_ready[i] <= 1;
      end
    end
    else begin
      for(i = 0; i < `PREG_NUM; i = i + 1) begin
        preg_ready[i] <= preg_ready_next[i];
      end
    end
  end
  assign src1_ready_0 = preg_ready_next[query_psrc1_0];
  assign src1_ready_1 = preg_ready_next[query_psrc1_1];
  assign src2_ready_0 = preg_ready_next[query_psrc2_0];
  assign src2_ready_1 = preg_ready_next[query_psrc2_1];
endmodule