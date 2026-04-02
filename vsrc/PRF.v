`include "defines.v"
module PRF (
  input clock,
  input reset,
  // 三个读端口
  input [`PREG_ADDR_WIDTH-1:0]  pra0_0,
  input [`PREG_ADDR_WIDTH-1:0]  pra0_1,
  input [`PREG_ADDR_WIDTH-1:0]  pra1_0,
  input [`PREG_ADDR_WIDTH-1:0]  pra1_1,
  input [`PREG_ADDR_WIDTH-1:0]  pra2_0,
  input [`PREG_ADDR_WIDTH-1:0]  pra2_1,

  output [`WORD_WIDTH-1:0]      prd0_0,
  output [`WORD_WIDTH-1:0]      prd0_1,
  output [`WORD_WIDTH-1:0]      prd1_0,
  output [`WORD_WIDTH-1:0]      prd1_1,
  output [`WORD_WIDTH-1:0]      prd2_0,
  output [`WORD_WIDTH-1:0]      prd2_1,

  input [`WORD_WIDTH-1:0]       wd_0,
  input                         we_0,
  input [`PREG_ADDR_WIDTH-1:0]  wa_0,
  input [`WORD_WIDTH-1:0]       wd_1,
  input                         we_1,
  input [`PREG_ADDR_WIDTH-1:0]  wa_1
);

  reg [`WORD_WIDTH-1:0] prf [0:`PREG_NUM-1];
  integer i;
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      for(i = 0; i < `PREG_NUM; i = i + 1) begin
        prf[i] <= 0;
      end
    end
    else begin
      // 写端口
      if(we_0 && wa_0 != 0) prf[wa_0] <= wd_0; 
      if(we_1 && wa_1 != 0) prf[wa_1] <= wd_1; 
    end
  end
  
  assign prd0_0 = prf[pra0_0];
  assign prd0_1 = prf[pra0_1];
  assign prd1_0 = prf[pra1_0];
  assign prd1_1 = prf[pra1_1];
  assign prd2_0 = prf[pra2_0];
  assign prd2_1 = prf[pra2_1];

endmodule