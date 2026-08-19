🔍 Day 05b — Parameterized Synchronous LIFO Stack

📌 Question of the Day

　　🧩 Problem Statement
Design a parameterized synchronous LIFO (stack) with configurable data width and depth. The stack must support push and pop operations, correctly report full/empty status, and gracefully handle the edge case of simultaneous push and pop in the same cycle.

　　⚙️ Module Declaration
```verilog
module lifo_stack #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4
)(
    input clk,
    input rst,
    input push,
    input pop,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output full,
    output empty
);
```

　　✅ Requirements
- Synchronous active-high reset
- Push blocked when `full`, pop blocked when `empty`
- LIFO ordering: last data pushed is first data popped
- Simultaneous push+pop handled without corrupting stack state
- Depth need not be a power of 2

🧠 My Approach
Used a `ptr` register as a circular write/read index sized only to `$clog2(DEPTH)` bits, and a separate `count` register sized to `$clog2(DEPTH+1)` bits to track true occupancy for full/empty detection. `ptr` intentionally wraps modulo `DEPTH` on push and pop — since it's only ever used as an array index, the wraparound is self-consistent and never produces an incorrect address. `count` is the single source of truth for full/empty, decoupled entirely from `ptr`'s bit width. Simultaneous push+pop is handled as a special case: if the stack isn't empty, the top element is swapped in place (`ptr`/`count` unchanged); if the stack is empty, it degrades to a plain push.

💡 Key Learning
A circular pointer used purely as an array index can be sized smaller than the pointer used for occupancy tracking — as long as full/empty decisions are made from a separately, correctly-sized counter rather than from the index itself. Conflating the two (sizing the index to also detect full/empty) is what forces tricks like the FIFO's extra-MSB approach from Day 4; splitting the responsibilities here avoids needing that trick at all.

🔬 Simulation Result
Waveform confirms correct LIFO ordering: pushed sequence `0A → 14 → 1E` (with a 4th push `28` correctly blocked once `full` asserts) pops back out in reverse as `1E → 14 → 0A`, with `empty` correctly reasserting once the stack drains.

🎤 Interview Q&A

Q: Why is your pointer width `$clog2(DEPTH)` instead of `$clog2(DEPTH)+1` like a typical FIFO pointer?
A: Because `ptr` here is used purely as a circular array index (mod DEPTH), not as a comparator for full/empty — that job is done by a separately-sized `count` register. A FIFO pointer often needs the extra bit because read/write pointers are compared directly to detect wraparound; here, `count` removes that need entirely.

Q: What happens if push and pop are asserted in the same cycle?
A: If the stack isn't empty, the top-of-stack element is overwritten with the new `din` value and the popped `dout` reflects the old top — net stack size stays the same. If the stack is empty, pop is invalid, so it behaves as a plain push.

Q: Why is `count` sized to `$clog2(DEPTH+1)` and not `$clog2(DEPTH)`?
A: `count` needs to represent every value from `0` to `DEPTH` inclusive (DEPTH+1 possible values), which requires one extra bit beyond what's needed to represent indices `0` to `DEPTH-1`.

🚧 Known Gap / Next Step
Testbench is directed and not self-checking (visual waveform inspection only) — consistent with the ongoing gap from Days 3–4. It also doesn't exercise the simultaneous push+pop path or the push-while-full/pop-while-empty boundary cases. Next step: build a scoreboard testbench with a software reference stack model, driven by a sequence that specifically hits simultaneous push+pop and both boundary conditions.