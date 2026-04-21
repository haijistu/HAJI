`include "defines.v"
module CSRF (
  input clock,
  input reset,
  // io
  input [`CSR_ADDR_WIDTH-1:0] csr_wa0,
  input [`WORD_WIDTH-1:0]     csr_wd0,
  input                       csr_we0,
  input [`CSR_ADDR_WIDTH-1:0] csr_wa1,
  input [`WORD_WIDTH-1:0]     csr_wd1,
  input                       csr_we1,

  input [`CSR_ADDR_WIDTH-1:0] csr_raddr,
  output [`WORD_WIDTH-1:0]    csr_rdata,

  output [`WORD_WIDTH-1:0]    csr_mepc,
  output [`WORD_WIDTH-1:0]    csr_mtvec,
  
  // exc
  input                       retire_mepc_we_0,
  input [`WORD_WIDTH-1:0]     retire_mepc_wd_0,
  input                       retire_mcause_we_0,
  input [`WORD_WIDTH-1:0]     retire_mcause_wd_0,
  input                       retire_mepc_we_1,
  input [`WORD_WIDTH-1:0]     retire_mepc_wd_1,
  input                       retire_mcause_we_1,
  input [`WORD_WIDTH-1:0]     retire_mcause_wd_1,

  // issue - scoreboard
  input                       issue_csr_valid_0,
  input [`CSR_ADDR_WIDTH-1:0] issue_csr_addr_0,
  output                      issue_csr_ready_0,
  input                       issue_csr_valid_1,
  input [`CSR_ADDR_WIDTH-1:0] issue_csr_addr_1,
  output                      issue_csr_ready_1,
  
  output                      issue_mtvec_ready,
  output                      issue_mepc_ready
);

// mepc, mcause, mtvec, mstatus
wire mepc_ready;
wire mcause_ready;
wire mtvec_ready;
wire mstatus_ready;
csr_scoreboard #(`CSR_MEPC) mepc_r(clock, reset, csr_wa0, csr_we0, csr_wa1, csr_we1, issue_csr_valid_0, issue_csr_addr_0, issue_csr_valid_1, issue_csr_addr_1, mepc_ready);
csr_scoreboard #(`CSR_MCAUSE) mcause_r(clock, reset, csr_wa0, csr_we0, csr_wa1, csr_we1, issue_csr_valid_0, issue_csr_addr_0, issue_csr_valid_1, issue_csr_addr_1, mcause_ready);
csr_scoreboard #(`CSR_MTVEC) mtvec_r(clock, reset, csr_wa0, csr_we0, csr_wa1, csr_we1, issue_csr_valid_0, issue_csr_addr_0, issue_csr_valid_1, issue_csr_addr_1, mtvec_ready);
csr_scoreboard #(`CSR_MSTATUS) mstatus_r(clock, reset, csr_wa0, csr_we0, csr_wa1, csr_we1, issue_csr_valid_0, issue_csr_addr_0, issue_csr_valid_1, issue_csr_addr_1, mstatus_ready);

assign issue_mtvec_ready = mtvec_ready;
assign issue_mepc_ready = mepc_ready;

assign issue_csr_ready_0 = ((issue_csr_addr_0 == `CSR_MEPC) && mepc_ready) ||
                           ((issue_csr_addr_0 == `CSR_MCAUSE) && mcause_ready) ||
                           ((issue_csr_addr_0 == `CSR_MTVEC) && mtvec_ready) ||
                           ((issue_csr_addr_0 == `CSR_MSTATUS) && mstatus_ready);

assign issue_csr_ready_1 = (issue_csr_addr_0 != issue_csr_addr_1) &&
                           (((issue_csr_addr_1 == `CSR_MEPC) && mepc_ready) ||
                           ((issue_csr_addr_1 == `CSR_MCAUSE) && mcause_ready) ||
                           ((issue_csr_addr_1 == `CSR_MTVEC) && mtvec_ready) ||
                           ((issue_csr_addr_1 == `CSR_MSTATUS) && mstatus_ready));
                        
reg [`WORD_WIDTH-1:0] mepc;
reg [`WORD_WIDTH-1:0] mstatus;
reg [`WORD_WIDTH-1:0] mcause;
reg [`WORD_WIDTH-1:0] mtvec;

assign csr_mepc = mepc;
assign csr_mtvec = mtvec;
always @(posedge clock) begin
  if(reset) begin
    mepc <= 0;
    mstatus <= 32'h1800;
    mcause <= 0;
    mtvec <= 0;
  end
  else begin
    if(csr_we0) begin
      case (csr_wa0)
        `CSR_MEPC : mepc <= csr_wd0;
        `CSR_MCAUSE : mcause <= csr_wd0;
        `CSR_MTVEC : mtvec <= csr_wd0;
        `CSR_MSTATUS : mstatus <= csr_wd0;
        default: ;
      endcase
    end
    if(csr_we1) begin
      case (csr_wa1)
        `CSR_MEPC : mepc <= csr_wd1;
        `CSR_MCAUSE : mcause <= csr_wd1;
        `CSR_MTVEC : mtvec <= csr_wd1;
        `CSR_MSTATUS : mstatus <= csr_wd1;
        default: ;
      endcase
    end
    if(retire_mepc_we_0) mepc <= retire_mepc_wd_0;
    if(retire_mepc_we_1) mepc <= retire_mepc_wd_1;
    if(retire_mcause_we_0) mcause <= retire_mcause_wd_0;
    if(retire_mcause_we_1) mcause <= retire_mcause_wd_1;
  end
end

assign csr_rdata = {32{csr_raddr == `CSR_MEPC}} & mepc |
                   {32{csr_raddr == `CSR_MCAUSE}} & mcause |
                   {32{csr_raddr == `CSR_MTVEC}} & mtvec |
                   {32{csr_raddr == `CSR_MSTATUS}} & mstatus;

endmodule

module csr_scoreboard #(
  parameter [`CSR_ADDR_WIDTH-1:0] CSR_NUM
)(
  input clock,
  input reset,
  input [`CSR_ADDR_WIDTH-1:0] csr_wa0,
  input csr_we0,
  input [`CSR_ADDR_WIDTH-1:0] csr_wa1,
  input csr_we1,
  input csr_valid_0,
  input [`CSR_ADDR_WIDTH-1:0] csr_addr_0,
  input csr_valid_1,
  input [`CSR_ADDR_WIDTH-1:0] csr_addr_1,
  output ready
);

reg csr_ready;
always @(posedge clock) begin
  if(reset) begin
    csr_ready <= 1'b1;
  end
  else if((csr_wa0 == CSR_NUM && csr_we0) || (csr_wa1 == CSR_NUM && csr_we1)) begin
    csr_ready <= 1'b1;
  end
  else if((csr_valid_0 && csr_addr_0 == CSR_NUM) || (csr_valid_1 && csr_addr_1 == CSR_NUM)) begin
    csr_ready <= 1'b0;
  end
end
assign ready = csr_ready;
endmodule