`include "defines.v"
module ROB (
  input      clock,
  input      reset,
  // 来自 IDU 的指令信息(dispatch)
  input                             idu_valid_0,
  input      [`WORD_WIDTH-1:0]      idu_inst_0,
  input      [`REG_ADDR_WIDTH-1:0]  idu_rd_0,
  input                             idu_rd_0_valid,
  input      [`FU_TYPE_WIDTH-1:0]   idu_fu_type_0,
  input      [`PADDR_WIDTH-1:0]     idu_pc_0,
  input      [`PREG_ADDR_WIDTH-1:0] idu_preg_0,
  input      [`PREG_ADDR_WIDTH-1:0] idu_opreg_0,

  input                             idu_valid_1,
  input      [`WORD_WIDTH-1:0]      idu_inst_1,
  input      [`REG_ADDR_WIDTH-1:0]  idu_rd_1,
  input                             idu_rd_1_valid,
  input      [`FU_TYPE_WIDTH-1:0]   idu_fu_type_1,
  input      [`PADDR_WIDTH-1:0]     idu_pc_1,
  input      [`PREG_ADDR_WIDTH-1:0] idu_preg_1,
  input      [`PREG_ADDR_WIDTH-1:0] idu_opreg_1,

  // 分发的rob idx
  output     [`ROB_ADDR_WIDTH-1:0]  rob_idx_0,
  output     [`ROB_ADDR_WIDTH-1:0]  rob_idx_1,

  // wb
  input                       wb_rob_valid_0,
  input [`ROB_ADDR_WIDTH-1:0] wb_rob_idx_0,
  input [`WORD_WIDTH-1:0]     wb_rob_wd_0,
  input                       wb_rob_valid_1,
  input [`ROB_ADDR_WIDTH-1:0] wb_rob_idx_1,
  input [`WORD_WIDTH-1:0]     wb_rob_wd_1,
  input                       wb_rob_valid_2,
  input [`ROB_ADDR_WIDTH-1:0] wb_rob_idx_2,
  input [`WORD_WIDTH-1:0]     wb_rob_wd_2,
  input [`PADDR_WIDTH-1:0]    wb_rob_jump_addr,
  input                       wb_rob_jump_flag,
  
  // retire - rename
  output reg                    retire_valid_0,
  output reg                    retire_valid_1,
  output                        retire_store_valid_0,
  output                        retire_store_valid_1,
  output                        retire_rd_valid_0,
  output                        retire_rd_valid_1,
  output [`REG_ADDR_WIDTH-1:0]  retire_areg_0,
  output [`REG_ADDR_WIDTH-1:0]  retire_areg_1,
  output [`PREG_ADDR_WIDTH-1:0] retire_opreg_0,
  output [`PREG_ADDR_WIDTH-1:0] retire_opreg_1,
  output [`PREG_ADDR_WIDTH-1:0] retire_preg_0,
  output [`PREG_ADDR_WIDTH-1:0] retire_preg_1,
  output [`ROB_ADDR_WIDTH-1:0]  retire_rob_idx_0,
  output [`ROB_ADDR_WIDTH-1:0]  retire_rob_idx_1,
  // retire - prf
  output [`WORD_WIDTH-1:0]      retire_wd_0,
  output [`WORD_WIDTH-1:0]      retire_wd_1,
  output [`PREG_ADDR_WIDTH-1:0] retire_wa_0,
  output [`PREG_ADDR_WIDTH-1:0] retire_wa_1,

  // retire - bru
  // 只会退休一条分支指令，不会退休后面满足条件的指令
  output                          retire_bru_valid,
  output [`PADDR_WIDTH-1:0]       retire_bru_addr,
  output                          retire_bru_flag,
  output [`PADDR_WIDTH-1:0]       retire_bru_pc,

  output                          retire_store_finish,
  output [`ROB_ADDR_WIDTH-1:0]    retire_store_rob_idx,

  // stall
  output                          rob_full

);

  // 基于FIFO实现的ROB
  reg  [`FU_TYPE_WIDTH-1:0]   rob_fu_type   [0:`ROB_SIZE-1];
  reg  [`REG_ADDR_WIDTH-1:0]  rob_areg      [0:`ROB_SIZE-1];
  reg  [`PREG_ADDR_WIDTH-1:0] rob_preg      [0:`ROB_SIZE-1];
  reg  [`PREG_ADDR_WIDTH-1:0] rob_opreg     [0:`ROB_SIZE-1];
  reg  [`PADDR_WIDTH-1:0]     rob_pc        [0:`ROB_SIZE-1];
  reg                         rob_complete  [0:`ROB_SIZE-1];
  reg                         rob_rd_valid  [0:`ROB_SIZE-1];
  reg  [`PADDR_WIDTH-1:0]     rob_jump_addr [0:`ROB_SIZE-1];
  reg                         rob_jump_flag [0:`ROB_SIZE-1];
  reg  [`WORD_WIDTH-1:0]      rob_wd        [0:`ROB_SIZE-1];
  reg  [`WORD_WIDTH-1:0]      rob_inst      [0:`ROB_SIZE-1];
  reg  [`ROB_ADDR_WIDTH:0]    head, tail;
  wire [`ROB_ADDR_WIDTH:0]    tail_next = tail + 1;
  wire [`ROB_ADDR_WIDTH:0]    head_next = head + 1;
  // Dispatch 阶段：将 RENAME 的指令信息写入 ROB
  integer i;
  always @(posedge clock) begin
    if (reset) begin
      tail <= 0;
      for (i = 0; i < `ROB_SIZE; i++) begin
        rob_complete[i] <= 0;
      end
    end else begin
      if (idu_valid_0 && idu_valid_1) begin
        rob_fu_type[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_fu_type_0;
        rob_areg[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_rd_0;
        rob_preg[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_preg_0;
        rob_opreg[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_opreg_0;
        rob_pc[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_pc_0;
        rob_rd_valid[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_rd_0_valid;
        rob_inst[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_inst_0;
        rob_complete[tail[`ROB_ADDR_WIDTH-1:0]] <= 0;

        rob_fu_type[tail_next[`ROB_ADDR_WIDTH-1:0]] <= idu_fu_type_1;
        rob_areg[tail_next[`ROB_ADDR_WIDTH-1:0]] <= idu_rd_1;
        rob_preg[tail_next[`ROB_ADDR_WIDTH-1:0]] <= idu_preg_1;
        rob_opreg[tail_next[`ROB_ADDR_WIDTH-1:0]] <= idu_opreg_1;
        rob_pc[tail_next[`ROB_ADDR_WIDTH-1:0]] <= idu_pc_1;
        rob_rd_valid[tail_next[`ROB_ADDR_WIDTH-1:0]] <= idu_rd_1_valid;
        rob_inst[tail_next[`ROB_ADDR_WIDTH-1:0]] <= idu_inst_1;
        rob_complete[tail_next[`ROB_ADDR_WIDTH-1:0]] <= 0;
        tail <= tail + 2;
      end
      else if (idu_valid_0) begin
        rob_fu_type[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_fu_type_0;
        rob_areg[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_rd_0;
        rob_preg[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_preg_0;
        rob_opreg[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_opreg_0;
        rob_pc[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_pc_0;
        rob_rd_valid[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_rd_0_valid;
        rob_inst[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_inst_0;
        rob_complete[tail[`ROB_ADDR_WIDTH-1:0]] <= 0;
        tail <= tail + 1;
      end
      else if (idu_valid_1) begin
        rob_fu_type[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_fu_type_1;
        rob_areg[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_rd_1;
        rob_preg[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_preg_1;
        rob_opreg[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_opreg_1;
        rob_pc[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_pc_1;
        rob_rd_valid[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_rd_1_valid;
        rob_inst[tail[`ROB_ADDR_WIDTH-1:0]] <= idu_inst_1;
        rob_complete[tail[`ROB_ADDR_WIDTH-1:0]] <= 0;
        tail <= tail + 1;
      end
    end
  end
  assign rob_idx_0 = tail[`ROB_ADDR_WIDTH-1:0];
  assign rob_idx_1 = idu_valid_0 ? tail_next[`ROB_ADDR_WIDTH-1:0] : tail[`ROB_ADDR_WIDTH-1:0];

  // Commit 阶段
  always @(posedge clock) begin
    if(~reset) begin
      if(wb_rob_valid_0) begin
        rob_complete[wb_rob_idx_0] <= 1'b1;
        rob_wd[wb_rob_idx_0] <= wb_rob_wd_0;
      end
      if(wb_rob_valid_1) begin
        rob_complete[wb_rob_idx_1] <= 1'b1;
        rob_wd[wb_rob_idx_1] <= wb_rob_wd_1;
      end
      if(wb_rob_valid_2) begin
        rob_complete[wb_rob_idx_2] <= 1'b1;
        rob_wd[wb_rob_idx_2] <= wb_rob_wd_2;
        rob_jump_addr[wb_rob_idx_2] <= wb_rob_jump_addr;
        rob_jump_flag[wb_rob_idx_2] <= wb_rob_jump_flag;
      end
      if(retire_valid_0) begin
        rob_complete[head[`ROB_ADDR_WIDTH-1:0]] <= 1'b0;
      end
      if(retire_valid_1) begin
        rob_complete[head_next[`ROB_ADDR_WIDTH-1:0]] <= 1'b0;
      end
    end
  end

  always @(posedge clock) begin
    if(reset) begin
      head <= 0;
    end
    else begin
      if(retire_valid_0 && retire_valid_1) begin
        head <= head + 2;
      end 
      else if(retire_valid_0) begin
        head <= head + 1;
      end
    end
  end

  assign retire_store_valid_0 = rob_complete[head[`ROB_ADDR_WIDTH-1:0]] && (rob_fu_type[head[`ROB_ADDR_WIDTH-1:0]] == `FU_STORE);
  assign retire_store_valid_1 = rob_complete[head[`ROB_ADDR_WIDTH-1:0]] & rob_complete[head_next[`ROB_ADDR_WIDTH-1:0]] && (rob_fu_type[head_next[`ROB_ADDR_WIDTH-1:0]] == `FU_STORE);
  assign retire_rd_valid_0 = rob_rd_valid[head[`ROB_ADDR_WIDTH-1:0]];
  assign retire_rd_valid_1 = rob_rd_valid[head_next[`ROB_ADDR_WIDTH-1:0]];
  assign retire_opreg_0 = rob_opreg[head[`ROB_ADDR_WIDTH-1:0]];
  assign retire_opreg_1 = rob_opreg[head_next[`ROB_ADDR_WIDTH-1:0]];
  assign retire_wa_0 = rob_preg[head[`ROB_ADDR_WIDTH-1:0]];
  assign retire_wa_1 = rob_preg[head_next[`ROB_ADDR_WIDTH-1:0]];
  assign retire_wd_0 = rob_wd[head[`ROB_ADDR_WIDTH-1:0]];
  assign retire_wd_1 = rob_wd[head_next[`ROB_ADDR_WIDTH-1:0]];
  assign retire_areg_0 = rob_areg[head[`ROB_ADDR_WIDTH-1:0]];
  assign retire_areg_1 = rob_areg[head_next[`ROB_ADDR_WIDTH-1:0]];
  assign retire_rob_idx_0 = head[`ROB_ADDR_WIDTH-1:0];
  assign retire_rob_idx_1 = head_next[`ROB_ADDR_WIDTH-1:0];
  assign retire_preg_0 = rob_preg[head[`ROB_ADDR_WIDTH-1:0]];
  assign retire_preg_1 = rob_preg[head_next[`ROB_ADDR_WIDTH-1:0]];

  // retire - complete
  wire head_complete = rob_complete[head[`ROB_ADDR_WIDTH-1:0]];
  wire head_next_complete = rob_complete[head[`ROB_ADDR_WIDTH-1:0]] & rob_complete[head_next[`ROB_ADDR_WIDTH-1:0]];
  // bru
  wire head_bru = (rob_fu_type[head[`ROB_ADDR_WIDTH-1:0]] == `FU_BRU) || (rob_fu_type[head[`ROB_ADDR_WIDTH-1:0]] == `FU_JUMP);
  wire head_next_bru = (rob_fu_type[head_next[`ROB_ADDR_WIDTH-1:0]] == `FU_BRU)|| (rob_fu_type[head_next[`ROB_ADDR_WIDTH-1:0]] == `FU_JUMP);
  assign retire_bru_valid = rob_complete[head[`ROB_ADDR_WIDTH-1:0]] & head_bru;
  assign retire_bru_addr = rob_jump_addr[head[`ROB_ADDR_WIDTH-1:0]];
  assign retire_bru_flag = rob_jump_flag[head[`ROB_ADDR_WIDTH-1:0]];
  assign retire_bru_pc = rob_pc[head[`ROB_ADDR_WIDTH-1:0]];

  // store
  wire head_store = (rob_fu_type[head[`ROB_ADDR_WIDTH-1:0]] == `FU_STORE);
  wire head_next_store = (rob_fu_type[head_next[`ROB_ADDR_WIDTH-1:0]] == `FU_STORE);
  wire head_store_hit = head[`ROB_ADDR_WIDTH-1:0] == retire_store_rob_idx;
  wire head_next_store_hit = head_next[`ROB_ADDR_WIDTH-1:0] == retire_store_rob_idx;

  reg [`PADDR_WIDTH-1:0] retire_pc_0 = 0;
  reg [`PADDR_WIDTH-1:0] retire_pc_1 = 0;
  reg [`WORD_WIDTH-1:0]  retire_inst_0 = 0;
  reg [`WORD_WIDTH-1:0]  retire_inst_1 = 0;
  
  always @(*) begin
    retire_valid_0 = head_store ? (head_complete & retire_store_finish & head_store_hit) : head_complete;
    retire_valid_1 = head_next_store ? (head_next_complete & retire_store_finish & head_next_store_hit) : ~head_bru & ~head_next_bru & head_next_complete & retire_valid_0;
    retire_pc_0 = rob_pc[head[`ROB_ADDR_WIDTH-1:0]];
    retire_pc_1 = rob_pc[head_next[`ROB_ADDR_WIDTH-1:0]];
    retire_inst_0 = rob_inst[head[`ROB_ADDR_WIDTH-1:0]];
    retire_inst_1 = rob_inst[head_next[`ROB_ADDR_WIDTH-1:0]];
  end
  
  assign rob_full = ((tail[`ROB_ADDR_WIDTH-1:0] == head[`ROB_ADDR_WIDTH-1:0]) && (tail[`ROB_ADDR_WIDTH] ^ head[`ROB_ADDR_WIDTH])) || ((tail_next[`ROB_ADDR_WIDTH-1:0] == head[`ROB_ADDR_WIDTH-1:0]) && (tail_next[`ROB_ADDR_WIDTH] ^ head[`ROB_ADDR_WIDTH]));

  reg [`PADDR_WIDTH-1:0] apc;
  always @(posedge clock) begin
    if(reset) apc <= `INIT_PC;
    else if(retire_bru_valid) begin
      apc <= retire_bru_flag ? retire_bru_addr : retire_bru_pc + 32'd4;
    end
    else if(retire_valid_0 && retire_valid_1) begin
      apc <= retire_pc_1 + 32'd4;
    end
    else if(retire_valid_0) begin
      apc <= retire_pc_0 + 32'd4;
    end
  end
endmodule