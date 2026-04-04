`include "defines.v"
module IFU_top (
  input clock,
  input reset,
  input stall,

  // IFU与icache的握手接口
  input                               icache_ivalid, // 指令有效信号
  input [`ISSUE_NUM*`WORD_WIDTH-1:0]  icache_idata, // 指令
  input                               icache_iarready, // 取指地址准备好
  output                              ifu_arvalid, // 取指地址有效
  output [`PADDR_WIDTH-1:0]           ifu_araddr, // 取指地址
  output                              ifu_rready, // 取指数据准备好

  // IDU-bru
  input                               idu_bru_valid,
  // retire-bru
  input                               retire_bru_valid,
  input [`PADDR_WIDTH-1:0]            retire_bru_addr,
  input                               retire_bru_flag,
  input [`PADDR_WIDTH-1:0]            retire_bru_pc,

  // 传输至idu的数据
  output reg [`PADDR_WIDTH-1:0] ifu_inst0,
  output reg [`PADDR_WIDTH-1:0] ifu_inst1,
  output                        ifu_valid_0,
  output                        ifu_valid_1,
  output [`PADDR_WIDTH-1:0]     ifu_pc0,
  output [`PADDR_WIDTH-1:0]     ifu_pc1,
  // Jump Target
  input [`PADDR_WIDTH-1:0] exc_jump_addr,
  input exc_jump_flag
);
// 超标量设计的IFU模块，负责从icache中取指，并将指令传输给idu
// 每次取指获取两条指令，支持单发和双发模式
  // 上电初始化
  reg [`PADDR_WIDTH-1:0] pc = `INIT_PC;
  wire [`PADDR_WIDTH-1:0] next_pc = exc_jump_flag ? exc_jump_addr : retire_bru_valid ? (retire_bru_flag ? retire_bru_addr : retire_bru_pc + 32'd4) : pc + 32'd8;
  
  // C1: 发送取指请求
  // C2: 等待指令返回
  // C3: 指令有效，执行指令
  localparam C0 = 3'b000, C1 = 3'b001, C2 = 3'b010, C3 = 3'b011, C4 = 3'b100;
  reg [2:0] state;
  always @(posedge clock) begin
    if(reset) begin
      state <= C0;
    end
    else if(!stall)begin 
      case (state)
        C1: state <= idu_bru_valid ? C4 : icache_iarready ? C2 : C1;
        C2: state <= icache_ivalid ? C3 : C2;
        C3: state <= C1;
        C4: state <= retire_bru_valid ? C1 : C4;
        default: state <= C1;
      endcase
    end
  end

  assign ifu_arvalid = (!stall) && (state == C1) && (!idu_bru_valid);
  assign ifu_araddr = pc;
  assign ifu_rready = (!stall) && (state == C2);

  always @(posedge clock) begin
    if(reset) pc <= `INIT_PC;
    else if(!stall) begin
      if (state == C3) pc <= next_pc;
      else if (retire_bru_valid) pc <= next_pc;
    end
  end

  assign ifu_pc0 = pc;
  assign ifu_pc1 = pc + 32'd4;
  always @(posedge clock) begin
    if(reset) {ifu_inst1, ifu_inst0} <= 64'd0;
    else if(!stall) begin
      if(icache_ivalid) {ifu_inst1, ifu_inst0} <= icache_idata;
    end
  end
  assign ifu_valid_0 = (!stall) && (state == C3);
  assign ifu_valid_1 = (!stall) && (state == C3);
endmodule