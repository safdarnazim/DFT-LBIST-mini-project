`timescale 1ns/1ps
// =============================================================================
// Module  : misr
// Purpose : 3-bit Multiple Input Signature Register — response compactor
//
// DFT Concept:
//   After a test pattern is applied and the response is captured,
//   the scan chain is SHIFTED OUT. Instead of sending all shift-out bits
//   to an external tester (which would need huge bandwidth), the MISR
//   COMPACTS the entire serial response into a short SIGNATURE.
//
//   The MISR is a shift register with XOR feedback from the serial input:
//     q[0] ← q[2] ^ scan_out
//     q[1] ← q[0]
//     q[2] ← q[1]
//
//   This is a 3-bit MISR with polynomial x^3 + x + 1 (same as LFSR).
//
//   After all test patterns are applied, the final signature is compared
//   against a GOLDEN SIGNATURE (computed from fault-free simulation).
//   A mismatch → FAULT DETECTED.
//
//   This is the BIST "go/no-go" mechanism used in volume manufacturing test.
// =============================================================================

module misr (
    input  wire       clk,
    input  wire       rst,
    input  wire       scan_out,    // Serial response from scan chain tail
    output wire [2:0] signature    // Compacted test signature
);

    reg [2:0] q;

    always @(posedge clk) begin
        if (rst) begin
            q <= 3'b000;
        end else begin
            q[0] <= q[2] ^ scan_out;  // XOR injection from scan chain
            q[1] <= q[0];
            q[2] <= q[1];
        end
    end

    assign signature = q;

endmodule
