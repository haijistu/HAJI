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
  output [`ISSUE_NUM*`WORD_WIDTH-1:0]  icache_idata, // 64bit=2×32bit指令
  
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
  // AXI写接口（不使用）
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

  // ====================== 固定参数（16字节Cache块） ======================
  localparam block_size   = 16;      // Cache块大小：16字节
  localparam block_num    = 32;      // Cache块数量
  localparam offset_width = 4;       // 偏移位宽：4位（0~15字节）
  localparam index_width  = 5;       // 索引位宽
  localparam tag_width    = `PADDR_WIDTH - offset_width - index_width;

  // ====================== 核心1：取指地址计算（4字节对齐，无修改） ======================
  wire [`PADDR_WIDTH-1:0] addr0 = ifu_araddr;        // 第一条指令地址（4字节对齐）
  wire [`PADDR_WIDTH-1:0] addr1 = ifu_araddr + 4;   // 第二条指令地址（必跨4字节）

  // ====================== 核心2：跨Cache块判断（解决你的核心问题） ======================
  // 16字节块：块内4字节单元 [0:0-3,1:4-7,2:8-11,3:12-15]
  // 单元3是最后一个4字节 → +4必跨块！
  wire cross_line = (addr0[offset_width-1:2] == 2'd3); 

  // ====================== 地址分解：当前块 + 下一个块（跨块用） ======================
  // 当前块（addr0所在块）
  wire [offset_width-1:0] offset0    = addr0[offset_width-1:0];
  wire [index_width-1:0]  index0     = addr0[offset_width+index_width-1:offset_width];
  wire [tag_width-1:0]    tag0       = addr0[`PADDR_WIDTH-1:offset_width+index_width];
  wire [`PADDR_WIDTH-1:0] line_addr0 = {addr0[`PADDR_WIDTH-1:offset_width], {offset_width{1'b0}}}; // 当前块对齐地址

  // 下一个块（addr1所在块，跨块时使用）
  wire [offset_width-1:0] offset1    = addr1[offset_width-1:0];
  wire [index_width-1:0]  index1     = addr1[offset_width+index_width-1:offset_width];
  wire [tag_width-1:0]    tag1       = addr1[`PADDR_WIDTH-1:offset_width+index_width];
  wire [`PADDR_WIDTH-1:0] line_addr1 = {addr1[`PADDR_WIDTH-1:offset_width], {offset_width{1'b0}}}; // 下一块对齐地址

  // ====================== Cache存储阵列 ======================
  reg [block_size*8-1:0]  cache_data [0:block_num-1]; // 128bit/块
  reg [tag_width-1:0]     cache_tag  [0:block_num-1];
  reg                     cache_valid[0:block_num-1];

  // ====================== 命中判断：单块/跨块 ======================
  wire hit0  = cache_valid[index0] && (cache_tag[index0] == tag0); // 当前块命中
  wire hit1  = cache_valid[index1] && (cache_tag[index1] == tag1); // 下一块命中
  wire hit   = cross_line ? (hit0 && hit1) : hit0;                 // 总命中：跨块需双块都命中

  // ====================== 扩展状态机：支持跨块读取 ======================
  // C0: 空闲/命中
  // C1: 读第一个块（当前块）
  // C2: 等待第一个块数据
  // C3: 读第二个块（跨块时）
  // C4: 等待第二个块数据
  reg [2:0] state;
  reg [`PADDR_WIDTH-1:0] axi_addr; // AXI读地址寄存器
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      state <= 3'd0;
      axi_addr <= 'b0;
    end else begin
      case(state)
        // 空闲：收到请求，命中保持C0，未命中进入C1读第一个块
        3'd0: begin
          if(ifu_arvalid && !hit) begin
            state <= 3'd1;
            axi_addr <= line_addr0;
          end
        end
        // 发第一个块读请求
        3'd1: state <= icache_arready ? 3'd2 : 3'd1;
        // 等待第一个块读完
        3'd2: begin
          if(icache_rvalid && icache_rlast) begin
            // 跨块：进入C3读第二个块；不跨块：回到C0
            state <= cross_line & ~hit1 ? 3'd3 : 3'd0;
            axi_addr <= line_addr1;
          end
        end
        // 发第二个块读请求（仅跨块）
        3'd3: state <= icache_arready ? 3'd4 : 3'd3;
        // 等待第二个块读完（仅跨块）
        3'd4: state <= (icache_rvalid && icache_rlast) ? 3'd0 : 3'd4;
        default: state <= 3'd0;
      endcase
    end
  end

  // ====================== Cache更新逻辑（支持双块写入） ======================
  integer i;
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      for(i=0; i<block_num; i=i+1) begin
        cache_valid[i] <= 1'b0;
        cache_tag[i]   <= 'b0;
        cache_data[i]  <= 'b0;
      end
    end
    // AXI读回数据，更新对应Cache块
    else if((state==3'd2 || state==3'd4) && icache_rvalid && icache_rid==4'b0000 && icache_rresp==2'b00) begin
      cache_data[axi_addr[offset_width+index_width-1:offset_width]] <= 
        {icache_rdata, cache_data[axi_addr[offset_width+index_width-1:offset_width]][block_size*8-1:32]};
      if(icache_rlast) begin
        cache_valid[axi_addr[offset_width+index_width-1:offset_width]] <= 1'b1;
        cache_tag[axi_addr[offset_width+index_width-1:offset_width]]   <= axi_addr[`PADDR_WIDTH-1:offset_width+index_width];
      end
    end
  end

  // ====================== AXI读接口控制 ======================
  assign icache_arvalid = (state == 3'd1 || state == 3'd3);
  assign icache_araddr  = axi_addr;        // 读寄存器中的块地址
  assign icache_arsize  = 3'b010;          // 32bit/次
  assign icache_arlen   = (block_size >> 2) - 1; // 4拍=16字节
  assign icache_arid    = 4'b0000;
  assign icache_arburst = 2'b01;           // 增量突发
  assign icache_rready  = (state == 3'd2 || state == 3'd4);

  // AXI写接口（全0，不使用）
  assign icache_awvalid = 1'b0;
  assign icache_awaddr  = 'b0;
  assign icache_awlen   = 'b0;
  assign icache_awsize  = 'b0;
  assign icache_awid    = 'b0;
  assign icache_awburst = 'b0;
  assign icache_wvalid  = 1'b0;
  assign icache_wdata   = 'b0;
  assign icache_wstrb   = 'b0;
  assign icache_wlast   = 1'b0;
  assign icache_bready  = 1'b0;

  // ====================== 指令有效信号 ======================
  reg ivalid;
  assign icache_iarready = (state == 3'd0); // 仅空闲时接收请求
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      ivalid <= 1'b0;
    end else begin
      // 条件1：单块/跨块 全部命中
      // 条件2：跨块/单块 读取完成
      if( (ifu_arvalid && hit) || 
          (state==3'd2 && !cross_line && icache_rvalid && icache_rlast) || 
          (state==3'd4 && cross_line && icache_rvalid && icache_rlast) ||
          (state==3'd2 && cross_line && hit1 && icache_rvalid && icache_rlast))
        ivalid <= 1'b1;
      // IFU接收数据后拉低
      else if(ifu_rready)
        ivalid <= 1'b0;
    end
  end
  assign icache_ivalid = ivalid;

  // ====================== 核心3：数据输出（解决跨块拼接） ======================
  // 同块：直接取连续8字节；跨块：拼接当前块最后4字节 + 下一块最先4字节
  wire [31:0] inst0 = cache_data[index0][offset0*8 +: 32]; // 第一条指令
  wire [31:0] inst1 = cross_line ? cache_data[index1][offset1*8 +: 32] : cache_data[index0][(offset0+4)*8 +: 32]; // 第二条指令
  assign icache_idata = {inst1, inst0}; // 64bit输出：{第二条指令，第一条指令}

endmodule