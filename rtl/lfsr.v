`timescale 1ns/1ps
// =============================================================================
// Module  : lfsr
// Purpose : 3-bit Linear Feedback Shift Register — pseudo-random pattern generator
//
// DFT Concept:
//   In LBIST (Logic Built-In Self-Test), test patterns must be generated ON-CHIP
//   without an external tester. An LFSR generates a long pseudo-random sequence
//   from a compact circuit, providing good fault coverage at low hardware cost.
//
//   This is a Fibonacci LFSR with polynomial x^3 + x + 1:
//     Feedback = q[0] ^ q[2]  (taps at positions 0 and 2)
//     Sequence: 111 → 011 → 101 → 110 → 111 → ... (period = 7)
//
//   The LFSR output feeds the DECOMPRESSOR to expand 3 bits → 4 scan inputs,
//   allowing more scan chains than LFSR bits (space compaction).
//
//   Initial seed = 3'b111 (must be non-zero for LFSR to run).
// =============================================================================

module lfsr (
    input  wire       clk,
    input  wire       rst,
    output wire [2:0] q    // Pseudo-random output
);

    reg [2:0] q_reg;

    // Fibonacci LFSR: next[2:0] = {q[1], q[0], q[0]^q[2]}
    always @(posedge clk or posedge rst) begin
        if (rst)
            q_reg <= 3'b111;   // Seed (must be non-zero)
        else
            q_reg <= {q_reg[1:0], q_reg[0] ^ q_reg[2]};
    end

    assign q = q_reg;

endmodule
