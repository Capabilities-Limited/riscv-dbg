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
module debug_rom (
  input  logic         clk_i,
  input  logic         req_i,
  input  logic [63:0]  addr_i,
  output logic [63:0]  rdata_o
);

  localparam int unsigned RomSize = 29;

  logic [RomSize-1:0][63:0] mem;
  assign mem = {
    64'h00000000_f20ff06f,
    64'hf24ff06f_14001033,
    64'h00040663_12001033,
    64'h10052223_14001033,
    64'h00447413_40044403,
    64'h7b202473_7b302573,
    64'h7b200073_7b202473,
    64'h7b302573_12001033,
    64'h10852423_f1402473,
    64'h14001033_00100073,
    64'h7b202473_7b302573,
    64'h12001033_10052623,
    64'h00c51513_00c55513,
    64'h00000517_14001033,
    64'hfd5ff06f_f8041ae3,
    64'h00247413_40044403,
    64'h00a40433_f1402473,
    64'h06041263_00147413,
    64'h40044403_00a40433,
    64'h10852023_f1402473,
    64'h0040006f_00a40433,
    64'h10852823_0100006f,
    64'h00a40433_10852a23,
    64'h14001033_00c51513,
    64'h00c55513_00000517,
    64'h7b351073_7b241073,
    64'h0ff0000f_02c0006f,
    64'h0240006f_0700006f,
    64'h0980006f_0480006f
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
    if (addr_q < $clog2(RomSize)'(RomSize)) begin
        rdata_o = mem[addr_q];
    end
  end

endmodule
