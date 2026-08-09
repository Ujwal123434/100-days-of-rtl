# Day 01 — Sequence Detector `1011` (Moore FSM) | Verilog RTL

## 📌 Problem Statement

Design a **Moore FSM** in Verilog that detects the pattern **`1011`** in a
serial input bit stream, with **overlapping detection** — i.e. the FSM must
not discard bits after a match; it reuses the longest valid suffix that could
begin a new match.

Example:
```
Input  : 1011011
Match 1: 1011
Match 2:    1011   (shares the trailing "11" with match 1)
```

---

## 🧠 Why Moore (not Mealy) here

In a Moore machine, `detect` depends **only on current state**, so it's
glitch-free and easy to reason about — but it comes out **one clock cycle
after** the final bit arrives (since you must first clock into S4, then
read the output). A Mealy version would assert `detect` combinationally in
the *same* cycle as the last input bit — faster, but the output is more
prone to glitches (input-dependent) and can be trickier to time-close.

| | Moore | Mealy |
|---|---|---|
| Output depends on | current state only | current state + input |
| Output timing | 1 cycle after match | same cycle as match |
| States needed (this problem) | 5 | can be done in 4 |
| Glitch behavior | stable | can glitch on input changes |

---

## 🔀 State Transition Table

| Current State | Meaning        | din=0 → Next | din=1 → Next | detect |
|----------------|----------------|--------------|--------------|--------|
| S0             | no match       | S0           | S1           | 0      |
| S1             | matched `1`    | S2           | S1           | 0      |
| S2             | matched `10`   | S0           | S3           | 0      |
| S3             | matched `101`  | S2           | S4           | 0      |
| S4             | matched `1011` | S2           | S1           | 1      |

**Overlap logic (the part interviewers probe hardest):** from S4, on
`din=1` we go to **S1** (not S0), because that just-received `1` could be
the start of the next `1011`. On `din=0` we go to **S2**, because the last
two bits seen (`1` from entering S4 + this new `0`) form a valid `10`
partial match. This reuse — instead of always falling back to S0 — is
exactly what makes detection overlapping.

---

## ⚙ RTL Structure (3-always-block style)

1. **State register** — `always @(posedge clk)`, synchronous reset to `S0`.
2. **Next-state logic** — `always @(*)`, pure combinational `case`.
3. **Output logic** — `always @(*)`, `detect = (state == S4)`.

State encoding uses `localparam` with named states (`S0`..`S4`) — never
raw magic numbers — for readability and synthesis-tool friendliness.

---

## 🔬 Verified Simulation Result

Ran in Icarus Verilog with test stream `101101101101011`:

```
din    : 1 0 1 1 0 1 1 0 1 1 0 1 0 1 1
detect : 0 0 0 1 0 0 1 0 0 1 0 0 0 0 1
```

4 overlapping matches correctly detected, one cycle after each match completes.

---

## 🎤 Interview Q&A (for quick revision)

**Q1. What is a sequence detector?**
A sequential circuit that continuously monitors a serial bit stream and
asserts an output whenever a predefined pattern appears.

**Q2. Why Moore FSM here?**
Output depends only on current state → stable, glitch-free output, easier
to time and easier to reason about in a review.

**Q3. Moore vs Mealy — the real trade-off?**
Mealy reacts one cycle earlier (same-cycle output) but ties the output
directly to the input, so it can glitch; Mealy also often needs fewer
states since it can encode "about to match" transitions in the output
rather than a dedicated state.

**Q4. Why does S4 go to S1/S2 instead of S0?**
To support overlap — the tail bits of the completed match may already be
the start of the next match, so you must not discard them.

**Q5. Why `localparam` instead of raw numbers?**
Readability, maintainability, avoids magic numbers, and it's the
synthesis-safe way (vs `parameter`, which can be overridden externally —
you don't want your FSM encoding overridden by an instantiation).

**Q6. Why synchronous reset over asynchronous here?**
Synchronous reset changes state only on the clock edge — more predictable,
easier static timing closure, and avoids reset-recovery/removal timing
issues that async reset can introduce on FPGA/ASIC flows. (Async reset is
still used when you need the block reset instantly regardless of clock,
e.g. power-on reset trees.)

**Q7. How many states, and why 5 and not fewer?**
5 states (`S0`–`S4`) for a Moore implementation of a 4-bit pattern: one
state per "how much of the pattern has been matched so far," plus the
detect state. A Mealy version of the same detector can be done in 4 states
since the last transition's *output* signals the match instead of needing
a dedicated state for it.

**Q8. What if the pattern had repeated characters, e.g. `1111`?**
The overlap logic gets trickier — you'd need to carefully recompute, for
every state, the longest proper suffix of the matched-so-far string that
is also a prefix of the pattern (this is literally the KMP failure
function from string matching, applied to hardware). Good follow-up to
practice: try designing a detector for `1111` or `1101` and see how the
transition table changes.

---

## 📂 Files

- `sequence_detector.v` — DUT (Moore FSM)
- `tb_sequence_detector.v` — testbench, streams the 15-bit test vector
- `README.md` — this file

## ✅ Status
- Moore FSM implemented — ✔
- Overlapping detection — ✔
- Synchronous reset — ✔
- Testbench written and **simulated in Icarus Verilog** — ✔ (output verified above)