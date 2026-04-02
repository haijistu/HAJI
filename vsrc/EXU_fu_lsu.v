`include "defines.v"
module FU_lsu (
  input                             clock,
  input                             reset,

  // 来自PRF的源操作数
  input [`WORD_WIDTH-1:0]           lsu_psrc1,
  input [`WORD_WIDTH-1:0]           lsu_psrc2,

  // 发射到执行单元的指令信息
  input                             lsu_issue_valid,
  input [`OP_WIDTH-1:0]             lsu_issue_op,
  input [`WORD_WIDTH-1:0]           lsu_issue_imm,
  input                             lsu_issue_imm_valid,
  input [`PADDR_WIDTH-1:0]          lsu_issue_pc,

  // AXI 读通道
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

  // 写回信号 - load
  output [`WORD_WIDTH-1:0]          lsu_wd,
  output                            lsu_load_valid,
  output                            lsu_store_valid,
  output [2:0]                      lsu_store_op,
  output [`PADDR_WIDTH-1:0]         lsu_store_addr,
  output [`WORD_WIDTH-1:0]          lsu_store_data
);
  // 内部信号定义
  wire [`WORD_WIDTH-1:0]  lsu_src1;
  wire [`WORD_WIDTH-1:0]  lsu_src2;
  wire [`PADDR_WIDTH-1:0] lsu_addr;
  // 操作数选择
  assign lsu_src1 = lsu_psrc1;
  assign lsu_src2 = lsu_issue_imm_valid ? lsu_issue_imm : lsu_psrc2;
  
  // 计算访存地址
  assign lsu_addr = lsu_src1 + lsu_src2;

  wire lw_inst  = ~lsu_issue_op[3] & ~lsu_issue_op[2] &  lsu_issue_op[1] & ~lsu_issue_op[0];
  wire lbu_inst = ~lsu_issue_op[3] &  lsu_issue_op[2] & ~lsu_issue_op[1] & ~lsu_issue_op[0];
  wire lb_inst  = ~lsu_issue_op[3] & ~lsu_issue_op[2] & ~lsu_issue_op[1] & ~lsu_issue_op[0];
  wire lhu_inst = ~lsu_issue_op[3] &  lsu_issue_op[2] &  lsu_issue_op[1] &  lsu_issue_op[0];
  wire lh_inst  = ~lsu_issue_op[3] & ~lsu_issue_op[2] & ~lsu_issue_op[1] &  lsu_issue_op[0];
  wire sw_inst  =  lsu_issue_op[3] & ~lsu_issue_op[2] &  lsu_issue_op[1] & ~lsu_issue_op[0];
  wire sb_inst  =  lsu_issue_op[3] & ~lsu_issue_op[2] & ~lsu_issue_op[1] & ~lsu_issue_op[0];
  wire sh_inst  =  lsu_issue_op[3] & ~lsu_issue_op[2] & ~lsu_issue_op[1] &  lsu_issue_op[0];

  wire load_inst = lw_inst | lbu_inst | lb_inst | lh_inst | lhu_inst;
  assign lsu_store_valid = sb_inst | sw_inst | sh_inst;
  assign lsu_store_op = {sw_inst, sh_inst, sb_inst};
  assign lsu_store_data = sw_inst ? lsu_psrc2 : sb_inst ? {4{lsu_psrc2[7:0]}} : sh_inst ? {2{lsu_psrc2[15:0]}} : 0;
  assign lsu_store_addr = lsu_addr;

  localparam C0 = 2'b00, C1 = 2'b01, C2 = 2'b10, C3 = 2'b11;
  reg [1:0] state;
  always @(posedge clock) begin
    if(reset) begin
      state <= C0;
    end
    case (state)
      C0: state <= (lsu_issue_valid && load_inst) ? C1 : C0;
      C1: state <= lsu_arready ? C2 : C1;
      C2: state <= lsu_rvalid && lsu_rlast && (lsu_rid == 4'b0000) && (lsu_rresp == 2'b00) ? C0 : C2;
      default: state <= C0;
    endcase
  end
  
  assign lsu_arvalid = (state == C1);
  assign lsu_araddr = lsu_addr;
  assign lsu_arlen = 8'd0;
  assign lsu_arsize[0] = lh_inst | lhu_inst;
  assign lsu_arsize[1] = lw_inst | lw_inst; 
  assign lsu_arid = 4'b0000;
  assign lsu_arburst = 2'b01;

  assign lsu_rready = (state == C2);
  assign lsu_load_valid = (state == C2) && lsu_rvalid && lsu_rlast && (lsu_rid == 4'b0000) && (lsu_rresp == 2'b00);
  assign lsu_wd = lw_inst ? lsu_rdata :
              (lbu_inst && lsu_addr[1:0] == 2'b11) ? {24'd0, lsu_rdata[31:24]} :
              (lbu_inst && lsu_addr[1:0] == 2'b10) ? {24'd0, lsu_rdata[23:16]} :
              (lbu_inst && lsu_addr[1:0] == 2'b01) ? {24'd0, lsu_rdata[15: 8]} :
              (lbu_inst && lsu_addr[1:0] == 2'b00) ? {24'd0, lsu_rdata[ 7: 0]} :
              (lb_inst  && lsu_addr[1:0] == 2'b11) ? {{24{lsu_rdata[31]}}, lsu_rdata[31:24]} :
              (lb_inst  && lsu_addr[1:0] == 2'b10) ? {{24{lsu_rdata[23]}}, lsu_rdata[23:16]} :
              (lb_inst  && lsu_addr[1:0] == 2'b01) ? {{24{lsu_rdata[15]}}, lsu_rdata[15: 8]} :
              (lb_inst  && lsu_addr[1:0] == 2'b00) ? {{24{lsu_rdata[ 7]}}, lsu_rdata[ 7: 0]} :
              (lhu_inst && lsu_addr[1:0] == 2'b10) ? {16'd0, lsu_rdata[31:16]} :
              (lhu_inst && lsu_addr[1:0] == 2'b00) ? {16'd0, lsu_rdata[15: 0]} :
              (lh_inst  && lsu_addr[1:0] == 2'b10) ? {{16{lsu_rdata[31]}}, lsu_rdata[31:16]} :
              (lh_inst  && lsu_addr[1:0] == 2'b00) ? {{16{lsu_rdata[15]}}, lsu_rdata[15: 0]} : 0;
endmodule
