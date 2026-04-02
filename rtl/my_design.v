`timescale 1ns/1ps
// =============================================================================
// Module  : my_design
// Purpose : Simple combinational + sequential logic (DFT-unaware version)
//
// DFT Concept:
//   This is the ORIGINAL design before any DFT modifications.
//   It contains 4 flip-flops that are NOT observable or controllable
//   from the primary I/O — making fault testing very difficult.
//
//   The DFT flow will:
//     1. Replace these standard DFFs with scan_dffs  (scan insertion)
//     2. Chain them into a scan path                 (scan chain)
//     3. Surround with LFSR + MISR for LBIST         (self-test)
//
//   Logic function:
//     d[0] = in[0] & in[1]
//     d[1] = in[1] ^ in[3]
//     d[2] = in[1] | in[2]
//     d[3] = in[2] ^ in[3]
// =============================================================================

module my_design (
    input  wire       clk,
    input  wire [3:0] in,
    output reg  [3:0] q
);

    wire [3:0] d;

    assign d[0] = in[0] & in[1];
    assign d[1] = in[1] ^ in[3];
    assign d[2] = in[1] | in[2];
    assign d[3] = in[2] ^ in[3];

    always @(posedge clk)
        q <= d;

endmodule
