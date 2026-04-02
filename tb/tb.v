`timescale 1ns/1ps
// =============================================================================
// Module  : tb
// Purpose : Testbench for DFT LBIST flow
//
// Test Plan:
//   1. Reset all DFT components
//   2. Run N LBIST cycles:
//        a. SHIFT IN  – load pseudo-random pattern into scan chain (SE=1)
//        b. CAPTURE   – evaluate combinational logic (SE=0, 1 cycle)
//        c. SHIFT OUT – push response into MISR (SE=1)
//   3. Print final MISR signature
//   4. Compare against golden signature (from fault-free simulation)
//
// Golden Signature:
//   Run this testbench on a known-good design first.
//   The printed signature becomes the reference for production testing.
//   Any deviation in silicon → fault detected.
// =============================================================================

module tb;

    // -------------------------------------------------------------------------
    // DUT connections
    // -------------------------------------------------------------------------
    reg        clk;
    reg        rst;
    reg  [3:0] in;
    reg        mode;   // 1=LBIST, 0=functional
    reg        SI;

    wire [3:0] q;
    wire [2:0] signature;

    // Golden signature — update this after first clean simulation run
    localparam [2:0] GOLDEN_SIGNATURE = 3'b010;  // derived from fault-free simulation

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    top dut (
        .clk       (clk),
        .rst       (rst),
        .in        (in),
        .mode      (mode),
        .SI        (SI),
        .q         (q),
        .signature (signature)
    );

    // -------------------------------------------------------------------------
    // Clock: 10 ns period
    // -------------------------------------------------------------------------
    initial clk = 0;
    always  #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: shift N cycles (SE=1)
    // -------------------------------------------------------------------------
    task shift_cycles;
        input integer n;
        integer i;
        begin
            mode = 1'b1;
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: capture cycle (SE=0, exactly 1 clock)
    // -------------------------------------------------------------------------
    task capture_cycle;
        begin
            mode = 1'b0;
            @(posedge clk);
        end
    endtask

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    integer pattern;
    integer pass;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);

        // --- Initialise ---
        rst  = 1'b1;
        mode = 1'b0;
        SI   = 1'b0;
        in   = 4'b1010;   // held constant; LBIST ignores functional in during shift

        // --- Reset: hold for 2 cycles ---
        repeat (2) @(posedge clk);
        rst = 1'b0;

        $display("----------------------------------------------------");
        $display(" LBIST SIMULATION START");
        $display("----------------------------------------------------");

        // --- LBIST: 8 test patterns ---
        // Each pattern = shift-in(4) + capture(1) + shift-out(4)
        for (pattern = 0; pattern < 8; pattern = pattern + 1) begin
            $display("[Pattern %0d]", pattern);

            // Phase 1: Shift in test pattern (load scan chain from LFSR/decompressor)
            $display("  SHIFT IN  (4 cycles, SE=1)");
            shift_cycles(4);

            // Phase 2: Capture — combinational logic evaluates, FFs sample result
            $display("  CAPTURE   (1 cycle,  SE=0)  q=%b", q);
            capture_cycle();

            // Phase 3: Shift out response into MISR
            $display("  SHIFT OUT (4 cycles, SE=1)  sig=%b", signature);
            shift_cycles(4);
        end

        // --- Final signature ---
        #10;
        $display("----------------------------------------------------");
        $display(" LBIST COMPLETE");
        $display(" Final Signature = %b  (hex: %h)", signature, signature);

        // --- Pass/Fail check ---
        // NOTE: On first run, read the printed signature and update GOLDEN_SIGNATURE above.
        pass = (signature === GOLDEN_SIGNATURE);
        if (GOLDEN_SIGNATURE === 3'b000)
            $display(" [INFO] GOLDEN_SIGNATURE is placeholder 3'b000.");
        else if (pass)
            $display(" [PASS] Signature matches golden reference.");
        else
            $display(" [FAIL] Signature MISMATCH! Expected %b, Got %b",
                      GOLDEN_SIGNATURE, signature);

        $display("----------------------------------------------------");
        #20;
        $finish;
    end

endmodule
