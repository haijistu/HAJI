`include "defines.v"
module RENAME_freelist #(
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
  reg [DATA_WIDTH-1:0] free_list [DATA_DEPTH-1:0];
  reg [DATA_WIDTH:0] head; // 读指针
  reg [DATA_WIDTH:0] tail; // 写指针
  wire [DATA_WIDTH:0] head_next = head + 1;
  wire [DATA_WIDTH:0] tail_next = tail + 1;
  
  // 判断空闲列表是否为空
  assign empty = (head == tail);
  
  integer i;
  
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      head <= 1;
      tail <= 0; 
      for (i = 0; i < DATA_DEPTH; i = i + 1) begin
        free_list[i] <= i[DATA_WIDTH-1:0]; // 初始时所有寄存器都空闲，编号为0到63
      end
    end else begin
      // 处理pop操作（分配物理寄存器）
      if(!empty) begin
        // 两个同时pop，且空闲列表有足够空间
        if (pop0_valid && pop1_valid) begin
          head <= head + 2;
        end
        // 单个pop
        else if (pop0_valid) begin
          head <= head + 1;
        end
        else if (pop1_valid) begin
          head <= head + 1;
        end
      end
      
      // 处理push操作（回收物理寄存器）
      // 确保不会将物理寄存器0推入freelist
      if (push0_valid && push0 != 0 && push1_valid && push1 != 0) begin
        free_list[tail[DATA_WIDTH-1:0]] <= push0;
        free_list[tail_next[DATA_WIDTH-1:0]] <= push1;
        tail <= tail + 2;
      end
      else if (push0_valid && (push0 != 0)) begin
        free_list[tail[DATA_WIDTH-1:0]] <= push0;
        tail <= tail + 1;
      end
      else if (push1_valid && (push1 != 0)) begin
        free_list[tail[DATA_WIDTH-1:0]] <= push1;
        tail <= tail + 1;
      end
    end
  end
  
  // 分配物理寄存器
  assign pop0 = free_list[head[DATA_WIDTH-1:0]];
  assign pop1 = pop0_valid ? free_list[head_next[DATA_WIDTH-1:0]] : free_list[head[DATA_WIDTH-1:0]];
  
endmodule