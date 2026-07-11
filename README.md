![Verilog](https://img.shields.io/badge/Language-Verilog-blue)
![Simulation](https://img.shields.io/badge/Simulation-Vivado_XSIM-green)
![Protocol](https://img.shields.io/badge/Protocol-AMBA_AXI4-orange)
![Status](https://img.shields.io/badge/Status-Simulated-yellow)

# AXI Protocol Suite in Verilog

Custom RTL implementation of the AMBA AXI protocol family, built from scratch to understand how modern SoC interconnects actually work under the hood — not just use them as black-box IP.

This started as a way to really *get* AXI beyond the block diagrams in datasheets. Instead of instantiating a Vivado AXI IP and moving on, I wrote every channel, every handshake, and every burst mode myself, then simulated each one to watch the protocol behave exactly the way the spec describes.

---

## What's in here

| Module | Description |
|---|---|
| **AXI4 Full** | Master and Slave with all five channels — AW, W, B, AR, R — including FIXED, INCR, and WRAP burst support |
| **AXI4-Lite** | Simplified Master/Slave for single-beat, register-style access — no bursts, no IDs, just clean request-response |
| **AXI4-Stream** | Master/Slave pair built around the TVALID/TREADY handshake for continuous data movement, no addressing |
| **AXI4-Stream Arbiter** | Lets multiple AXI-Stream masters share one downstream slave without colliding |
| **AXI4-Stream FIFO** | Sits between a producer and consumer on the stream interface to absorb timing mismatches |
| **AXI4-Lite GPIO** | A memory-mapped peripheral, controlled entirely through AXI-Lite reads and writes — proof the Lite interface works end to end |

---

## Why I built it this way

AXI4 Full and AXI4-Lite are implemented as two separate designs, not one protocol with a "lite mode" flag — because that's how the actual specification treats them. Building them separately forced me to understand *why* AXI-Lite drops IDs, bursts, and out-of-order completion in the first place, instead of just knowing that it does.

The peripherals — GPIO, FIFO, and Arbiter — weren't handed a pre-built AXI interface. I wrote the AXI-facing logic for each one myself, which meant thinking through details like when a FIFO is allowed to deassert TREADY, or how an arbiter should handle a master that's mid-burst when a higher-priority request shows up.

---

## AXI4 Full — implementation details

- Independent read and write datapaths, each with its own FSM
- All five AXI4 channels implemented and handshaking correctly (AW, W, B, AR, R)
- Ready/Valid handshake on every channel, per spec — no combinational shortcuts between VALID and READY
- Burst address generation for FIXED, INCR, and WRAP modes
- WRAP boundary wraparound handled explicitly, not just INCR with a mask

### AXI4 channel architecture

*(Diagram from [fpgaemu.readthedocs.io](https://fpgaemu.readthedocs.io/en/latest/axi.html))*

![AXI4 channels](axi-full/axi4_channels.png)

---

## Repository structure

```
axi-protocols/
├── axi-full/
│   ├── rtl/        → Master & Slave RTL
│   ├── tb/         → Testbench
│   └── sim/        → Simulation waveform screenshots
├── axi-lite/
├── axi-stream/
├── axi-arbiter/
├── axi-gpio/
├── axi-fifo/
└── README.md
```

Every module is self-contained — its RTL, testbench, and waveform screenshots all live together, so each one can be reviewed on its own without digging through the rest of the repo.

---

## Simulation status

Every module has been written and simulated in Vivado XSIM, with waveforms checked by hand to confirm correct behavior:

- Ready/Valid handshaking completes correctly on every channel
- Read and write transactions complete with the expected timing
- Burst addresses increment and wrap correctly across FIXED, INCR, and WRAP modes
- GPIO reads and writes land on the correct registers through AXI-Lite
- AXI-Stream transfers and FIFO buffering behave as expected under back-pressure

This is simulation-level confidence, not formal verification — there's no UVM environment, no constrained-random stimulus, and no functional coverage behind these results yet. That's the next stage of this project, not something I'm claiming is done.

---

## Sample waveforms

<!-- Add screenshots here, e.g.: -->
<!-- ![AXI4 Full Write Transaction](axi-full/sim/axi_full_write.png) -->

---

## Tools

| Tool | Purpose |
|---|---|
| Verilog | RTL design |
| Vivado XSIM | Simulation |
| VS Code | Development |

---

## Project stats

| | |
|---|---|
| Language | Verilog |
| Protocols implemented | AXI4, AXI4-Lite, AXI4-Stream |
| Modules | 8 |
| Burst types | FIXED, INCR, WRAP |
| Simulator | Vivado XSIM |

---

## How to run a simulation

1. Open Vivado and create a new simulation-only project
2. Add the RTL sources from the relevant module's `rtl/` folder
3. Add the matching testbench from `tb/`
4. Run **Behavioral Simulation**
5. Inspect the waveform to confirm handshake and transaction behavior

---

## What's next

- A proper verification environment — starting with directed SystemVerilog testbenches, then UVM — for at least the AXI4 Full master/slave pair
- Functional coverage and SVA-based assertion checking
- Connecting the GPIO, FIFO, and Arbiter to an actual AXI interconnect instead of testing them in isolation
- FPGA implementation on real hardware, not just simulation

---

## Author

**Akhil N**
ECE student, focused on VLSI and RTL design
GitHub: [n-akhil-vlsi](https://github.com/n-akhil-vlsi)
