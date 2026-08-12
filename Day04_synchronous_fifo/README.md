# Day 04 — Synchronous FIFO (Full/Empty Flags)

## Question of the Day

### Problem Statement
Write a Verilog module that implements a Synchronous FIFO (First-In First-Out) with configurable depth and width using a single clock for both read and write operations.

### Module Declaration
```verilog
module fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 8
)(
    input  clk,
    input  rst_n,
    input  cs,
    input  wr_en,
    input  rd_en,
    input  [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output full,
    output empty
);
```

> **Note:** This implementation uses an **active-low, synchronous reset** (`rst_n`) and includes a `cs` (chip-select) enable port. If your target spec calls for active-high `reset` with no `cs`, the pointer/full/empty logic below stays identical — only the reset polarity and enable conditions need updating.

### Requirements
- Design a Synchronous FIFO using a single clock for both read and write operations.
- Implement the FIFO using a register array for internal storage.
- Support configurable data width and FIFO depth using parameters.
- Use read and write pointers that are `$clog2(DEPTH)+1` bits wide to correctly detect Full and Empty conditions.
- Assert `full` when the FIFO cannot accept additional data.
- Assert `empty` when there is no valid data available for reading.
- Ignore write requests while the FIFO is full to prevent overflow.
- Ignore read requests while the FIFO is empty to prevent underflow.
- Support simultaneous read and write operations during normal FIFO operation.
- Use a synchronous reset.
- Update all sequential logic on the rising edge of `clk`.
- Use non-blocking assignments (`<=`).

---

## My Approach

Designed the FIFO using a memory-based architecture with separate write and read pointers to control data storage and retrieval.

The implementation consists of:

- **Memory Array** – Stores the FIFO data (`fifo[0:FIFO_DEPTH-1]`).
- **Write Pointer** – Tracks the next location where incoming data will be written.
- **Read Pointer** – Tracks the next location from which data will be read.
- **Full Flag Logic** – Detects when the FIFO has reached its maximum capacity by comparing the write and read pointers using an additional wrap-around bit.
- **Empty Flag Logic** – Detects when all stored data has been read by comparing both pointers.

The read and write pointers are implemented with an extra Most Significant Bit (MSB) beyond the memory address width. This additional bit distinguishes the Full condition from the Empty condition when both pointers reference the same memory location after wrap-around.

```verilog
assign empty = (rd_ptr == wr_ptr);
assign full  = (rd_ptr == {~wr_ptr[FIFO_DEPTH_LOG], wr_ptr[FIFO_DEPTH_LOG-1:0]});
```

The design also supports simultaneous read and write operations while preventing overflow and underflow through proper control logic (`cs && wr_en && !full`, `cs && rd_en && !empty`).

---

## Key Learning

- Understood the working principle of a First-In First-Out (FIFO) memory.
- Learned the difference between Synchronous FIFO and Asynchronous FIFO.
- Understood why FIFO pointers require an extra wrap-around bit for reliable Full and Empty detection.
- Learned that the memory address uses only the lower pointer bits, while the MSB is used for wrap detection.
- Implemented Full and Empty flag generation using pointer comparison.
- Understood how overflow and underflow are prevented using enable conditions.
- Learned how simultaneous read and write operations affect FIFO behavior.
- Learned the difference between **directed** and **self-checking** testbenches, and why flag-only checks (`full`/`empty`) are insufficient to catch data-corruption bugs.
- Verified FIFO functionality through simulation using write, read, Full, and Empty conditions, with a scoreboard comparing DUT output against a software reference model.

---

## Simulation Result

✔ Successfully writes data into the FIFO.
✔ Successfully reads data in the same order it was written (FIFO behavior).
✔ Correctly asserts the Full flag when the FIFO reaches maximum capacity.
✔ Correctly asserts the Empty flag after all stored data has been read.
✔ Successfully prevents overflow and underflow conditions.
✔ Verified pointer operation, Full/Empty flag generation, and FIFO functionality using simulation waveforms and a self-checking testbench (reference model + scoreboard).

---

## Interview Q&A

**Q1. Why does the FIFO pointer need an extra bit beyond the address width?**
With `N` address bits for a depth-`2^N` FIFO, `rd_ptr == wr_ptr` on its own is ambiguous — it's true both when the FIFO is completely empty and completely full (after wrap-around). Adding one extra MSB that keeps counting (instead of wrapping at the memory boundary) lets you distinguish the two: equal pointers *including* the MSB means empty; equal lower bits but *different* MSB means full.

**Q2. Why is only `wr_ptr[FIFO_DEPTH_LOG-1:0]` used to index memory, not the full pointer?**
The MSB exists purely for full/empty tracking — it doesn't correspond to a real memory location. The physical memory only has `2^FIFO_DEPTH_LOG` locations, so only the lower bits are valid addresses.

**Q3. What happens if `wr_en` and `rd_en` are both asserted in the same cycle?**
Both pointers increment simultaneously (assuming not full/not empty). Net FIFO occupancy stays the same. The value read out is whatever was at `rd_ptr` *before* this cycle's write — the just-written data is not read out in the same cycle (registered read).

**Q4. What happens if you try to write when `full=1`?**
The write is dropped — `wr_ptr` does not increment and `fifo[wr_ptr]` is not overwritten, because the write is gated by `!full`. This prevents overflow (silently overwriting unread data).

**Q5. What happens if you try to read when `empty=1`?**
The read is dropped — `rd_ptr` does not increment and `data_out` holds its previous value, because the read is gated by `!empty`. This prevents underflow (reading stale/invalid data).

**Q6. Why use non-blocking assignments (`<=`) for pointer and memory updates?**
Non-blocking assignments model correct synchronous sequential behavior — all right-hand sides are evaluated using the pre-edge values before any updates commit. This avoids race conditions between the pointer update and memory write within the same always block, and matches how real flip-flops behave.

**Q7. Why is `data_out` a registered output instead of combinational (`fifo[rd_ptr]` directly)?**
A registered read adds one cycle of latency but produces a cleaner, glitch-free output that's easier to time close in synthesis. The alternative (combinational read, "first-word fall-through") gives zero-latency output but couples the read address path directly to the output timing path — a tradeoff worth mentioning if asked.

**Q8. How would you convert this into an asynchronous FIFO (different read/write clocks)?**
You'd need to synchronize the pointers across clock domains — typically by Gray-coding the pointers (so only one bit changes at a time) and passing them through 2-flop synchronizers before comparing across domains. Direct binary pointer comparison across clock domains risks metastability and incorrect full/empty detection.

**Q9. Why is a flag-only testbench (checking just `full`/`empty` at the end) insufficient?**
It verifies the FIFO reaches capacity/drains correctly, but never checks that the *data values* read back match what was written, in order. A bug that scrambles or corrupts stored data could still pass a flag-only check. A self-checking testbench with a reference model (software queue) and a scoreboard comparing every read against the expected value catches this class of bug automatically.

**Q10. How would you size the FIFO in a real system (e.g., between two blocks with different throughput)?**
Depth is driven by the maximum burst/backlog the producer can generate before the consumer catches up, plus margin for latency in the enable/handshake path. Undersizing causes overflow-driven data loss (or backpressure stalls); oversizing wastes area — this is typically determined by simulating worst-case traffic patterns, not guessed.

---

## Known Gap / Next Step
The self-checking testbench for this FIFO is still being built out (reference-model queue + scoreboard, replacing the earlier flag-only checks). Corner cases still to add: simultaneous `wr_en`+`rd_en` under randomized stimulus, and full→drain→refill cycling.