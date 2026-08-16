# 🔍 Day 06 — UART Transmitter (8-N-1, No Parity)

## 📌 Question of the Day

### 🧩 Problem Statement
Design a UART transmitter that serializes an 8-bit byte onto a single `tx` line following the standard 8-N-1 framing format (1 start bit, 8 data bits LSB-first, 1 stop bit, no parity), driven by an external `baud_tick` pulse rather than a full baud-rate generator.

### ⚙️ Module Declaration
```verilog
module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    input  wire       baud_tick,
    output reg        tx,
    output reg        tx_busy
);
```

### ✅ Requirements
- Synchronous active-high reset (`rst`).
- `tx_start` is a pulse that begins a transmission; `tx_data[7:0]` is the byte to send.
- `tx` idles high; `tx_busy` is high for the entire duration of a transmission.
- Frame format: **1 start bit (low) → 8 data bits, LSB first → 1 stop bit (high)**.
- `baud_tick` (1-cycle pulse, externally generated) tells the FSM when to advance to the next bit — no internal baud-rate generator required.
- While `tx_busy` is high, `tx_start` must be ignored (no restart mid-transmission).

---

## 🧠 My Approach

Implemented as a 4-state Moore FSM (`IDLE → START → DATA → STOP`) combined with a bit-indexed shift-out datapath, rather than one state per data bit.

The implementation consists of:

- **State register** – `IDLE`, `START`, `DATA`, `STOP`, encoded with a 2-bit `localparam` set.
- **`data_reg`** – latches `tx_data` on `tx_start` in `IDLE`, holds the byte being shifted out for the rest of the frame.
- **`bit_count`** – tracks which data bit (`0` to `7`) is currently being driven onto `tx`; used to detect when all 8 bits have been sent (`bit_count == 7`) rather than hardcoding 8 separate DATA states.
- **`tx_busy` gating** – asserted the moment `tx_start` is accepted in `IDLE`, held through `START`/`DATA`/`STOP`, and only cleared one `baud_tick` after the stop bit completes — this also structurally protects against restarting mid-frame, since `tx_start` is only ever checked inside the `IDLE` branch.

```verilog
DATA: begin
    tx <= data_reg[bit_count];
    if (baud_tick) begin
        if (bit_count == 4'd7)
            state <= STOP;
        else
            bit_count <= bit_count + 1'b1;
    end
end
```

Each state holds its output level for a full `baud_tick` period before advancing — `tx` is driven combinationally off `data_reg[bit_count]` inside `DATA`, and the bit index only increments on the tick, ensuring each bit occupies exactly one baud period on the line.

---

## 💡 Key Learning

- Learned how to fuse FSM control logic (Day 1–3 territory) with a datapath shift/index register (Day 4 territory) into a single design — UART TX is a natural combination of both skills.
- Understood why a bit-counter + index (`data_reg[bit_count]`) is preferable to one hardcoded state per data bit — it keeps the state space small (4 states regardless of data width) and scales cleanly if the frame width changes.
- Learned why `tx_busy` should only be gated in `IDLE` — placing the `tx_start` check inside a single state, rather than checking it globally, is what structurally guarantees a mid-frame restart is impossible, without needing extra guard logic elsewhere.
- Understood the practical reason to decouple `baud_tick` generation from the FSM itself — separating "when to advance" from "what to do" keeps the protocol/FSM logic testable independently of clock-division details.
- Learned to verify serial bit-ordering by hand: for LSB-first transmission, `tx_data[0]` is sent right after the start bit, and `tx_data[7]` is sent last, immediately before the stop bit — the reverse of how the byte is normally read.

---

## 🔬 Simulation Result

For `tx_data = 8'b10110010` (LSB-first send order: `0,1,0,0,1,1,0,1`):

✔ Start bit correctly drives `tx` low immediately upon entering `START`.
✔ All 8 data bits shift out on `tx` in the correct LSB-first order, one bit per `baud_tick`, verified by hand-tracing tick-by-tick against `data_reg[bit_count]`.
✔ Stop bit correctly drives `tx` high for one full `baud_tick` period before returning to idle.
✔ `tx_busy` asserts the instant `tx_start` is accepted and deasserts exactly one `baud_tick` after the stop bit completes — not early, not late.
✔ `tx_start` is structurally ignored while `tx_busy=1`, since the `case` statement only evaluates `tx_start` inside the `IDLE` branch.
✔ Verified via waveform trace against a manual bit-by-bit expected sequence for a single 8-bit test pattern.

---

## 🎤 Interview Q&A

**Q1. Why use a bit-counter with `data_reg[bit_count]` instead of 8 separate DATA states?**

A counter-indexed shift keeps the FSM at a fixed 4 states regardless of data width — if the protocol later needed 16-bit words, only the counter width and terminal count (`bit_count == 15`) would change, not the state machine structure. Hardcoding 8 states doesn't scale and duplicates logic that's otherwise identical bit-to-bit.

**Q2. How does this design guarantee `tx_start` can't restart a transmission mid-frame?**

`tx_start` is only checked inside the `IDLE` branch of the state case statement. Since the FSM can't be in `IDLE` and `START`/`DATA`/`STOP` simultaneously, there's no code path where `tx_start` is evaluated outside of `IDLE` — it's structurally impossible, not just logically discouraged.

**Q3. Why does `tx_busy` deassert one tick after the stop bit, rather than immediately when entering STOP?**

The stop bit needs to occupy a full baud period on the line for a receiver to correctly detect it (and for back-to-back frames to have proper line separation). Dropping `tx_busy` — or allowing a new `tx_start` — before that period completes would truncate the stop bit's actual transmitted duration.

**Q4. Why decouple `baud_tick` from an internal baud-rate generator instead of building one into this module?**

Separating the timing generator from the protocol FSM keeps each piece independently testable — the FSM logic can be verified with any tick source (even a simple periodic pulse in a testbench) without needing to also get clock-division math correct. In a real design, `baud_tick` would come from a separate, reusable baud-rate generator module shared across multiple UART instances if needed.

**Q5. LSB-first vs MSB-first — does it matter for correctness, and how would you know which to use?**

It doesn't affect correctness as long as transmitter and receiver agree — but it does have to match the protocol spec exactly, since bit order is not self-describing on the wire. Standard UART (RS-232-style) is LSB-first by convention, which is why this design shifts `tx_data[0]` out first.

---

## 🚧 Known Gap / Next Step
Testbench currently exercises only a single data pattern (`8'b10110010`) with one clean transmission and no self-checking assertions (waveform-verified by hand). Next steps: add `8'h00` and `8'hFF` edge-case patterns, a self-checking scoreboard comparing the serialized `tx` stream against an expected bit sequence, and an explicit test asserting that `tx_start` pulsed during `tx_busy=1` has no effect on the in-flight frame.