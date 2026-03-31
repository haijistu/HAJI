`include "defines.v"
module STORE_BUFFER (
  input clock,
  input reset,

  input                       store_valid,
  input [2:0]                 store_op,
  input [`PADDR_WIDTH-1:0]    store_addr,
  input [`WORD_WIDTH-1:0]     store_data,
  input [`ROB_ADDR_WIDTH-1:0] store_rob_idx,

  input                       retire_valid_0,
  input [`ROB_ADDR_WIDTH-1:0] retire_rob_idx_0,
  input                       retire_valid_1,
  input [`ROB_ADDR_WIDTH-1:0] retire_rob_idx_1,
  
  // AXI写事务
  output                      store_awvalid,
  input                       store_awready,
  output [`PADDR_WIDTH-1:0]   store_awaddr,
  output [7:0]                store_awlen,
  output [2:0]                store_awsize,
  output [3:0]                store_awid,
  output [1:0]                store_awburst,
  output                      store_wvalid,
  input                       store_wready,
  output [`WORD_WIDTH-1:0]    store_wdata,
  output [3:0]                store_wstrb,
  output                      store_wlast,
  input                       store_bvalid,
  output                      store_bready,
  input  [1:0]                store_bresp,
  input  [3:0]                store_bid
);
  
  reg [`ROB_ADDR_WIDTH-1:0] todo_list[0:15];
  reg [4:0] head, tail;
  reg [4:0] tail_next = tail + 1;
  wire empty = (head == tail);

  reg [`PADDR_WIDTH-1:0]    addr[0:`ROB_SIZE-1];
  reg [`WORD_WIDTH-1:0]     data[0:`ROB_SIZE-1];
  reg                       free[0:`ROB_SIZE-1];
  reg [2:0]                 op[0:`ROB_SIZE-1];
  always @(posedge clock) begin
    if(~reset) begin
      if(store_valid && free[store_rob_idx] == 1'b0) begin
        addr[store_rob_idx] <= store_addr;
        data[store_rob_idx] <= store_data;
        op[store_rob_idx] <= store_op;
      end
    end
  end

  reg [1:0] state;
  localparam S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;
  always @(posedge clock) begin
    if(reset) state <= S0;
    else begin
      case(state)
        S0: state <= (!empty)? S1 : S0;
        S1: state <= store_awready ? S2 : S1;
        S2: state <= store_wready ? S3 : S2;
        S3: state <= store_bvalid && (store_bid == 4'b0000) && (store_bresp == 2'b00) ? S0 : S3;
      endcase
    end
  end

  always @(posedge clock) begin
    if(reset) begin
      head <= 0;
      tail <= 0;
    end
    else begin
      if(retire_valid_0 && retire_valid_1) begin
        todo_list[tail[3:0]] <= retire_rob_idx_0;
        todo_list[tail_next[3:0]] <= retire_rob_idx_1;
        tail <= tail + 2;
      end
      else if(retire_valid_0) begin
        todo_list[tail[3:0]] <= retire_rob_idx_0;
        tail <= tail + 1;
      end
      else if(retire_valid_1) begin
        todo_list[tail[3:0]] <= retire_rob_idx_1;
        tail <= tail + 1;
      end

      if((state == S3) && store_bvalid && (store_bid == 4'b0000) && (store_bresp == 2'b00)) begin
        head <= head + 1;
      end
    end
  end
  
  wire [`ROB_ADDR_WIDTH-1:0] head_rob_idx = todo_list[head[3:0]];

  wire sb_inst = op[head_rob_idx][0];
  wire sh_inst = op[head_rob_idx][1];
  wire sw_inst = op[head_rob_idx][2];

  assign store_awvalid = (state == S1);
  assign store_awaddr = addr[head_rob_idx];
  assign store_awlen = 8'd0;
  assign store_awsize[0] = sh_inst;
  assign store_awsize[1] = sw_inst;
  assign store_awid = 4'b0000;
  assign store_awburst = 2'b01;

  // 先发送写地址，然后再传输写数据
  assign store_wvalid = (state == S2);
  assign store_wlast = (state == S2);
  assign store_wdata = sw_inst ? data[head_rob_idx] : sb_inst ? {4{data[head_rob_idx][7:0]}} : sh_inst ? {2{data[head_rob_idx][15:0]}} : 0;
  assign store_wstrb[3] = sw_inst | (sb_inst && addr[head_rob_idx][1:0] == 2'b11) | (sh_inst && addr[head_rob_idx][1:0] == 2'b10);
  assign store_wstrb[2] = sw_inst | (sb_inst && addr[head_rob_idx][1:0] == 2'b10) | (sh_inst && addr[head_rob_idx][1:0] == 2'b10);
  assign store_wstrb[1] = sw_inst | (sb_inst && addr[head_rob_idx][1:0] == 2'b01) | (sh_inst && addr[head_rob_idx][1:0] == 2'b00);
  assign store_wstrb[0] = sw_inst | (sb_inst && addr[head_rob_idx][1:0] == 2'b00) | (sh_inst && addr[head_rob_idx][1:0] == 2'b00);

  assign store_bready = (state == S2 || state == S3);

endmodule