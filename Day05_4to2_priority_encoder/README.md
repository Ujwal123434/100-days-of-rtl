# 🗓️ Day 5 — 4-bit Priority Encoder with Valid Output

## 📋 Problem Statement

Design a combinational **4-bit priority encoder**:

- **Input:** `in[3:0]`
- **Output:** `code[1:0]` — binary code of the **highest-priority active bit** (bit 3 = highest priority, bit 0 = lowest)
- **Output:** `valid` — high if any input bit is set, low when `in == 4'b0000`
- Purely combinational — no clock, no reset

| `in` | `code` | `valid` |
|---|---|---|
| `0100` | `10` | `1` |
| `0101` | `10` (bit 2 wins over bit 0) | `1` |
| `0000` | `xx` (don't care) | `0` |

**Why this problem:** Priority encoders appear constantly in real hardware — interrupt controllers, bus arbiters, cache/FIFO replacement logic. It's also a classic interview question testing whether you understand *priority* logic vs *one-hot* logic, and it pairs well against the one-hot FSM from Day 3.

---

## 💻 RTL Design

```verilog
module priority_encoder (
    input  wire [3:0] in,
    output reg  [1:0] code,
    output wire       valid
);

always @(*) begin
    casez (in)
        4'b1???: code = 2'b11;
        4'b01??: code = 2'b10;
        4'b001?: code = 2'b01;
        4'b0001: code = 2'b00;
        default: code = 2'b00;
    endcase
end

assign valid = |in;

endmodule
```

### Design Choices

- **`casez` over `casex`:** `casez` treats `?`/`z` as don't-care in case items but compares `x` on the input literally. `casex` would treat unknown (`x`) input bits as don't-care too — dangerous here, since an uninitialized `in` (e.g. right after power-up) could false-match a branch under `casex`. `casez` is the safer choice for priority logic.
- **`valid` as a separate signal:** without it, `code = 00` is ambiguous — it could mean "bit 0 is active" or "nothing is active." Downstream logic gates on `valid` before trusting `code`, avoiding phantom triggers (e.g. a false interrupt-0 handler call when no interrupt occurred).
- **Full case coverage:** all 16 possible `in` combinations are covered across the four casez branches (8 + 4 + 2 + 1) plus `default` for `0000` — no latch inference risk.

---

## 🧪 Testbench


**Verification method:** exhaustive sweep of all 16 input combinations (`in = 4'b0000` through `4'b1111`), waveform-checked in simulation.

---

## 📊 Simulation Waveform

All 16 input combinations verified:

| `in` range | Expected `code` | Result |
|---|---|---|
| `0000` | `code=xx`, `valid=0` | ✅ |
| `0001` | `code=00`, `valid=1` | ✅ |
| `0010`–`0011` | `code=01` | ✅ |
| `0100`–`0111` | `code=10` (flat across all 4) | ✅ |
| `1000`–`1111` | `code=11` (flat across all 8) | ✅ |

`code` stays constant across each priority band regardless of what the lower bits are doing — confirming true priority behavior rather than simple bit detection.

---

## ❓ Q&A

**Q: What's the difference between `casez` and `casex`, and why does it matter here?**
A: `casez` only treats `?`/`z` as wildcards in the case items, while `casex` also treats `x` on the input side as a wildcard. If `in` ever carries an unknown `x` value (e.g., during power-up before signals settle), `casex` could incorrectly match a branch, masking a real bug. `casez` avoids this and is the safer default for priority-style decode logic.

**Q: What would change if this were rewritten as an if-else priority chain instead of `casez`?**
A: Functionally identical — same priority order, same outputs. The main practical differences are readability/style and how explicitly the priority order is expressed; most synthesis tools will produce equivalent priority-mux hardware either way.

**Q: Why not just use `|in` logic directly instead of a separate `valid` output?**
A: That's exactly what `valid` is — `assign valid = |in`. The point is exposing it as its own signal so downstream logic can explicitly check "is `code` meaningful" before acting on it, rather than silently trusting a `code` value that might correspond to no active input at all.

---

## 🔗 Links

- Repo: [github.com/Ujwal123434/100-days-of-rtl](https://github.com/Ujwal123434/100-days-of-rtl)