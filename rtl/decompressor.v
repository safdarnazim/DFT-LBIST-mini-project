`timescale 1ns/1ps
// =============================================================================
// Module  : decompressor
// Purpose : Expands 3 LFSR bits into 4 scan chain inputs (space compaction)
//
// DFT Concept:
//   In industry, a design has many more scan chains than LFSR output bits.
//   The DECOMPRESSOR (also called "EDT decompressor" in Mentor Tessent)
//   takes a few seed bits and expands them into many scan chain inputs
//   using XOR networks.
//
//   This creates LINEARLY INDEPENDENT patterns across chains, giving good
//   coverage without needing one LFSR bit per scan chain.
//
//   Expansion: 3 bits → 4 scan inputs
//     scan_in[0] = lfsr[0] ^ lfsr[1]
//     scan_in[1] = lfsr[1] ^ lfsr[2]
//     scan_in[2] = lfsr[2]
//     scan_in[3] = lfsr[0]
//
//   In this project, only scan_in[0] is used (single scan chain).
//   The other outputs illustrate how real designs expand to multiple chains.
// =============================================================================

module decompressor (
    input  wire [2:0] lfsr_out,  // 3-bit LFSR seed
    output wire [3:0] scan_in    // 4 expanded scan chain inputs
);

    assign scan_in[0] = lfsr_out[0] ^ lfsr_out[1];
    assign scan_in[1] = lfsr_out[1] ^ lfsr_out[2];
    assign scan_in[2] = lfsr_out[2];
    assign scan_in[3] = lfsr_out[0];

endmodule
