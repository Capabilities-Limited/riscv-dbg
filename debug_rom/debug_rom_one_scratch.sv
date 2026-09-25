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

  localparam int unsigned RomSize = 22;

  logic [RomSize-1:0][63:0] mem;
  assign mem = {
    64'h00000000_a59ff06f,
    64'ha5dff06f_14001033,
    64'h00040663_12001033,
    64'h10052223_14001033,
    64'h00447413_40044403,
    64'h7b202473_7b200073,
    64'h7b202473_12001033,
    64'h10802423_f1402473,
    64'h14001033_00100073,
    64'h7b202473_12001033,
    64'h10002623_14001033,
    64'hfddff06f_fa041ae3,
    64'h00247413_40044403,
    64'hf1402473_04041463,
    64'h00147413_40044403,
    64'h10802023_f1402473,
    64'h0040006f_10802823,
    64'h00c0006f_10802a23,
    64'h14001033_7b241073,
    64'h0ff0000f_0180006f,
    64'h0140006f_0500006f,
    64'h0680006f_0300006f
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
