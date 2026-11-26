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

  localparam int unsigned RomSize = 38;

  logic [RomSize-1:0][63:0] mem;
  assign mem = {
    64'h00000000_7b200073,
    64'h7b302573_7b202473,
    64'h10852823_f1402473,
    64'h9edff06f_7b302573,
    64'h7b202473_9f9ff06f,
    64'h5610007b_7b302573,
    64'h7b202473_00040a63,
    64'h00447413_40044403,
    64'h0685047b_f1402473,
    64'h10052423_00100073,
    64'h5610007b_7b302573,
    64'h7b202473_10052c23,
    64'h7385457b_fffff517,
    64'h00100073_7b302573,
    64'h7b202473_10052c23,
    64'h7505457b_fffff517,
    64'hfd5ff06f_f60410e3,
    64'h00247413_40044403,
    64'h0685047b_f1402473,
    64'h04041863_00147413,
    64'h40044403_0685047b,
    64'h10852023_f1402473,
    64'h7885457b_fffff517,
    64'h7b351073_7b241073,
    64'h0ff0000f_0180006f,
    64'h12852023_f1402473,
    64'h7a85457b_fffff517,
    64'h7b351073_7b241073,
    64'h0ff0000f_0380006f,
    64'h12852423_f1402473,
    64'h7c85457b_fffff517,
    64'h7b351073_7b241073,
    64'h0ff0000f_0240006f,
    64'h00000013_00c0006f,
    64'h00000013_0b00006f,
    64'h00000013_0a00006f,
    64'h00000013_1100006f,
    64'h00000013_06c0006f
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
