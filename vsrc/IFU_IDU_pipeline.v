`include "defines.v"
module IFU_IDU_pipeline (
  input clock,
  input reset,
  input stall,

  input [`PADDR_WIDTH-1:0]     ifu_pc_0,
  input [`WORD_WIDTH-1:0 ]     ifu_inst_0,
  input                        ifu_valid_0,
  input [`PADDR_WIDTH-1:0]     ifu_pc_1,
  input [`WORD_WIDTH-1:0 ]     ifu_inst_1,
  input                        ifu_valid_1,

  output reg [`PADDR_WIDTH-1:0]     idu_pc_0,
  output reg [`WORD_WIDTH-1:0 ]     idu_inst_0,
  output reg                        idu_valid_0,
  output reg [`PADDR_WIDTH-1:0]     idu_pc_1,
  output reg [`WORD_WIDTH-1:0 ]     idu_inst_1,
  output reg                        idu_valid_1
);

always @(posedge clock or posedge reset) begin
  if(reset) begin
    idu_inst_0 <= 0;
    idu_pc_0 <= 0;
    idu_valid_0 <= 0;
    idu_inst_1 <= 0;
    idu_pc_1 <= 0;
    idu_valid_1 <= 0;
  end
  else if(!stall) begin
    if(ifu_valid_0) begin
      idu_inst_0 <= ifu_inst_0;
      idu_pc_0 <= ifu_pc_0;
      idu_valid_0 <= 1'b1;
    end
    else idu_valid_0 <= 1'b0;

    if(ifu_valid_1) begin
      idu_inst_1 <= ifu_inst_1;
      idu_pc_1 <= ifu_pc_1;
      idu_valid_1 <= 1'b1;
    end
    else idu_valid_1 <= 1'b0;
  end
end

endmodule