`include "defines.v"
module EXU_WB_pipeline (
  input clock,
  input reset,

  input                         alu_valid,
  input [`WORD_WIDTH-1:0]       alu_wd,
  input [`ROB_ADDR_WIDTH-1:0]   alu_rob_idx,

  input                         lsu_valid,
  input [`WORD_WIDTH-1:0]       lsu_wd,
  input [`ROB_ADDR_WIDTH-1:0]   lsu_rob_idx,

  input                         bru_valid,
  input [`PADDR_WIDTH-1:0]      bru_jump_addr,
  input                         bru_jump_flag,
  input [`WORD_WIDTH-1:0]       bru_wd,
  input [`ROB_ADDR_WIDTH-1:0]   bru_rob_idx,

  output reg                        wb_alu_valid,
  output reg [`WORD_WIDTH-1:0]      wb_alu_wd,
  output reg [`ROB_ADDR_WIDTH-1:0]  wb_alu_rob_idx,

  output reg                        wb_lsu_valid,
  output reg [`WORD_WIDTH-1:0]      wb_lsu_wd,
  output reg [`ROB_ADDR_WIDTH-1:0]  wb_lsu_rob_idx,

  output reg                        wb_bru_valid,
  output reg [`PADDR_WIDTH-1:0]     wb_bru_jump_addr,
  output reg                        wb_bru_jump_flag,
  output reg [`WORD_WIDTH-1:0]      wb_bru_wd,
  output reg [`ROB_ADDR_WIDTH-1:0]  wb_bru_rob_idx
);

always @(posedge clock) begin
  if(reset) begin
    wb_alu_valid <= 0;
    wb_alu_wd <= 0;
    wb_alu_rob_idx <= 0;
    wb_lsu_valid <= 0;
    wb_lsu_wd <= 0;
    wb_lsu_rob_idx <= 0;
    wb_bru_valid <= 0;
    wb_bru_jump_addr <= 0;
    wb_bru_jump_flag <= 0;
    wb_bru_wd <= 0;
    wb_bru_rob_idx <= 0;
  end 
  else begin
    if(alu_valid) begin
      wb_alu_valid <= 1;
      wb_alu_wd <= alu_wd;
      wb_alu_rob_idx <= alu_rob_idx;
    end
    else wb_alu_valid <= 0;

    if(lsu_valid) begin
      wb_lsu_valid <= 1;
      wb_lsu_wd <= lsu_wd;
      wb_lsu_rob_idx <= lsu_rob_idx;
    end
    else wb_lsu_valid <= 0;

    if(bru_valid) begin
      wb_bru_valid <= 1;
      wb_bru_jump_addr <= bru_jump_addr;
      wb_bru_jump_flag <= bru_jump_flag;
      wb_bru_wd <= bru_wd;
      wb_bru_rob_idx <= bru_rob_idx;
    end
    else wb_lsu_valid <= 0;
  end
end
  
endmodule