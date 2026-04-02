`timescale 1ns/1ps
// =============================================================================
// Module  : scan_dff
// Purpose : Scan-enabled D flip-flop (building block for scan chains)
//
// DFT Concept:
//   A standard DFF captures data from D on every clock edge.
//   A SCAN DFF adds a multiplexer at the input:
//     - SE=0 (normal/capture mode) → Q captures D  (functional)
//     - SE=1 (shift mode)          → Q captures SI (scan serial input)
//
//   This is the fundamental cell used in scan insertion.
//   SO = Q, allowing flip-flops to be chained: SO[n] → SI[n+1]
// =============================================================================

module scan_dff (
    input  wire clk,  // Clock
    input  wire rst,  // Synchronous active-high reset
    input  wire D,    // Functional data input
    input  wire SI,   // Scan serial input
    input  wire SE,   // Scan enable: 1=shift, 0=capture
    output reg  Q     // Output (also acts as SO when chained)
);

    always @(posedge clk) begin
        if (rst)
            Q <= 1'b0;
        else if (SE)
            Q <= SI;   // Shift mode: pass scan data
        else
            Q <= D;    // Capture mode: latch functional result
    end

endmodule
