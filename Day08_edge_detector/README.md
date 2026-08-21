## 🔍 Day 07 — Edge Detector (Rising & Falling)

### 📌 Question of the Day

#### 🧩 Problem Statement
Design a synchronous edge detector that monitors an input signal and generates single-cycle pulses whenever a rising edge or a falling edge is detected.

#### ⚙️ Module Declaration
```verilog
module edge_detector (
    input  wire clk,
    input  wire rst,
    input  wire signal_in,
    output reg  rising_edge,
    output reg  falling_edge
);
```

#### ✅ Requirements
- Detect rising edge (0 → 1) and falling edge (1 → 0) on `signal_in`.
- Each output pulses high for exactly **1 clock cycle** per detected edge.
- Synchronous reset, active high.

---

### 🧠 My Approach
- Maintain a registered copy of the input, `prev`, updated every clock cycle.
- Compare the **current** value of `signal_in` against the **previous registered** value:
  - `rising_edge  = signal_in & ~prev`
  - `falling_edge = ~signal_in & prev`
- Register both edge outputs directly (rather than computing them combinationally), so the pulses are glitch-free and cleanly aligned to the clock — at the cost of one extra cycle of latency between the actual transition and the flagged pulse.

### 💡 Key Learning
Registering the edge-detect logic instead of leaving it combinational is a deliberate trade-off: you lose a cycle of latency but gain a clean, glitch-free pulse with no combinational hazards feeding downstream logic. In interviews, being able to name this trade-off (registered vs combinational edge detect) signals you understand *why* you chose a style, not just that it works in simulation.

### 🔬 Simulation Result
Verified in Icarus Verilog. Waveform confirms:
- Rising edge pulse generated exactly one cycle after `signal_in` transitions 0 → 1.
- Falling edge pulse generated exactly one cycle after `signal_in` transitions 1 → 0.
- Both pulses are exactly one clock cycle wide.
- No spurious pulses during steady-state high or low periods.

### 🎤 Interview Q&A
**Q: Why register `prev` instead of just comparing `signal_in` to a combinational delayed version?**
A: Registering `prev` *is* the delay — a flip-flop is the simplest 1-cycle delay element. Comparing it against the live input each cycle is what produces the edge pulse.

**Q: What happens if `signal_in` is asynchronous to `clk`?**
A: Sampling an async signal directly into logic risks metastability. A proper design would pass `signal_in` through a 2-flip-flop synchronizer before feeding this edge-detect logic — not implemented here since it wasn't in scope, but worth calling out explicitly in a review.

**Q: Could this glitch if `signal_in` toggles faster than the clock period?**
A: Yes — any edges narrower than one clock period can be missed entirely (classic sampling/aliasing problem). This design assumes `signal_in` is stable for at least one full clock cycle per level.

### 🚧 Known Gap / Next Step
- Testbench is directed/waveform-verified, not self-checking — no automated pass/fail assertions.
- No 2-FF synchronizer implemented for the async input path (called out above, but a stronger submission would include it or explicitly justify skipping it).
- No test coverage for back-to-back edges with minimal spacing between transitions.