# DFT Mini Project — DFT Flow in Minimal Form

A self-contained Verilog project that walks through the **complete DFT (Design for Testability) flow** as practiced in the semiconductor industry, from scan insertion through LBIST using a tiny but real design.

---

## What This Project Teaches

| DFT Concept | Where It Appears |
|---|---|
| Why standard DFFs are untestable | `rtl/my_design.v` |
| Scan DFF (mux-D scan cell) | `rtl/scan_dff.v` |
| Scan insertion | `rtl/scan_insertion_my_design.v` |
| Scan chain (shift + capture + shift) | `tb/tb.v` tasks |
| LFSR pattern generation | `rtl/lfsr.v` |
| Decompressor (space compaction) | `rtl/decompressor.v` |
| MISR response compaction | `rtl/misr.v` |
| LBIST top-level integration | `rtl/top.v` |
| Golden signature / pass-fail | `tb/tb.v` |

---

## Project Structure

```
dft_mini_project/
├── rtl/
│   ├── my_design.v                  # Original design (no DFT)
│   ├── scan_dff.v                   # Scan-enabled D flip-flop
│   ├── scan_insertion_my_design.v   # my_design after scan insertion
│   ├── lfsr.v                       # LFSR: pseudo-random pattern generator
│   ├── decompressor.v               # Decompressor: 3→4 bit expansion
│   ├── misr.v                       # MISR: response compactor
│   └── top.v                        # Top-level LBIST integration
├── tb/
│   └── tb.v                         # Testbench (LBIST simulation)
├── Makefile
└── README.md
```

---

## DFT Concepts Explained

### 1. The Problem — Why Standard Designs Are Hard to Test

A design straight from RTL has flip-flops that are **not directly controllable or observable** from the chip's I/O pins. To test for manufacturing defects (stuck-at faults, bridging faults, etc.), you would need an astronomical number of input combinations.

See `rtl/my_design.v` — the 4 FFs inside cannot be individually observed from outside.

---

### 2. Scan DFF — The Fundamental DFT Cell

- **SE = 0** (Capture / Normal): `Q ← D` — standard DFF behaviour  
- **SE = 1** (Shift / Scan): `Q ← SI` — acts as a simple shift register cell

See `rtl/scan_dff.v`.

---

### 3. Scan Insertion — Replacing DFFs with Scan DFFs

All flip-flops in the design are replaced with scan_dffs and **chained in series**:

```
SI → [ff0] → [ff1] → [ff2] → [ff3] → SO
```

This creates a **scan chain** of length 4 (one FF per original DFF).

See `rtl/scan_insertion_my_design.v`.

---

### 4. The Test Cycle (Shift → Capture → Shift)

Every test pattern follows this 3-phase sequence:

```
Phase 1 — SHIFT IN  (SE=1, 4 clocks)
   Serial test pattern is clocked into the scan chain from SI.
   At the end, every FF holds a specific test value.

Phase 2 — CAPTURE   (SE=0, 1 clock)
   Combinational logic evaluates with the loaded pattern as inputs.
   FFs capture the response simultaneously.

Phase 3 — SHIFT OUT (SE=1, 4 clocks)
   The captured response is shifted out serially through SO → MISR.
```

---

### 5. LFSR — On-Chip Pattern Generator

In **LBIST (Logic Built-In Self-Test)**, patterns are generated on-chip — no external tester required.

A **Linear Feedback Shift Register** produces a pseudo-random sequence with period `2^n - 1` from a simple XOR-feedback circuit.

This project uses a 3-bit LFSR with polynomial `x³ + x + 1`:

```
Seed: 111
Sequence: 111 → 011 → 101 → 110 → 111 → ... (period 7)
```

See `rtl/lfsr.v`.

---

### 6. Decompressor — Space Compaction

A design has far more scan chains than LFSR bits. The **decompressor** expands a small seed into many scan chain inputs using XOR networks, producing linearly independent patterns with minimal hardware.

```
lfsr[2:0] ──▶ [ XOR network ] ──▶ scan_in[3:0]
```

This is the same concept as Mentor Tessent's **EDT (Embedded Deterministic Test)** decompressor.

See `rtl/decompressor.v`.

---

### 7. MISR — Response Compaction

Shifting out 4 FFs × 8 patterns = 32 bits of response. Sending all of this off-chip would require huge tester bandwidth. Instead, the **MISR** (Multiple Input Signature Register) compacts all serial responses into a single short **signature** using XOR feedback:

```
q[0] ← q[2] ^ scan_out
q[1] ← q[0]
q[2] ← q[1]
```

After all patterns run, the 3-bit signature is compared against the **golden signature** derived from fault-free simulation. A mismatch means a fault was detected.

See `rtl/misr.v`.

---

### 8. LBIST Top Level

```
          SHIFT phase (SE=1)         CAPTURE phase (SE=0)
          ──────────────────         ──────────────────────
 LFSR ──▶ Decompressor ──▶ [Scan Chain] ──▶ MISR
                                ▲
                          (DUT logic evaluates here)
```

See `rtl/top.v`.

---

## Quick Start

### Prerequisites

```bash
# Ubuntu / Debian
sudo apt install iverilog gtkwave

# macOS (Homebrew)
brew install icarus-verilog gtkwave
```

### Run

```bash
make          # compile + simulate (prints LBIST result)
make view     # open waveform in GTKWave
make clean    # remove build artifacts
```

### Output
<img width="581" height="780" alt="image" src="https://github.com/user-attachments/assets/7e6f2a09-8f8f-4df8-bf3c-098b523f727c" />





---

## Industry Mapping

| This Project | Industry Equivalent |
|---|---|
| `scan_dff` | Standard cell: `SDFF`, `SDFFRX1` etc. |
| Scan insertion | Synopsys DFT Compiler / Mentor Tessent scan insertion |
| LFSR | LBIST controller seed generator |
| Decompressor | Tessent EDT / Synopsys DFTMAX decompressor |
| MISR | On-chip compactor (Tessent LogicBIST) |
| Golden signature | ATE (Automatic Test Equipment) signature database |
| `mode` pin | `BIST_EN` / test mode control in chip top |

---

## Extending This Project

- **Add a second scan chain** — connect `scan_in[1]` to a second DUT  
- **Inject a fault** — force a wire to stuck-at-0 in `scan_insertion_my_design.v` and observe signature change  
- **Add ATPG mode** — drive scan chain from external `SI` pin when `mode=0`  
- **Increase LFSR width** — use a 16-bit LFSR for more pattern diversity  

---

## References

- Bushnell & Agrawal — *Essentials of Electronic Testing* (the standard textbook)  
- Synopsys DFT Compiler User Guide  
- Mentor Tessent Scan and ATPG documentation  
- IEEE 1149.1 (JTAG) — boundary scan standard  
