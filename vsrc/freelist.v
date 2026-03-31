`include "defines.v"
module freelist #(
  parameter DATA_WIDTH,
  parameter DATA_DEPTH
) (
  input clock,
  input reset,
  input pop0_valid, 
  input pop1_valid,
  input push0_valid,
  input push1_valid,
  input [DATA_WIDTH-1:0] push0,
  input [DATA_WIDTH-1:0] push1,
  output [DATA_WIDTH-1:0] pop0,
  output [DATA_WIDTH-1:0] pop1,
  output empty
);
  
  // 同步FIFO实现空闲寄存器列表
  reg [DATA_WIDTH-1:0] free_list [DATA_DEPTH-1:0]; // 空闲寄存器列表
  // 读写指针地址拓展，以实现判空
  reg [DATA_WIDTH:0] head; // 读指针
  reg [DATA_WIDTH:0] tail; // 写指针
  wire [DATA_WIDTH:0] head_next = head + 1;
  integer i;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      head <= 0;
      tail <= DATA_DEPTH-1; // 初始时写指针指向最后一个位置
      for (i = 0; i < DATA_DEPTH; i = i + 1) begin
        free_list[i] <= i[DATA_WIDTH-1:0]; // 初始时所有寄存器都空闲，编号为0到63
      end
    end else begin
      // 处理pop0和pop1操作
      if (pop0_valid && !empty) begin
        head <= head + 1; // pop0操作，读指针前移
      end
      if (pop1_valid && !empty) begin
        head <= head + 1; // pop1操作，读指针前移
      end
      if (push0_valid) begin
        tail <= tail + 1; // push0操作，写指针前移
      end
      if (push1_valid) begin
        tail <= tail + 1; // push1操作，写指针前移
      end
    end
  end
  assign pop0 = free_list[head[DATA_WIDTH-1:0]];
  assign pop1 = free_list[head_next[DATA_WIDTH-1:0]];
endmodule