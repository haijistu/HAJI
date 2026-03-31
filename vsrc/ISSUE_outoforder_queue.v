`include "defines.v"
module ISSUE_outoforder_queue (
  input clock,
  input reset,

  // dispatch
  input                         dispatch_valid_0,
  input [`OP_WIDTH-1:0]         dispatch_op_0,
  input [`WORD_WIDTH-1:0]       dispatch_imm_0,
  input                         dispatch_imm_valid_0,
  input [`PADDR_WIDTH-1:0]      dispatch_pc_0,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prs1_0,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prs2_0,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prd_0,
  input [`ROB_ADDR_WIDTH-1:0]   dispatch_rob_idx_0,

  input                         dispatch_valid_1,
  input [`OP_WIDTH-1:0]         dispatch_op_1,
  input [`WORD_WIDTH-1:0]       dispatch_imm_1,
  input                         dispatch_imm_valid_1,
  input [`PADDR_WIDTH-1:0]      dispatch_pc_1,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prs1_1,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prs2_1,
  input [`PREG_ADDR_WIDTH-1:0]  dispatch_prd_1,
  input [`ROB_ADDR_WIDTH-1:0]   dispatch_rob_idx_1,

  input                         dispatch_prs1_ready_0,
  input                         dispatch_prs2_ready_0,
  input                         dispatch_prs1_ready_1,
  input                         dispatch_prs2_ready_1,

  // issue
  output reg                        issue_valid,
  input                             fu_ready,
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

  // issue
  reg [`QUEUE_ADDR_WIDTH-1:0] issue_idx;

  // freelist
  wire [`QUEUE_ADDR_WIDTH-1:0] free_id_0;
  wire [`QUEUE_ADDR_WIDTH-1:0] free_id_1;
  freelist #(
    .DATA_WIDTH(`QUEUE_ADDR_WIDTH),
    .DATA_DEPTH(`QUEUE_SIZE)
  ) rename_freelist (
    .clock(clock),
    .reset(reset),
    .pop0_valid(dispatch_valid_0),
    .pop1_valid(dispatch_valid_1),
    .push0_valid(fu_ready),
    .push1_valid(),
    .push0(issue_idx),
    .push1(),
    .pop0(free_id_0),
    .pop1(free_id_1),
    .empty()
  );
  

  integer i;
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      for(i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        queue_free[i] <= 0;
      end
    end
    else begin
      if(dispatch_valid_0 && dispatch_valid_1) begin
        queue_free[free_id_0] <= 1'b1;
        queue_imm[free_id_0] <= dispatch_imm_0;
        queue_imm_valid[free_id_0] <= dispatch_imm_valid_0;
        queue_op[free_id_0] <= dispatch_op_0;
        queue_pc[free_id_0] <= dispatch_pc_0;
        queue_prs1[free_id_0] <= dispatch_prs1_0;
        queue_prs2[free_id_0] <= dispatch_prs2_0;
        queue_prd[free_id_0] <= dispatch_prd_0;
        queue_rob_idx[free_id_0] <= dispatch_rob_idx_0;

        queue_free[free_id_1] <= 1'b1;
        queue_imm[free_id_1] <= dispatch_imm_1;
        queue_imm_valid[free_id_1] <= dispatch_imm_valid_1;
        queue_op[free_id_1] <= dispatch_op_1;
        queue_pc[free_id_1] <= dispatch_pc_1;
        queue_prs1[free_id_1] <= dispatch_prs1_1;
        queue_prs2[free_id_1] <= dispatch_prs2_1;
        queue_prd[free_id_1] <= dispatch_prd_1;
        queue_rob_idx[free_id_1] <= dispatch_rob_idx_1;
      end
      else if(dispatch_valid_0) begin
        queue_free[free_id_0] <= 1'b1;
        queue_imm[free_id_0] <= dispatch_imm_0;
        queue_imm_valid[free_id_0] <= dispatch_imm_valid_0;
        queue_op[free_id_0] <= dispatch_op_0;
        queue_pc[free_id_0] <= dispatch_pc_0;
        queue_prs1[free_id_0] <= dispatch_prs1_0;
        queue_prs2[free_id_0] <= dispatch_prs2_0;
        queue_prd[free_id_0] <= dispatch_prd_0;
        queue_rob_idx[free_id_0] <= dispatch_rob_idx_0;
      end
      else if(dispatch_valid_1) begin
        queue_free[free_id_0] <= 1'b1;
        queue_imm[free_id_0] <= dispatch_imm_1;
        queue_imm_valid[free_id_0] <= dispatch_imm_valid_1;
        queue_op[free_id_0] <= dispatch_op_1;
        queue_pc[free_id_0] <= dispatch_pc_1;
        queue_prs1[free_id_0] <= dispatch_prs1_1;
        queue_prs2[free_id_0] <= dispatch_prs2_1;
        queue_prd[free_id_0] <= dispatch_prd_1;
        queue_rob_idx[free_id_0] <= dispatch_rob_idx_1;
      end

      // issue
      if(issue_valid) begin
        queue_free[issue_idx] <= 0;
      end
    end
  end
  
  // issue
  wire [`QUEUE_SIZE-1:0] ready_vec;
  generate
    for (genvar i = 0; i < `QUEUE_SIZE; i = i + 1) begin
      assign ready_vec[i] = queue_free[i] && queue_src1_ready[i] && queue_src2_ready[i];
    end
  endgenerate

  // wakeup
  always @(*) begin
    for(i = 0; i < `QUEUE_SIZE; i = i + 1) begin
      queue_src1_ready_next[i] = queue_src1_ready[i];
      queue_src2_ready_next[i] = queue_src2_ready[i];
    end
    if(dispatch_valid_0 && dispatch_valid_1) begin
      queue_src1_ready_next[free_id_0] = dispatch_prs1_ready_0;
      queue_src2_ready_next[free_id_0] = dispatch_prs2_ready_0;
      queue_src1_ready_next[free_id_1] = dispatch_prs1_ready_1;
      queue_src2_ready_next[free_id_1] = dispatch_prs2_ready_1;
    end
    else if(dispatch_valid_0) begin
      queue_src1_ready_next[free_id_0] = dispatch_prs1_ready_0;
      queue_src2_ready_next[free_id_0] = dispatch_prs2_ready_0;
    end
    else begin
      queue_src1_ready_next[free_id_0] = dispatch_prs1_ready_1;
      queue_src2_ready_next[free_id_0] = dispatch_prs2_ready_1;
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
    if(~reset) begin
      for(i = 0; i < `QUEUE_SIZE; i = i + 1) begin
        queue_src1_ready[i] <= queue_src1_ready_next[i];
        queue_src2_ready[i] <= queue_src2_ready_next[i];
      end
    end
  end

  // issue
  always @(*) begin
    issue_valid = 0;
    issue_idx = 0;
    for (int i = 0; i < `QUEUE_SIZE; i++) begin
      if (ready_vec[i] && !issue_valid) begin
        issue_valid = 1;
        issue_idx = i[`QUEUE_ADDR_WIDTH-1:0];
      end
    end
  end

  assign issue_op   = queue_op[issue_idx];
  assign issue_prs1 = queue_prs1[issue_idx];
  assign issue_prs2 = queue_prs2[issue_idx];
  assign issue_prd = queue_prd[issue_idx];
  assign issue_rob_idx = queue_rob_idx[issue_idx];
  assign issue_imm = queue_imm[issue_idx];
  assign issue_imm_valid = queue_imm_valid[issue_idx];
  assign issue_pc = queue_pc[issue_idx];

endmodule