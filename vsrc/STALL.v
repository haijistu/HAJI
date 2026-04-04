`include "defines.v"
module STALL (
  input                           rob_full,
  output [`STALL_ADDR_WIDTH-1:0]  stall
);

assign stall = rob_full ? 5'b00111 : 5'b00000;
endmodule