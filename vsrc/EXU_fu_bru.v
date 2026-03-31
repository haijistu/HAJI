`include "defines.v"
module FU_bru (
  // 来自PRF的源操作数
  input [`WORD_WIDTH-1:0]           bru_psrc1,
  input [`WORD_WIDTH-1:0]           bru_psrc2,

  // 发射到执行单元的指令信息
  input                             bru_issue_valid,
  input [`OP_WIDTH-1:0]             bru_issue_op,
  input [`WORD_WIDTH-1:0]           bru_issue_imm,
  input [`PADDR_WIDTH-1:0]          bru_issue_pc,

  // 输出信号
  output [`PADDR_WIDTH-1:0]         jump_addr,
  output                            jump_flag,

  // 写回
  output [`WORD_WIDTH-1:0]          bru_wd
);

  // 内部信号定义
  wire [`WORD_WIDTH-1:0]  bru_src1;
  wire [`WORD_WIDTH-1:0]  bru_src2;
  wire                    branch_taken;
  wire [`PADDR_WIDTH-1:0] branch_target;
  wire [`PADDR_WIDTH-1:0] jal_target;
  wire [`PADDR_WIDTH-1:0] jalr_target;

  // 操作数选择
  assign bru_src1 = bru_psrc1;
  assign bru_src2 = bru_psrc2;

  // 计算分支目标地址
  assign branch_target = bru_issue_pc + bru_issue_imm;
  assign jal_target = bru_issue_pc + bru_issue_imm;
  assign jalr_target = bru_src1 + bru_issue_imm;

  // 分支条件判断
  assign branch_taken = (
    (bru_issue_op == `BRANCH_BEQ  && bru_src1 == bru_src2) ||
    (bru_issue_op == `BRANCH_BNE  && bru_src1 != bru_src2) ||
    (bru_issue_op == `BRANCH_BLT  && $signed(bru_src1) < $signed(bru_src2)) ||
    (bru_issue_op == `BRANCH_BGE  && $signed(bru_src1) >= $signed(bru_src2)) ||
    (bru_issue_op == `BRANCH_BLTU && bru_src1 < bru_src2) ||
    (bru_issue_op == `BRANCH_BGEU && bru_src1 >= bru_src2) ||
    (bru_issue_op == `JUMP_JAL) ||
    (bru_issue_op == `JUMP_JALR)
  );

  // 计算跳转地址
  assign jump_addr = (bru_issue_op == `JUMP_JAL) ? jal_target : (bru_issue_op == `JUMP_JALR) ? jalr_target : branch_target;  

  // 跳转标志
  assign jump_flag = branch_taken;

endmodule
