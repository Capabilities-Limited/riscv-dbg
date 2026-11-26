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
  input  logic         rst_ni,
  input  logic         req_i,
  input  logic [63:0]  addr_i,
  output logic [63:0]  rdata_o
);

  localparam int unsigned RomSize = 43;

  logic [RomSize-1:0][63:0] mem;
  assign mem = {
    64'h7b200073_7b302573,
    64'h7b202473_5600007b,
    64'h10852823_f1402473,
    64'h5610007b_9c9ff06f,
    64'h7b302573_7b202473,
    64'h9d5ff06f_5610007b,
    64'h7b302573_7b202473,
    64'h00040a63_5600007b,
    64'h00447413_40044403,
    64'h00a40433_f1402473,
    64'h10052423_00100073,
    64'h5610007b_7b302573,
    64'h7b202473_5600007b,
    64'h10052c23_71c5457b,
    64'hfffff517_5610007b,
    64'h00100073_7b302573,
    64'h7b202473_5600007b,
    64'h10052c23_73c5457b,
    64'hfffff517_5610007b,
    64'hfd5ff06f_f40418e3,
    64'h00247413_40044403,
    64'h00a40433_f1402473,
    64'h06041063_00147413,
    64'h40044403_00a40433,
    64'h10852023_f1402473,
    64'h7785457b_fffff517,
    64'h5610007b_7b351073,
    64'h7b241073_0ff0000f,
    64'h01c0006f_12852023,
    64'hf1402473_79c5457b,
    64'hfffff517_5610007b,
    64'h7b351073_7b241073,
    64'h0ff0000f_0400006f,
    64'h12852423_f1402473,
    64'h7c05457b_fffff517,
    64'h5610007b_7b351073,
    64'h7b241073_0ff0000f,
    64'h00000013_02c0006f,
    64'h00000013_0100006f,
    64'h00000013_0c80006f,
    64'h00000013_0b00006f,
    64'h00000013_1340006f,
    64'h00000013_0780006f
  };

  logic [$clog2(RomSize)-1:0] addr_d, addr_q;

  assign addr_d = req_i ? addr_i[$clog2(RomSize)-1+3:3] : addr_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      addr_q <= '0;
    end else begin
      addr_q <= addr_d;
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
