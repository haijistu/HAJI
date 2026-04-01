`include "defines.v"
module IFU_top (
  input clock,
  input reset,

  // IFU与icache的握手接口
  input                               icache_ivalid, // 指令有效信号
  input [`ISSUE_NUM*`WORD_WIDTH-1:0]  icache_idata, // 指令
  input                               icache_iarready, // 取指地址准备好
  output                              ifu_arvalid, // 取指地址有效
  output [`PADDR_WIDTH-1:0]           ifu_araddr, // 取指地址
  output                              ifu_rready, // 取指数据准备好

  // 传输至idu的数据
  output reg [`PADDR_WIDTH-1:0] ifu_inst0,
  output reg [`PADDR_WIDTH-1:0] ifu_inst1,
  output                        ifu_valid_0,
  output                        ifu_valid_1,
  output [`PADDR_WIDTH-1:0]     ifu_pc0,
  output [`PADDR_WIDTH-1:0]     ifu_pc1,
  // Jump Target
  input [`PADDR_WIDTH-1:0] jump_addr,
  input jump_flag,
  input [`PADDR_WIDTH-1:0] exc_jump_addr,
  input exc_jump_flag
);
// 超标量设计的IFU模块，负责从icache中取指，并将指令传输给idu
// 每次取指获取两条指令，支持单发和双发模式
  // 上电初始化
  reg [`PADDR_WIDTH-1:0] pc = `INIT_PC;
  wire [`PADDR_WIDTH-1:0] next_pc = exc_jump_flag ? exc_jump_addr : jump_flag ? jump_addr : (pc + 32'd8);
  
  // C1: 发送取指请求
  // C2: 等待指令返回
  // C3: 指令有效，执行指令
  localparam C0 = 2'b00, C1 = 2'b01, C2 = 2'b10, C3 = 2'b11;
  reg [1:0] state;
  always @(posedge clock) begin
    if(reset) begin
      state <= C0;
    end
    else begin 
      case (state)
        C1: state <= icache_iarready ? C2 : C1;
        C2: state <= icache_ivalid ? C3 : C2;
        C3: state <= C1;
        default: state <= C1;
      endcase
    end
  end

  assign ifu_arvalid = (state == C1);
  assign ifu_araddr = pc;
  assign ifu_rready = (state == C2);
  always @(posedge clock) begin
    if(reset) pc <= `INIT_PC;
    else if (state == C3) pc <= next_pc;
  end

  assign ifu_pc0 = pc;
  assign ifu_pc1 = pc + 32'd4;
  always @(posedge clock) begin
    if(reset) {ifu_inst1, ifu_inst0} <= 64'd0;
    else if(icache_ivalid) {ifu_inst1, ifu_inst0} <= icache_idata;
  end
  assign ifu_valid_0 = (state == C3);
  assign ifu_valid_1 = (state == C3);
endmodule