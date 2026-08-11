# Day 03 - Sequence Detector `1101` — Overlap, One-Hot, Mealy, Sync Reset | Verilog RTL

## 📌 Problem Statement

Design a sequence detector for pattern **`1101`** with **OVERLAP** allowed:
once a match completes, the bit that just completed it is immediately
reused as the start of the next potential match — nothing is discarded.

Chosen implementation: **Mealy FSM**, in one line — `z` is a function of
`(state, x)`, so detection asserts on the *same* cycle the final bit is
consumed, one cycle earlier than an equivalent Moore design would flag it.

---

## 🔀 Why overlap changes the table (the actual point of this exercise, mirrored from Day 2)

In a **non-overlap** detector (Day 2), the match state's next-state logic
is independent of the input — it unconditionally returns to S0, discarding
the bit that completed the match.

In **overlap-allowed** detection, the match transition's next-state logic
**does** depend on the input — the bit that completed the match is
re-evaluated as the start of a fresh partial match rather than thrown away.

### State Transition & Output Table

| Current | Meaning (matched prefix) | x=0 → Next | x=0 → z | x=1 → Next | x=1 → z |
|---------|---------------------------|------------|---------|------------|---------|
| S0      | "" (no match)             | S0         | 0       | S1         | 0       |
| S1      | `1`                       | S0         | 0       | S2         | 0       |
| S2      | `11`                      | S3         | 0       | S2         | 0       |
| S3      | `110`                     | S0         | 0       | **S1**     | **1**   |

Note S3's row on `x=1`: next-state is **S1**, not S0 — that's the tell that
this is overlap. (In the non-overlap version, that row would go
unconditionally to S0 regardless of `x`.)

**Proof it matters:** streaming `1101101` through this design —

```
x      : 1    1    0    1    1    0    1
z      : 0    0    0    1    0    0    1
state  : 0010 0100 1000 0010 0100 1000 0010
```

Two `z` pulses from a 7-bit stream where the two matches of `1101` share a
bit — `1101101` contains `1101` at position 1–4 and again at position 4–7,
overlapping on the middle `1`. A non-overlap version of this same stream
would only fire once. Verified in simulation (see below).

---

## 🎨 One-hot state encoding

| State | Meaning | One-hot code |
|-------|---------|----------------|
| S0 | no match | `4'b0001` |
| S1 | matched `1` | `4'b0010` |
| S2 | matched `11` | `4'b0100` |
| S3 | matched `110` | `4'b1000` |

Only 4 states are needed (not 5) precisely because this is Mealy — the
"match found" event is a transition, not a state, so there's no dedicated
post-match state the way a Moore version would require.

One-hot was chosen deliberately here because `z` is already combinational
(Mealy output = f(state, x)) and therefore already exposed to glitch risk.
One-hot removes the state *decoder* from the output path entirely — each
state is its own wire, so the output logic is a direct AND of `state[3]`
and `x`, rather than a multi-bit equality comparator. Fewer gates on the
glitch-sensitive output path, at the cost of 4 flops instead of 2.

---

## ⏱ Synchronous active-high reset

```verilog
always @(posedge clk) begin
    if (rst) state <= S0;
    else     state <= next_state;
end
```

Only `posedge clk` in the sensitivity list — `rst` is sampled like any
other synchronous input and only takes effect on a clock edge. Contrast
with Day 2's async reset, which forced `state <= S0` immediately via
`posedge rst` in the sensitivity list.

| | Synchronous reset (this design) | Asynchronous reset (Day 2) |
|---|---|---|
| Takes effect | only at clock edge | immediately, any time |
| Timing closure | easier — reset is just another synchronous input | harder — needs reset **de-assertion** synchronized to avoid recovery/removal violations |
| Use case | most datapath logic, ASIC flows favoring smaller cells | power-on reset trees, safety-critical resets that can't wait for a clock edge |
| Risk | state is undefined until the first clock edge after reset asserts — no reset without a live clock | glitch on `rst` line can corrupt state independent of clock |

---

## 🔬 Verification: self-checking testbench with reference model

Following the Day 2 pattern, the testbench should run an **independent
software reference model** in parallel with the DUT — same input `x`,
separately-derived FSM (plain integer state 0–3, written fresh from the
transition table above rather than copied from the RTL), and a scoreboard
flagging any cycle where `dut.z != ref_model.z`.

Recommended stimulus:
- A directed vector including `1101101` specifically, to stress the
  overlap boundary condition (two matches sharing a bit)
- A vector including `11101101` (a near-miss `1110` followed by a real
  match) to confirm the FSM doesn't false-positive on partial matches
- 60+ bits of `$random` stimulus for additional coverage
- A mid-run reset assertion aligned to a clock edge, since sync reset only
  behaves correctly when sampled that way — worth explicitly testing that
  a reset asserted between clock edges doesn't take effect until the next
  edge, as expected

### Actual simulation result (from the waveform run this session)

Testbench stream applied: `1, 1, 0, 1, 1, 0, 1, 0`

```
x    z   state (after clock edge)
1    0   S1
1    0   S2
0    0   S3
1    1   S1   <-- match #1: ...1101 complete
1    0   S2
0    0   S3
1    1   S1   <-- match #2: overlap reuse of trailing 1, then 1101 completes again
0    0   S0
```

Two `z` pulses confirmed on the waveform, both landing on the cycle where
the final `1` of a `1101` match is consumed — matching Mealy timing
(assert same-cycle, not one cycle later as Moore would).

---

## 🎤 Interview Q&A

**Q1. What's the one structural difference between overlap and non-overlap FSMs?**
The next-state logic of the final (match) state: overlap-allowed makes it
depend on the input (reusing trailing bits as a head start); non-overlap
makes it a fixed, unconditional transition back to S0.

**Q2. Why Mealy over Moore for this one?**
One-line justification: minimum-latency detection matters here — `z`
needs to assert the same cycle the match completes rather than one cycle
later, which is the whole point of contrasting this against Day 2's Moore
design.

**Q3. What breaks if you got the overlap transition wrong (i.e. sent S3 to S0 unconditionally on x=1)?**
You'd silently get non-overlap behavior instead — it wouldn't show up on
most test patterns, only on inputs where the pattern's suffix and prefix
overlap (like `1101` inside `1101101`), which is exactly why the directed
testbench specifically includes that vector.

**Q4. Why use a reference model instead of hardcoded expected outputs?**
Hardcoded values encode the same assumptions as the RTL — if the spec was
misunderstood, both the RTL and the expected values are wrong the same
way, and the testbench passes a broken design. An independently derived
reference model (different state representation, written fresh from the
spec) catches that class of correlated mistake.

**Q5. Sync vs async reset — which would you actually pick for this block in a real ASIC/FPGA flow, and why?**
Depends on context: ASIC flows generally favor sync reset for cleaner
timing closure and smaller flip-flop cells; safety-critical or power-on
reset paths favor async assert with a synchronizer for release, to
guarantee reset takes effect even without a running clock. A raw
fully-synchronous reset (as used here) is standard for ordinary datapath
logic where reset-recovery timing would otherwise be a headache.

**Q6. Why does S2 stay at S2 on x=1 instead of resetting the match count?**
Because after matching `11`, another `1` gives `111` — the FSM is tracking
"longest matched prefix of `1101`," and the incoming `1` doesn't extend
the match, but the last two 1's still represent a valid `11` prefix. This
is the same failure-function logic (KMP-style) that governs every overlap
detector's "stay put on a repeated symbol" transitions.

**Q7. What's the glitch risk specific to Mealy outputs, and how does one-hot mitigate it here?**
Since `z = f(state, x)` is purely combinational, any glitch on `x` before
the clock edge propagates directly to `z` — there's no register to filter
it. One-hot encoding keeps the output logic to a single AND gate
(`state[S3] & x`), minimizing the combinational depth on that
glitch-sensitive path compared to a binary-encoded equality comparator.

---

## 📂 Files

- `mealy_sequence_detector_overlap.v` — DUT (Mealy FSM, one-hot encoded, sync reset)
- `tb.v` — testbench (recommend upgrading to self-checking w/ reference model per Day 2 pattern)
- `README.md` — this file

## ✅ Status
- Overlap transition table derived and commented in RTL — ✔
- One-hot `localparam` state encoding — ✔
- Synchronous active-high reset — ✔
- Waveform-verified: two overlapping `z` pulses on `1101101`-containing stream — ✔
- Self-checking scoreboard testbench vs. independent reference model — ⬜ (recommended next step, see Day 2 pattern)