# Day 02 - Sequence Detector `1010` — Non-Overlap, Gray-Encoded, Async Reset | Verilog RTL

## 📌 Problem Statement

Design a sequence detector for pattern **`1010`** with **NON-OVERLAP**: once a
match completes, the FSM must restart cleanly from S0 — none of the bits that
formed the match may be reused toward the next match.

Chosen implementation: **Moore FSM**, in one line — output depends only on
state, so `detect` stays glitch-free even while `din` is toggling, which
matters more than same-cycle latency for a pattern-detect status flag.

---

## 🔀 Why non-overlap changes the table (the actual point of this exercise)

In an **overlap-allowed** detector, the "match" state's next-state logic
still depends on `din` — you reuse the trailing bits as a head start on the
next potential match (e.g. Day 1's `S4` went to `S1` or `S2` depending on
input).

In **non-overlap**, the match state's next-state logic must be
**independent of `din`** — it unconditionally returns to `S0`. The bit that
completed the match is consumed and discarded; the next potential match
starts strictly fresh on the *following* bit.

### State Transition Table

| Current | Meaning        | din=0 → Next | din=1 → Next | detect |
|---------|----------------|--------------|--------------|--------|
| S0      | no match       | S0           | S1           | 0      |
| S1      | matched `1`    | S2           | S1           | 0      |
| S2      | matched `10`   | S0           | S3           | 0      |
| S3      | matched `101`  | S4           | S1           | 0      |
| S4      | matched `1010` | **S0**       | **S0**       | 1      |

Note S4's row: **both** columns go to S0 — that's the tell that this is
non-overlap. (In the overlap version, that row would branch on `din`.)

**Proof it matters:** streaming `10101010` through this design —

```
din    : 1    0    1    0    1    0    1    0
detect : 0    0    0    1    0    0    0    0
state  : 001  011  010  110  000  000  001  011
```

Only **one** `detect` pulse, even though `1010` technically appears twice
in an overlapping reading of the stream (positions 1–4 and 5–8 don't
actually overlap here, but if you feed `101010` — where they *do* overlap —
non-overlap still fires once vs. overlap firing twice). Verified in
simulation (see below).

---

## 🎨 Gray-coded state encoding

Three encoding styles across three days now: binary → one-hot → **Gray**.
Gray guarantees exactly one bit flips between numerically-adjacent states —
useful in real designs where state transitions cross timing-sensitive logic
or feed into flags where multi-bit switching could cause transient
decoding glitches.

| State | Meaning | Gray code |
|-------|---------|-----------|
| S0 | no match | `000` |
| S1 | matched `1` | `001` |
| S2 | matched `10` | `011` |
| S3 | matched `101` | `010` |
| S4 | matched `1010` | `110` |

Each consecutive pair (S0→S1, S1→S2, S2→S3, S3→S4) differs by exactly one
bit — confirm this yourself before submitting; it's an easy thing to get
wrong under interview pressure if you just increment in binary and call it
"Gray."

---

## ⏱ Active-high asynchronous reset (the third twist)

```verilog
always @(posedge clk or posedge rst) begin
    if (rst) state <= S0;
    else     state <= next_state;
end
```

Async reset here means `rst` forces `state <= S0` **immediately**,
independent of `clk` — sensitivity list includes `posedge rst`. This is
different from Day 1's synchronous reset, where reset only took effect on
a clock edge. Tradeoff to know cold for interviews:

| | Synchronous reset | Asynchronous reset |
|---|---|---|
| Takes effect | only at clock edge | immediately, any time |
| Timing closure | easier (reset is just another synchronous input) | harder — needs reset **de-assertion** synchronized to avoid recovery/removal violations |
| Use case | most datapath logic | power-on reset trees, safety-critical resets that can't wait for a clock edge |
| Risk | none of the reset-recovery timing issues | if `rst` de-asserts too close to a clock edge, can cause metastability on release — real designs use a reset **synchronizer** to release async reset synchronously |

---

## 🔬 Verification: self-checking testbench with reference model

Instead of hardcoded expected values, the testbench runs an **independent
software reference model** in parallel with the DUT — same input `din`,
separately-derived FSM (plain integer state 0–4, deliberately *not*
Gray-coded, written straight from the spec rather than copied from the
RTL), and a scoreboard that flags any cycle where `dut.detect !=
ref_model.detect`.

- 40-bit directed vector (includes `10101010` specifically to stress the
  non-overlap boundary condition)
- 60 bits of randomized (`$random`) stimulus for additional coverage
- A mid-run async reset assertion to confirm reset recovery behaves
  correctly outside the normal clock-aligned flow

### Actual simulation result (Icarus Verilog)

```
*** PASS: all 102 checks matched reference model. ***
```

And the isolated `10101010` trace confirming exactly one `detect` pulse:

```
din detect state
1    0      001
0    0      011
1    0      010
0    1      110   <-- match, detect=1
1    0      000   <-- forced back to S0 regardless of din=1
0    0      000
1    0      001
0    0      011
```

---

## 🎤 Interview Q&A

**Q1. What's the one structural difference between overlap and non-overlap FSMs?**
The next-state logic of the final (match) state: overlap-allowed makes it
depend on `din` (reusing trailing bits); non-overlap makes it a fixed,
unconditional transition back to S0.

**Q2. Why Moore over Mealy for this?**
One-line justification: `detect` is a status flag, not a combinational
pass-through — glitch-free stability under changing `din` matters more here
than shaving one cycle of latency.

**Q3. What breaks if you got the non-overlap transition wrong (i.e. left it din-dependent)?**
You'd silently get overlap behavior instead — the bug wouldn't show up on
most test patterns, only on inputs where the pattern's suffix and prefix
overlap (like `1010` inside `101010` or `10101010`), which is exactly why
the directed testbench specifically includes that vector.

**Q4. Why use a reference model instead of hardcoded expected outputs?**
Hardcoded values encode the same assumptions as the RTL — if you
misunderstood the spec, both the RTL and your expected values are wrong
the same way, and the testbench passes a broken design. An independently
derived reference model (different state encoding, written fresh from the
spec) catches that class of correlated mistake.

**Q5. Async vs sync reset — which would you actually pick for this block in a real ASIC/FPGA flow, and why?**
Depends on context: FPGAs generally prefer sync reset (uses existing fabric
routing efficiently, avoids reset-recovery timing headaches); ASICs often
use async assert / sync de-assert (a reset synchronizer) to get immediate
reset behavior without metastability risk on release. A raw fully-async
reset with no synchronizer (as used in this exercise for practice) is
usually avoided in production designs for exactly that release-timing
reason.

**Q6. Why Gray coding for FSM states specifically?**
Reduces simultaneous multi-bit transitions, which matters when state bits
feed into asynchronous logic, cross clock domains, or drive output pins
directly — fewer bits changing at once means fewer transient/glitchy
intermediate values during propagation delay mismatches.

---

## 📂 Files

- `seq_det_1010_nonoverlap.v` — DUT (Moore FSM, Gray-encoded, async reset)
- `tb_seq_det_1010_nonoverlap.v` — self-checking TB with independent reference model
- `README.md` — this file

## ✅ Status
- Non-overlap transition table derived and commented in RTL — ✔
- Gray-coded `localparam` state encoding (verified 1-bit adjacency) — ✔
- Active-high asynchronous reset — ✔
- Self-checking scoreboard testbench vs. independent reference model — ✔
- **Simulated in Icarus Verilog: 102/102 checks passed** — ✔
