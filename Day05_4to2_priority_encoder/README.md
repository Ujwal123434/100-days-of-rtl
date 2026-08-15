# 🔍 Day 05 — 4-bit Priority Encoder with Valid Output

## 📌 Question of the Day

### 🧩 Problem Statement
Design a combinational 4-bit priority encoder that outputs the binary code of the highest-priority active input bit, along with a valid flag indicating whether any input bit is active at all.

### ⚙️ Module Declaration
```verilog
module priority_encoder (
    input  wire [3:0] in,
    output reg  [1:0] code,
    output wire       valid
);
```

### ✅ Requirements
- 4-bit input `in[3:0]`.
- Output `code[1:0]` gives the binary index of the **highest-priority active bit** — bit 3 is highest priority, bit 0 is lowest.
- Output `valid` is high if any input bit is set, low when `in == 4'b0000`.
- Purely combinational — no clock, no reset.
- When multiple bits are active simultaneously, the higher-priority bit must win regardless of the state of lower bits.
- When `in == 4'b0000`, `code` is don't-care but `valid` must correctly deassert.

---

## 🧠 My Approach

Implemented the priority logic using a `casez` statement instead of a straight if-else chain, since `casez` maps cleanly onto priority-encoded bit patterns using `?` as a wildcard for "don't care about this bit, priority is already decided by a higher bit."

The implementation consists of:

- **Priority casez ladder** – checks `in[3]` first (`4'b1???`), then `in[2]` (`4'b01??`), then `in[1]` (`4'b001?`), then `in[0]` (`4'b0001`), with `default` catching `4'b0000`.
- **`valid` as a separate signal** – computed independently as `assign valid = |in`, rather than folded into `code`, so downstream logic has an explicit way to know whether `code` should be trusted.

```verilog
casez (in)
    4'b1???: code = 2'b11;
    4'b01??: code = 2'b10;
    4'b001?: code = 2'b01;
    4'b0001: code = 2'b00;
    default: code = 2'b00;
endcase
assign valid = |in;
```

`casez` was chosen deliberately over `casex`: `casez` treats `?`/`z` as wildcards in the case items but still compares `x` on the input literally, whereas `casex` would also treat an unknown `x` on the input as a wildcard. If `in` ever carries an `x` (e.g. before reset/power-up settles in simulation), `casex` risks a false match and masks a real bug — `casez` is the safer choice for priority-style decode logic.

---

## 💡 Key Learning

- Understood the distinction between priority-encoded logic and one-hot decode logic — priority means only the highest-priority active bit matters, all lower bits are ignored once a higher one is set.
- Learned why `casez` is preferred over `casex` in RTL that will actually be synthesized/simulated with real (possibly unknown) hardware signals.
- Understood why a separate `valid` flag is necessary — without it, `code == 2'b00` is ambiguous between "bit 0 is active" and "nothing is active," which is a real bug class in interrupt controllers and arbiters (silently triggering line-0 handling when no interrupt occurred).
- Verified full case coverage by hand: 8 + 4 + 2 + 1 + 1 (default) = 16, matching all possible 4-bit input combinations, avoiding latch inference.

---

## 🔬 Simulation Result

✔ Correctly encodes the highest active bit for all 16 input combinations.
✔ Higher-priority bits correctly override lower-priority bits when multiple are set simultaneously (e.g. `in=0101` → `code=10`, bit 2 wins over bit 0).
✔ `code` stays flat/constant across each priority band regardless of lower-bit activity (verified `code=10` held across `0100`–`0111`, `code=11` held across `1000`–`1111`).
✔ `valid` correctly deasserts only at `in=0000` and stays asserted for all other 15 input values.
✔ Verified via exhaustive waveform sweep of all 16 input combinations (`in = 4'b0000` through `4'b1111`).

---

## 🎤 Interview Q&A

**Q1. What's the difference between `casez` and `casex`, and why does it matter here?**

`casez` only treats `?`/`z` as wildcards in the case items, while `casex` also treats `x` on the input side as a wildcard. If `in` ever carries an unknown `x` value (e.g. during power-up before signals settle), `casex` could incorrectly match a branch, masking a real bug. `casez` avoids this and is the safer default for priority-style decode logic.

**Q2. What would change if this were rewritten as an if-else priority chain instead of `casez`?**

Functionally identical — same priority order, same outputs. The main differences are readability/style and how explicitly the priority order is expressed in the code; most synthesis tools produce equivalent priority-mux hardware either way.

**Q3. Why not just use `|in` logic directly instead of a separate `valid` output?**

That's exactly what `valid` is — `assign valid = |in`. The point of exposing it as its own output is so downstream logic can explicitly check "is `code` meaningful" before acting on it, rather than silently trusting a `code` value that might correspond to no active input at all.

**Q4. Where does a priority encoder actually get used in real hardware?**

Interrupt controllers (deciding which of several pending interrupt lines to service first), bus/resource arbiters (deciding which requester gets the bus this cycle), and cache/FIFO replacement or allocation logic — anywhere multiple simultaneous requests need a deterministic single winner.

**Q5. How would you prove your `casez` ladder has full input coverage without just trusting it?**

Count combinations per branch and sum against `2^N` total inputs: `4'b1???` covers 8 combos, `4'b01??` covers 4, `4'b001?` covers 2, `4'b0001` covers 1, and `default` covers the remaining 1 (`0000`) — 8+4+2+1+1 = 16, matching all possible 4-bit inputs. This also confirms there's no missing case that could infer an unintended latch.

---

## 🚧 Known Gap / Next Step
Testbench code not yet documented in this README — waveform was verified via an exhaustive 16-value sweep of `in`, but the actual testbench source (loop-driven vs. manual stimulus, self-checking vs. visual-only) should be added here once finalized.