`timescale 1ns/1ps
// =============================================================================
// Module  : top
// Purpose : Top-level DFT wrapper integrating all LBIST components
//
// DFT Architecture (LBIST flow):
//
//   ┌─────────┐   [2:0]   ┌──────────────┐   [3:0]
//   │  LFSR   │──────────▶│ DECOMPRESSOR │──┐
//   │(pattern │           │ (3→4 expand) │  │ scan_in[0]
//   │  gen)   │           └──────────────┘  │
//   └─────────┘                             │
//        ▲                                  ▼
//       clk                      ┌─────────────────────┐
//                                │  scan_insertion_    │
//   mode=1 → SE=1 (shift)        │    my_design        │──▶ q[3:0]
//   mode=0 → SE=0 (capture)      │  (DUT + scan chain) │
//                                └─────────────────────┘
//                                         │ SO (scan_out)
//                                         ▼
//                                    ┌─────────┐
//                                    │  MISR   │──▶ signature[2:0]
//                                    │(compact)│
//                                    └─────────┘
//
// LBIST Test Cycle (per pattern):
//   Phase 1 - SHIFT IN  (SE=1, N clock cycles): Load pattern into scan chain
//   Phase 2 - CAPTURE   (SE=0, 1 clock cycle):  Evaluate combinational logic
//   Phase 3 - SHIFT OUT (SE=1, N clock cycles): Push response into MISR
//
// Ports:
//   mode = 1  → LBIST mode (SE driven by LFSR/decompressor)
//   mode = 0  → Functional / external scan mode (SI from primary input)
// =============================================================================

module top (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] in,         // Functional inputs (used when mode=0)
    input  wire       mode,       // 0=functional/extscan, 1=LBIST
    input  wire       SI,         // External scan input (used when mode=0)
    output wire [3:0] q,          // DUT outputs
    output wire [2:0] signature   // MISR signature (LBIST result)
);

    wire [2:0] lfsr_out;
    wire [3:0] scan_in_expanded;
    wire       scan_chain_si;
    wire       scan_out;
    wire       SE;

    // Scan Enable: always tied to mode in this project
    assign SE = mode;

    // -------------------------------------------------------------------------
    // LFSR: generates pseudo-random seed bits
    // -------------------------------------------------------------------------
    lfsr lfsr_inst (
        .clk (clk),
        .rst (rst),
        .q   (lfsr_out)
    );

    // -------------------------------------------------------------------------
    // DECOMPRESSOR: expands 3 LFSR bits → 4 scan inputs
    // -------------------------------------------------------------------------
    decompressor decom_inst (
        .lfsr_out (lfsr_out),
        .scan_in  (scan_in_expanded)
    );

    // -------------------------------------------------------------------------
    // Scan input mux:
    //   LBIST mode  → LFSR-generated pattern via decompressor
    //   Normal mode → External SI pin (for ATPG / functional use)
    // -------------------------------------------------------------------------
    assign scan_chain_si = mode ? scan_in_expanded[0] : SI;

    // -------------------------------------------------------------------------
    // DUT with scan insertion
    // -------------------------------------------------------------------------
    scan_insertion_my_design scan_dut (
        .clk (clk),
        .rst (rst),
        .in  (in),
        .SI  (scan_chain_si),
        .SE  (SE),
        .q   (q),
        .SO  (scan_out)
    );

    // -------------------------------------------------------------------------
    // MISR: compacts serial scan-out response into a 3-bit signature
    // -------------------------------------------------------------------------
    misr misr_inst (
        .clk      (clk),
        .rst      (rst),
        .scan_out (scan_out),
        .signature(signature)
    );

endmodule
