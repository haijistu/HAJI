`include "defines.v"
module ISSUE_inorder_queue (
  input clock,
  input reset,

  // dispatch
  input                         dispatch_valid_0,
  input [`OP_WIDTH-1:0]         dispatch_op_0,
  input [`WORD_WIDTH-1:0]       dispatch_imm_0,
  input                         dispatch_imm_valid_0,
  input [`PADDR_WIDTH-1:0]      dispatch_pc_0,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prs1_0,
  input                         dispatch_prs1_valid_0,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prs2_0,
  input                         dispatch_prs2_valid_0,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prd_0,
  input [`ROB_ADDR_WIDTH-1:0]   dispatch_rob_idx_0,

  input                         dispatch_valid_1,
  input [`OP_WIDTH-1:0]         dispatch_op_1,
  input [`WORD_WIDTH-1:0]       dispatch_imm_1,
  input                         dispatch_imm_valid_1,
  input [`PADDR_WIDTH-1:0]      dispatch_pc_1,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prs1_1,
  input                         dispatch_prs1_valid_1,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prs2_1,
  input                         dispatch_prs2_valid_1,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prd_1,
  input [`ROB_ADDR_WIDTH-1:0]   dispatch_rob_idx_1,
  
  input                         dispatch_prs1_ready_0,
  input                         dispatch_prs2_ready_0,
  input                         dispatch_prs1_ready_1,
  input                         dispatch_prs2_ready_1,

  // issue
  output                        issue_valid,
  output [`OP_WIDTH-1:0]        issue_op,
  output [`WORD_WIDTH-1:0]      issue_imm,
  output                        issue_imm_valid,
  output [`PADDR_WIDTH-1:0]     issue_pc,
  output [`PREG_ADDR_WIDTH-1:0] issue_prs1,
  output [`PREG_ADDR_WIDTH-1:0] issue_prs2,
  output [`PREG_ADDR_WIDTH-1:0] issue_prd,
  output [`ROB_ADDR_WIDTH-1:0]  issue_rob_idx,
  
  // wakeup
  input                             retire_valid_0,
  input [`PREG_ADDR_WIDTH-1:0]      retire_prd_0,
  input                             retire_valid_1,
  input [`PREG_ADDR_WIDTH-1:0]      retire_prd_1
);
  reg                         queue_free [0:`QUEUE_SIZE-1]; // 0为空闲 1为非空闲
  reg [`OP_WIDTH-1:0]         queue_op [0:`QUEUE_SIZE-1];
  reg [`WORD_WIDTH-1:0]       queue_imm [0:`QUEUE_SIZE-1];
  reg [`WORD_WIDTH-1:0]       queue_pc [0:`QUEUE_SIZE-1];
  reg [`PREG_ADDR_WIDTH-1:0]  queue_prs1 [0:`QUEUE_SIZE-1];
  reg [`PREG_ADDR_WIDTH-1:0]  queue_prs2 [0:`QUEUE_SIZE-1];
  reg [`PREG_ADDR_WIDTH-1:0]  queue_prd [0:`QUEUE_SIZE-1];
  reg [`ROB_ADDR_WIDTH-1:0]   queue_rob_idx [0:`QUEUE_SIZE-1];
  reg                         queue_src1_ready [0:`QUEUE_SIZE-1];
  reg                         queue_src2_ready [0:`QUEUE_SIZE-1];
  reg                         queue_src1_ready_next [0:`QUEUE_SIZE-1];
  reg                         queue_src2_ready_next [0:`QUEUE_SIZE-1];
  reg                         queue_imm_valid [0:`QUEUE_SIZE-1];
  reg  [`QUEUE_ADDR_WIDTH:0] head, tail;
  wire [`QUEUE_ADDR_WIDTH:0] tail_next = tail + 1;
  
  wire head_valid = queue_free[head[`QUEUE_ADDR_WIDTH-1:0]];
  wire head_ready = queue_src1_ready[head[`QUEUE_ADDR_WIDTH-1:0]];

  integer i;
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      for(i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        queue_free[i] <= 0;
      end
      head <= 0;
      tail <= 0;
    end
    else begin
      // dispatch
      if(dispatch_valid_0 && dispatch_valid_1) begin
        queue_free[tail[`QUEUE_ADDR_WIDTH-1:0]] <= 1'b1;
        queue_imm[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_imm_0;
        queue_imm_valid[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_imm_valid_0;
        queue_op[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_op_0;
        queue_pc[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_pc_0;
        queue_prs1[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prs1_0;
        queue_prs2[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prs2_0;
        queue_prd[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prd_0;
        queue_rob_idx[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_rob_idx_0;

        queue_free[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= 1'b1;
        queue_imm[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_imm_1;
        queue_imm_valid[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_imm_valid_1;
        queue_op[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_op_1;
        queue_pc[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_pc_1;
        queue_prs1[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prs1_1;
        queue_prs2[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prs2_1;
        queue_prd[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prd_1;
        queue_rob_idx[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_rob_idx_1;
        
        tail <= tail + 2;
      end
      else if(dispatch_valid_0) begin
        queue_free[tail[`QUEUE_ADDR_WIDTH-1:0]] <= 1'b1;
        queue_imm[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_imm_0;
        queue_imm_valid[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_imm_valid_0;
        queue_op[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_op_0;
        queue_pc[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_pc_0;
        queue_prs1[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prs1_0;
        queue_prs2[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prs2_0;
        queue_prd[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prd_0;
        queue_rob_idx[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_rob_idx_0;
        
        tail <= tail + 1;
      end
      else if(dispatch_valid_1) begin
        queue_free[tail[`QUEUE_ADDR_WIDTH-1:0]] <= 1'b1;
        queue_imm[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_imm_1;
        queue_imm_valid[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_imm_valid_1;
        queue_op[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_op_1;
        queue_pc[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_pc_1;
        queue_prs1[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prs1_1;
        queue_prs2[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prs2_1;
        queue_prd[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_prd_1;
        queue_rob_idx[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_rob_idx_1;
        
        tail <= tail + 1;
      end

      // issue
      if(issue_valid) begin
        queue_free[head[`QUEUE_ADDR_WIDTH-1:0]] <= 0;
        head <= head + 1;
      end
    end
  end

  always @(*) begin
    for(i = 0; i < `QUEUE_SIZE; i = i + 1) begin
      queue_src1_ready_next[i] = queue_src1_ready[i];
      queue_src2_ready_next[i] = queue_src2_ready[i];
    end
    if(dispatch_valid_0 && dispatch_valid_1) begin
      queue_src1_ready_next[tail[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_prs1_valid_0 ? dispatch_prs1_ready_0 : 1'b1;
      queue_src2_ready_next[tail[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_prs2_valid_0 ? dispatch_prs2_ready_0 : 1'b1;
      queue_src1_ready_next[tail_next[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_prs1_valid_1 ? dispatch_prs1_ready_1 : 1'b1;
      queue_src2_ready_next[tail_next[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_prs2_valid_1 ? dispatch_prs2_ready_1 : 1'b1;
    end
    else if(dispatch_valid_0) begin
      queue_src1_ready_next[tail[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_prs1_valid_0 ? dispatch_prs1_ready_0 : 1'b1;
      queue_src2_ready_next[tail[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_prs2_valid_0 ? dispatch_prs2_ready_0 : 1'b1;
    end
    else begin
      queue_src1_ready_next[tail[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_prs1_valid_1 ? dispatch_prs1_ready_1 : 1'b1;
      queue_src2_ready_next[tail[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_prs2_valid_1 ? dispatch_prs2_ready_1 : 1'b1;
    end
    if(retire_valid_0) begin
      for (i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        if (queue_free[i]) begin
          if (queue_prs1[i] == retire_prd_0) queue_src1_ready_next[i] = 1;
          if (queue_prs2[i] == retire_prd_0) queue_src2_ready_next[i] = 1;
        end
      end
    end
    if(retire_valid_1) begin
      for (i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        if (queue_free[i]) begin
          if (queue_prs1[i] == retire_prd_1) queue_src1_ready_next[i] = 1;
          if (queue_prs2[i] == retire_prd_1) queue_src2_ready_next[i] = 1;
        end
      end
    end
  end

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      for(i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        queue_src1_ready[i] <= 0;
        queue_src2_ready[i] <= 0;
      end
    end
    else begin
      for(i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        queue_src1_ready[i] <= queue_src1_ready_next[i];
        queue_src2_ready[i] <= queue_src2_ready_next[i];
      end
    end
  end
  
  assign issue_valid = head_valid && head_ready;
  assign issue_imm = queue_imm[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_imm_valid = queue_imm_valid[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_op = queue_op[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_pc = queue_pc[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_prd = queue_prd[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_rob_idx = queue_rob_idx[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_prs1 = queue_prs1[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_prs2 = queue_prs2[head[`QUEUE_ADDR_WIDTH-1:0]];
endmodule