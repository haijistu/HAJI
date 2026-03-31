`include "defines.v"
module RETIRE_top(
  input                                   clock,
  input                                   reset,
  
  // 与 ROB 的接口
  input      [`PREG_ADDR_WIDTH-1:0]       rob_nprd_0,      // ROB 中第一条指令的目标物理寄存器
  input      [`PREG_ADDR_WIDTH-1:0]       rob_nprd_1,      // ROB 中第二条指令的目标物理寄存器
  input      [`PREG_ADDR_WIDTH-1:0]       rob_oprd_0,      // ROB 中第一条指令的操作数物理寄存器
  input      [`PREG_ADDR_WIDTH-1:0]       rob_oprd_1,      // ROB 中第二条指令的操作数物理寄存器
  input      [`REG_ADDR_WIDTH-1:0]        rob_rd_0,        // ROB 中第一条指令的目标架构寄存器
  input      [`REG_ADDR_WIDTH-1:0]        rob_rd_1,        // ROB 中第二条指令的目标架构寄存器
  input                                   rob_complete_0,  // ROB 中第一条指令是否完成
  input                                   rob_complete_1,  // ROB 中第二条指令是否完成
  input                                   rob_empty,       // ROB 是否为空
  
  // 与 PRF 的接口
  input      [`WORD_WIDTH-1:0]            prf_data_0,      // 第一条指令的物理寄存器值
  input      [`WORD_WIDTH-1:0]            prf_data_1,      // 第二条指令的物理寄存器值
  
  // 与 RENAME 的接口
  output     [`REG_ADDR_WIDTH-1:0]        retire_rd_0,     // 退休的第一条指令的目标架构寄存器
  output     [`PREG_ADDR_WIDTH-1:0]       retire_prd_0,    // 退休的第一条指令的目标物理寄存器
  output                                  retire_valid_0,  // 第一条指令是否退休
  output     [`REG_ADDR_WIDTH-1:0]        retire_rd_1,     // 退休的第二条指令的目标架构寄存器
  output     [`PREG_ADDR_WIDTH-1:0]       retire_prd_1,    // 退休的第二条指令的目标物理寄存器
  output                                  retire_valid_1,  // 第二条指令是否退休
  
  // 与 ROB 的控制信号
  output                                  retire_rob_0,    // 退休 ROB 中的第一条指令
  output                                  retire_rob_1,    // 退休 ROB 中的第二条指令
  
  // 与 IFU 的接口（处理异常和跳转）
  output                                  retire_exception, // 是否发生异常
  output     [`WORD_WIDTH-1:0]            retire_pc        // 异常处理的 PC 值
);
  
  // 退休逻辑
  reg [`ROB_ADDR_WIDTH:0] rob_head;
  
  // 退休状态信号
  reg retire_valid_0_reg;
  reg retire_valid_1_reg;
  
  // 复位逻辑
  always @(posedge clock) begin
    if (reset) begin
      rob_head <= 0;
      retire_valid_0_reg <= 0;
      retire_valid_1_reg <= 0;
    end else begin
      // 默认情况下不退休
      retire_valid_0_reg <= 0;
      retire_valid_1_reg <= 0;
      
      // 检查 ROB 是否不为空且第一条指令已完成
      if (!rob_empty && rob_complete_0) begin
        // 退休第一条指令
        retire_valid_0_reg <= 1;
        
        // 检查是否可以退休第二条指令
        if (rob_complete_1) begin
          retire_valid_1_reg <= 1;
        end
      end
    end
  end
  
  // 输出赋值
  assign retire_rd_0 = rob_rd_0;
  assign retire_prd_0 = rob_nprd_0;
  assign retire_valid_0 = retire_valid_0_reg;
  
  assign retire_rd_1 = rob_rd_1;
  assign retire_prd_1 = rob_nprd_1;
  assign retire_valid_1 = retire_valid_1_reg;
  
  // 控制 ROB 指针
  assign retire_rob_0 = retire_valid_0_reg;
  assign retire_rob_1 = retire_valid_1_reg;
  
  // 异常处理（暂时简单实现）
  assign retire_exception = 0;
  assign retire_pc = 0;
  
endmodule

/*
退休单元与其他模块的交互说明：

1. 与 ROB（重排序缓冲区）的交互：
   - 输入：从 ROB 接收指令的物理寄存器信息、架构寄存器信息和完成状态
   - 输出：向 ROB 发送退休信号，指示哪些指令已完成退休

2. 与 PRF（物理寄存器文件）的交互：
   - 输入：从 PRF 接收物理寄存器的值，用于更新架构寄存器

3. 与 RENAME（重命名单元）的交互：
   - 输出：向 RENAME 发送退休的指令信息，用于更新 RAT（寄存器别名表）

4. 与 IFU（取指单元）的交互：
   - 输出：向 IFU 发送异常信号和异常处理的 PC 值

退休单元的主要功能：
- 按顺序从 ROB 中读取已完成的指令
- 每个时钟周期最多退休两条指令（双发射）
- 更新架构状态，确保程序的顺序执行语义
- 处理异常和中断

工作流程：
1. 检查 ROB 是否不为空且头部指令已完成
2. 如果第一条指令已完成，退休该指令
3. 如果第二条指令也已完成，同时退休该指令
4. 向相关模块发送退休信息，更新系统状态
*/