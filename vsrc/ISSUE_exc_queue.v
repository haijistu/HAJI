`include "defines.v"
module ISSUE_exc_queue (
  input clock,
  input reset,
  
  // dispatch
  input                         dispatch_valid_0,
  input [`OP_WIDTH-1:0]         dispatch_op_0,
  input [`PADDR_WIDTH-1:0]      dispatch_pc_0,
  input [`ROB_ADDR_WIDTH-1:0]   dispatch_rob_idx_0,

  input                         dispatch_valid_1,
  input [`OP_WIDTH-1:0]         dispatch_op_1,
  input [`PADDR_WIDTH-1:0]      dispatch_pc_1,
  input [`ROB_ADDR_WIDTH-1:0]   dispatch_rob_idx_1,

  // issue
  output                        issue_valid,
  output [`OP_WIDTH-1:0]        issue_op,
  output [`PADDR_WIDTH-1:0]     issue_pc,
  output [`ROB_ADDR_WIDTH-1:0]  issue_rob_idx,

  input                         retire_csr_valid_0,
  input [`CSR_ADDR_WIDTH-1:0]   retire_csr_addr_0,
  input                         retire_csr_valid_1,
  input [`CSR_ADDR_WIDTH-1:0]   retire_csr_addr_1,

  input                          mtvec_ready,
  input                          mepc_ready,

  // stall
  output                            queue_full
);
  
  reg                         queue_free [0:`QUEUE_SIZE-1]; // 0为空闲 1为非空闲
  reg [`OP_WIDTH-1:0]         queue_op [0:`QUEUE_SIZE-1];
  reg [`WORD_WIDTH-1:0]       queue_pc [0:`QUEUE_SIZE-1];
  reg [`ROB_ADDR_WIDTH-1:0]   queue_rob_idx [0:`QUEUE_SIZE-1];
  reg                         queue_ready [0:`QUEUE_SIZE-1];
  reg                         queue_ready_next [0:`QUEUE_SIZE-1];
  reg  [`QUEUE_ADDR_WIDTH:0]  head, tail;
  wire [`QUEUE_ADDR_WIDTH:0]  tail_next = tail + 1;

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
        queue_op[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_op_0;
        queue_pc[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_pc_0;
        queue_rob_idx[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_rob_idx_0;

        queue_free[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= 1'b1;
        queue_op[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_op_1;
        queue_pc[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_pc_1;
        queue_rob_idx[tail_next[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_rob_idx_1;
        
        tail <= tail + 2;
      end
      else if(dispatch_valid_0) begin
        queue_free[tail[`QUEUE_ADDR_WIDTH-1:0]] <= 1'b1;
        queue_op[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_op_0;
        queue_pc[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_pc_0;
        queue_rob_idx[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_rob_idx_0;
        
        tail <= tail + 1;
      end
      else if(dispatch_valid_1) begin
        queue_free[tail[`QUEUE_ADDR_WIDTH-1:0]] <= 1'b1;
        queue_op[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_op_1;
        queue_pc[tail[`QUEUE_ADDR_WIDTH-1:0]] <= dispatch_pc_1;
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

  wire dispatch_ready_0 = ((dispatch_op_0 == `EXCEPTION_ECALL) && (mtvec_ready)) || ((dispatch_op_0 == `EXCEPTION_MRET) && (mepc_ready));
  wire dispatch_ready_1 = ((dispatch_op_1 == `EXCEPTION_ECALL) && (mtvec_ready)) || ((dispatch_op_1 == `EXCEPTION_MRET) && (mepc_ready));

  always @(*) begin
    for (i = 0; i < `QUEUE_SIZE; i = i + 1) begin
      queue_ready_next[i] = queue_ready[i];
    end
    if(dispatch_valid_0) queue_ready_next[tail[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_ready_0;
    if(dispatch_valid_1) queue_ready_next[tail[`QUEUE_ADDR_WIDTH-1:0]] = dispatch_ready_1;
    if(retire_csr_valid_0) begin
      for (i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        if (queue_free[i]) begin
          if ((queue_op[i] == `EXCEPTION_ECALL && retire_csr_addr_0 == `CSR_MTVEC) || (queue_op[i] == `EXCEPTION_MRET && retire_csr_addr_0 == `CSR_MEPC)) queue_ready_next[i] = 1;
        end
      end
    end
    if(retire_csr_valid_1) begin
      for (i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        if (queue_free[i]) begin
          if ((queue_op[i] == `EXCEPTION_ECALL && retire_csr_addr_1 == `CSR_MTVEC) || (queue_op[i] == `EXCEPTION_MRET && retire_csr_addr_1 == `CSR_MEPC)) queue_ready_next[i] = 1;
        end
      end
    end
  end

  always @(posedge clock) begin
    if(reset) begin
      for(i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        queue_ready[i] <= 0;
      end
    end
    else begin
      for(i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        queue_ready[i] <= queue_ready_next[i];
      end
    end
  end

  assign issue_valid = queue_free[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_pc = queue_pc[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_rob_idx = queue_rob_idx[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign issue_op = queue_op[head[`QUEUE_ADDR_WIDTH-1:0]];
  assign queue_full = (tail[`ROB_ADDR_WIDTH-1:0] == head[`ROB_ADDR_WIDTH-1:0]) && (tail[`ROB_ADDR_WIDTH] ^ head[`ROB_ADDR_WIDTH]);
endmodule