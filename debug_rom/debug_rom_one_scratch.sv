/* Copyright 2018 ETH Zurich and University of Bologna.
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * File: $filename.v
 *
 * Description: Auto-generated bootrom
 */

// Auto-generated code
module debug_rom_one_scratch (
  input  logic         clk_i,
  input  logic         req_i,
  input  logic [63:0]  addr_i,
  output logic [63:0]  rdata_o
);

  localparam int unsigned RomSize = 29;

  logic [RomSize-1:0][63:0] mem;
  assign mem = {
    64'h00000000_7b200073,
    64'h7b202473_5600007b,
    64'h10802423_f1402473,
    64'h5610007b_a39ff06f,
    64'h7b202473_a41ff06f,
    64'h5610007b_7b202473,
    64'h00040863_5600007b,
    64'h00447413_40044403,
    64'hf1402473_10002223,
    64'h00100073_5610007b,
    64'h7b202473_5600007b,
    64'h10002623_5610007b,
    64'h00100073_7b202473,
    64'h5600007b_10002623,
    64'h5610007b_fddff06f,
    64'hf8041ce3_00247413,
    64'h40044403_f1402473,
    64'h04041263_00147413,
    64'h40044403_10802023,
    64'hf1402473_5610007b,
    64'h7b241073_0ff0000f,
    64'h0100006f_10802823,
    64'h5610007b_7b241073,
    64'h0ff0000f_0240006f,
    64'h10802a23_5610007b,
    64'h7b241073_0ff0000f,
    64'h0180006f_0080006f,
    64'h07c0006f_06c0006f,
    64'h0c80006f_0400006f
  };

  logic [$clog2(RomSize)-1:0] addr_q;

  always_ff @(posedge clk_i) begin
    if (req_i) begin
      addr_q <= addr_i[$clog2(RomSize)-1+3:3];
    end
  end

  // this prevents spurious Xes from propagating into
  // the speculative fetch stage of the core
  always_comb begin : p_outmux
    rdata_o = '0;
    if (addr_q < $clog2(RomSize+1)'(RomSize)) begin
        rdata_o = mem[addr_q];
    end
  end

endmodule
