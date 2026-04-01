`include "defines.v"
module ICACHE_top (
  input clock,
  input reset,
  
  // icache与IFU的握手接口
  input                     ifu_arvalid,
  input  [`PADDR_WIDTH-1:0] ifu_araddr,
  input                     ifu_rready,
  output                    icache_iarready,
  output                    icache_ivalid, // 指令有效信号
  output [`ISSUE_NUM*`WORD_WIDTH-1:0]  icache_idata, // 指令数据
  
  // IROM AXI BUS (只读接口)
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
  input  [3:0]              icache_bid
);

  // 块大小4B，块数16，总容量64B
  localparam block_size = 16;
  localparam block_num = 32;
  localparam offset_width = 4; // offset_width = log2(block_size);
  localparam index_width = 5;  // index_width = log2(block_num);
  localparam tag_width = `PADDR_WIDTH - offset_width - index_width;
  // Cache Line
  reg [block_size*8-1:0] cache_data [0:block_num-1];
  reg [tag_width-1:0] cache_tag [0:block_num-1];
  reg cache_valid [0:block_num-1];
  // 读请求状态
  // 计算地址分解
  wire [offset_width-1:0] offset = ifu_araddr[offset_width-1:0];
  wire [index_width-1:0] index = ifu_araddr[offset_width+index_width-1:offset_width];
  wire [tag_width-1:0] tag = ifu_araddr[`PADDR_WIDTH-1:offset_width+index_width];

  // 判断是否命中
  wire hit = cache_valid[index] && cache_tag[index] == tag;

  // icache状态机
  // C0: 空闲状态，等待ifu_arvalid，如果地址命中，输出指令；如果地址未命中，进入C1状态
  // C1: 发送读请求到IROM
  // C2: 等待读取数据
  // C3: 数据有效，更新cache
  reg [1:0] state;
  always @(posedge clock or posedge reset) begin
    if(reset) state <= 2'b00;
    else begin
      case (state)
        2'b00: state <= ifu_arvalid ? (hit ? 2'b00 : 2'b01) : 2'b00;
        2'b01: state <= icache_arready ? 2'b10 : 2'b01;
        2'b10: state <= icache_rvalid && icache_rlast ? 2'b00 : 2'b10;
        default: state <= 2'b00;
      endcase
    end
  end

  // 更新Cache
  always @(posedge clock) begin
    if(reset) begin
      integer i;
      for(i = 0; i < block_num; i = i + 1) begin
        cache_valid[i] <= 1'b0;
        cache_tag[i] <= 0;
        cache_data[i] <= 0;
      end
    end
    else if(state == 2'b10 && icache_rvalid && icache_rid == 4'b0000 && icache_rresp == 2'b00) begin
      if(icache_rlast) begin 
        cache_valid[index] <= 1'b1;
        cache_tag[index] <= tag;
      end
      // 多次读，写入同一个 cache_data[index] 中
      cache_data[index] <= (cache_data[index] >> 32) | {icache_rdata, {(block_size*8 - 32){1'b0}}}; // icache_rdata每次读4字节，根据参数配置补齐至于cache_data[index]同宽
    end
  end

  // AXI读请求信号
  assign icache_arvalid = (state == 2'b01);
  assign icache_araddr = {ifu_araddr[`PADDR_WIDTH-1:offset_width], {offset_width{1'b0}}}; // 地址对齐到块大小
  assign icache_arsize = 3'b010; // 4字节
  assign icache_arlen =  (block_size >> 2) - 1; // 读4次，每次4字节，总共16字节
  assign icache_arid = 4'b0000; // 固定ID
  assign icache_arburst = 2'b01; // 固定突发类型

  assign icache_rready = (state == 2'b10);

  // AXI写请求信号（不使用）
  assign icache_awvalid = 0;
  assign icache_awaddr = 0;
  assign icache_awlen = 0;
  assign icache_awsize = 0;
  assign icache_awid = 0;
  assign icache_awburst = 0;
  assign icache_wvalid = 0;
  assign icache_wdata = 0;
  assign icache_wstrb = 0;
  assign icache_wlast = 0;
  assign icache_bready = 0;

  // 延迟一个周期返回数据，模拟cache访问延迟
  reg                    ivalid;
  assign icache_iarready = (state == 2'b00);
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      ivalid <= 1'b0;
    end
    else begin
      if(ifu_arvalid && hit) begin
        ivalid <= 1'b1;
      end
      if(state == 2'b10 && icache_rvalid && icache_rlast && icache_rid == 4'b0000 && icache_rresp == 2'b00) begin
        ivalid <= 1'b1;
      end
      else if(ifu_rready) begin
        ivalid <= 1'b0;
      end
    end
  end
  assign icache_ivalid = ivalid;
  assign icache_idata = {cache_data[index] >> (offset * 8)}[63:0]; // 根据offset选择对应的4字节指令数据
endmodule