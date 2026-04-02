`timescale 1ns/1ps
// =============================================================================
// Module  : scan_insertion_my_design
// Purpose : my_design after scan insertion — standard DFFs replaced by scan_dffs
//
// DFT Concept:
//   All 4 flip-flops in my_design are replaced with scan_dff cells.
//   They are chained in series to form a SCAN CHAIN:
//
//     SI → [ff0] → [ff1] → [ff2] → [ff3] → SO
//
//   In SHIFT mode (SE=1):
//     Serial data is shifted through all flip-flops like a shift register.
//     This lets the tester LOAD a specific test pattern into all FFs,
//     and UNLOAD the captured response without needing direct access to each FF.
//
//   In CAPTURE mode (SE=0):
//     All FFs capture their combinational D input simultaneously (1 clock cycle).
//     This is the actual "test" moment.
//
//   Scan chain length = 4 (one per FF in the design).
// =============================================================================

module scan_insertion_my_design (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] in,   // Functional inputs
    input  wire       SI,   // Scan serial input (head of chain)
    input  wire       SE,   // Scan enable
    output wire [3:0] q,    // Functional outputs
    output wire       SO    // Scan serial output (tail of chain)
);

    // Internal combinational logic (same as my_design)
    wire [3:0] d;
    assign d[0] = in[0] & in[1];
    assign d[1] = in[1] ^ in[3];
    assign d[2] = in[1] | in[2];
    assign d[3] = in[2] ^ in[3];

    // Scan chain: ff0 → ff1 → ff2 → ff3
    // Q of each FF feeds SI of the next
    scan_dff ff0 (.clk(clk), .rst(rst), .D(d[0]), .SI(SI  ), .SE(SE), .Q(q[0]));
    scan_dff ff1 (.clk(clk), .rst(rst), .D(d[1]), .SI(q[0]), .SE(SE), .Q(q[1]));
    scan_dff ff2 (.clk(clk), .rst(rst), .D(d[2]), .SI(q[1]), .SE(SE), .Q(q[2]));
    scan_dff ff3 (.clk(clk), .rst(rst), .D(d[3]), .SI(q[2]), .SE(SE), .Q(q[3]));

    assign SO = q[3]; // Tail of scan chain

endmodule
