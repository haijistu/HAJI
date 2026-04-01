`include "defines.v"
module IDU_decode (
  input      [`PADDR_WIDTH-1:0]     pc,
  input      [`WORD_WIDTH-1:0 ]     inst,

  output     [`REG_ADDR_WIDTH-1:0]  rs1,
  output                            rs1_valid,
  output     [`REG_ADDR_WIDTH-1:0]  rs2,
  output                            rs2_valid, // rs2是否有效
  output     [`REG_ADDR_WIDTH-1:0]  rd,
  output                            rd_valid, // rd是否有效
  output     [`WORD_WIDTH-1:0]      imm,
  output                            imm_valid, // imm是否有效
  output     [`OP_WIDTH-1:0]        op,
  output     [`FU_TYPE_WIDTH-1:0]   fu_type
);
  wire [6:0] funct7 = inst[31:25];
  wire [2:0] funct3 = inst[14:12];
  wire [6:0] opcode = inst[6:0];

  // S
  wire sw_inst   = ~funct3[2]& funct3[1]&~funct3[0]&~opcode[6]& opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire sb_inst   = ~funct3[2]&~funct3[1]&~funct3[0]&~opcode[6]& opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire sh_inst   = ~funct3[2]&~funct3[1]& funct3[0]&~opcode[6]& opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  // J
  wire jal_inst  =  opcode[6]& opcode[5]&~opcode[4]& opcode[3]& opcode[2] & opcode[1]& opcode[0];
  // R
  wire add_inst  = ~(|funct7)&~funct3[2]&~funct3[1]&~funct3[0]&~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire and_inst  = ~(|funct7)& funct3[2]& funct3[1]& funct3[0]&~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire sltu_inst = ~(|funct7)&~funct3[2]& funct3[1] & funct3[0] & ~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire slt_inst  = ~(|funct7)&~funct3[2]& funct3[1] &~funct3[0] & ~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire xor_inst  = ~(|funct7)& funct3[2]&~funct3[1] &~funct3[0] & ~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire or_inst   = ~(|funct7)& funct3[2]& funct3[1] &~funct3[0] & ~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire sub_inst  = funct7[5]&~(|{funct7[6], funct7[4:0]})&~funct3[2]&~funct3[1]&~funct3[0]&~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire sll_inst   = ~(|funct7)&~funct3[2]&~funct3[1] & funct3[0] & ~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire sra_inst   = funct7[5]&~(|{funct7[6], funct7[4:0]})& funct3[2]&~funct3[1]& funct3[0] & ~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire srl_inst   = ~(|funct7)& funct3[2]&~funct3[1]& funct3[0] & ~opcode[6]& opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  // U
  wire lui_inst  = ~opcode[6]& opcode[5]& opcode[4]&~opcode[3]& opcode[2] & opcode[1]& opcode[0];
  wire auipc_inst= ~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]& opcode[2] & opcode[1]& opcode[0];
  // I
  wire lw_inst   = ~funct3[2]& funct3[1]&~funct3[0]&~opcode[6]&~opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire lbu_inst  =  funct3[2]&~funct3[1]&~funct3[0]&~opcode[6]&~opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire lb_inst   = ~funct3[2]&~funct3[1]&~funct3[0]&~opcode[6]&~opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire lhu_inst  =  funct3[2]&~funct3[1]& funct3[0]&~opcode[6]&~opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire lh_inst   = ~funct3[2]&~funct3[1]& funct3[0]&~opcode[6]&~opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire sltiu_inst= ~funct3[2]& funct3[1]& funct3[0] & ~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire addi_inst = ~funct3[2]&~funct3[1]&~funct3[0]&~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire jalr_inst = ~funct3[2]&~funct3[1]&~funct3[0]& opcode[6]& opcode[5]&~opcode[4]&~opcode[3]& opcode[2] & opcode[1]& opcode[0];
  wire srai_inst = funct7[5]&~(|{funct7[6], funct7[4:0]})& funct3[2]&~funct3[1]& funct3[0]&~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire slli_inst = ~(|funct7)&&~funct3[2]&~funct3[1]& funct3[0]&~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire srli_inst = ~(|funct7)&& funct3[2]&~funct3[1]& funct3[0]&~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire andi_inst =  funct3[2]& funct3[1]& funct3[0]&~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire ori_inst  =  funct3[2]& funct3[1]&~funct3[0]&~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire xori_inst =  funct3[2]&~funct3[1]&~funct3[0]&~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire slti_inst = ~funct3[2]& funct3[1]&~funct3[0]&~opcode[6]&~opcode[5]& opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  // B
  wire beq_inst= ~funct3[2]&~funct3[1]&~funct3[0] & opcode[6]& opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire bne_inst= ~funct3[2]&~funct3[1]& funct3[0] & opcode[6]& opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire blt_inst=  funct3[2]&~funct3[1]&~funct3[0] & opcode[6]& opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire bge_inst=  funct3[2]&~funct3[1]& funct3[0] & opcode[6]& opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire bltu_inst=  funct3[2]& funct3[1]&~funct3[0] & opcode[6]& opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];
  wire bgeu_inst=  funct3[2]& funct3[1]& funct3[0] & opcode[6]& opcode[5]&~opcode[4]&~opcode[3]&~opcode[2] & opcode[1]& opcode[0];

  // 指令类型
  wire instR = add_inst | sub_inst | and_inst | or_inst | xor_inst | slt_inst | sltu_inst | sll_inst | sra_inst | srl_inst;
  wire instI = addi_inst | jalr_inst | lw_inst | lbu_inst | sltiu_inst | lb_inst | lh_inst | lhu_inst | srai_inst | slli_inst | srli_inst | andi_inst | ori_inst | xori_inst | slti_inst;
  wire instU = lui_inst | auipc_inst;
  wire instJ = jal_inst;
  wire instS = sw_inst | sb_inst | sh_inst;
  wire instB = beq_inst | bne_inst | bge_inst | blt_inst | bgeu_inst | bltu_inst;

  // imm
  wire [`WORD_WIDTH-1:0] immI = {{20{inst[31]}}, inst[31:20]};
  wire [`WORD_WIDTH-1:0] immU = {inst[31:12], 12'd0};
  wire [`WORD_WIDTH-1:0] immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  wire [`WORD_WIDTH-1:0] immJ = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
  wire [`WORD_WIDTH-1:0] immB = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

  assign op[3] = auipc_inst | sltu_inst | sltiu_inst | sub_inst | srai_inst | sra_inst | sb_inst | sh_inst | sw_inst | jal_inst | jalr_inst;
  assign op[2] = xor_inst | or_inst | srai_inst | srli_inst | sra_inst | srl_inst | andi_inst | and_inst | xori_inst | ori_inst | bltu_inst | bgeu_inst | lbu_inst | lhu_inst;
  assign op[1] = lui_inst | sltu_inst | or_inst | sltiu_inst | andi_inst | and_inst | ori_inst | slti_inst | slt_inst | lw_inst | sw_inst | blt_inst | bge_inst;
  assign op[0] = auipc_inst | lui_inst | srai_inst | srli_inst | slli_inst | sra_inst | srl_inst | sll_inst | andi_inst | and_inst | lh_inst | lhu_inst | sh_inst | bne_inst | bge_inst | bgeu_inst | jalr_inst;

  // 功能单元类型(riscv32e)
  assign fu_type[0] = add_inst | sub_inst | and_inst | or_inst | xor_inst | slt_inst | sltu_inst | sll_inst | sra_inst | srl_inst | addi_inst | slti_inst | sltiu_inst | slli_inst | srai_inst | srli_inst | andi_inst | ori_inst | xori_inst | auipc_inst | lui_inst;
  assign fu_type[1] = lw_inst | lbu_inst | lb_inst | lhu_inst | lh_inst;
  assign fu_type[2] = sw_inst | sb_inst | sh_inst;
  assign fu_type[3] = beq_inst | bne_inst | blt_inst | bge_inst | bltu_inst | bgeu_inst;
  assign fu_type[4] = jal_inst | jalr_inst;

  assign imm =  instI ? immI : instS ? immS : instJ ? immJ : instB ? immB : instU ? immU : 0;
  
  assign rs1 = inst[19:15];
  assign rs1_valid = instR | instS | instB | instI;
  assign rs2 = inst[24:20];
  assign rs2_valid = instR | instS | instB; // R、S、B类型指令需要rs2
  assign rd = inst[11:7];
  assign rd_valid = instR | instI | instU | instJ; // R、I、U、J类型指令需要rd
  assign imm_valid = instI | instU | instS | instJ | instB; // I、U、S、J、B类型指令需要imm

endmodule