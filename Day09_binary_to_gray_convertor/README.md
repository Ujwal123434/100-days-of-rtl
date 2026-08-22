## 🔍 Day 08 — Binary ↔ Gray Code Converter

### 📌 Question of the Day

#### 🧩 Problem Statement
Design a purely combinational module that converts a 4-bit binary number to its Gray code equivalent, and a 4-bit Gray code number back to its binary equivalent — both directions in the same module.

#### ⚙️ Module Declaration
```verilog
module binary_gray_converter (
    input  wire [3:0] bin_in,
    input  wire [3:0] gray_in,
    output wire [3:0] gray_out,
    output wire [3:0] bin_out
);
```

#### ✅ Requirements
- `gray_out` = Gray code equivalent of `bin_in`.
- `bin_out` = binary equivalent of `gray_in`.
- Purely combinational, no clock.

---

### 🧠 My Approach
- **Binary → Gray:** single XOR pass — `gray_out = bin_in ^ (bin_in >> 1)`. Each Gray bit is just the XOR of a binary bit with its neighbor to the left; all bits can be computed independently and simultaneously.
- **Gray → Binary:** built as a ripple chain of dependent `assign` statements:
  ```verilog
  bin_out[3] = gray_in[3];
  bin_out[2] = bin_out[3] ^ gray_in[2];
  bin_out[1] = bin_out[2] ^ gray_in[1];
  bin_out[0] = bin_out[1] ^ gray_in[0];
  ```
  Each bit depends on the *previously computed* binary bit, not the raw Gray input directly — so it can't be flattened into one parallel XOR expression the way binary→Gray can.

### 💡 Key Learning
The asymmetry between the two directions comes from how each code is *defined*:
- Gray bit `i` = XOR of binary bits `i` and `i+1` — a fixed, local relationship. All Gray bits can be derived in parallel from the binary input directly.
- Binary bit `i` = XOR of *all* Gray bits from the MSB down to `i` — a cumulative relationship. You can't get `bin_out[i]` without first knowing `bin_out[i+1]`, which is why decoding is inherently a serial/ripple dependency, even though it's still combinational (no clock).

This is a good one to have crisp in an interview — it's a classic "why is A easy but B needs a chain" question that tests whether you understand the math, not just the code.

### 🔬 Simulation Result
Verified in Icarus Verilog. Waveform confirms a full round-trip across all 7 tested vectors (`0000` through `1111`): `bin_in → gray_out`, then `gray_out` fed back as `gray_in → bin_out`, correctly reproduces the original binary value at every step.

### 🎤 Interview Q&A
**Q: Why is binary-to-Gray a single XOR pass but Gray-to-binary needs a chain?**
A: Each Gray bit depends only on two adjacent binary bits (a local, parallel relationship), so all Gray bits can be computed independently at once. Each binary bit, however, depends on the cumulative XOR of every Gray bit from the MSB down to that position — so decoding one bit requires the result of the bit above it, forcing a ripple/chain structure.

**Q: Is the Gray-to-binary ripple chain still combinational, or does it behave sequentially?**
A: Still purely combinational — there's no clock and no state. It just has a longer critical path than the binary-to-Gray direction because of the bit-to-bit dependency, which matters for timing closure at wider bit widths.

**Q: How would this scale to 8 or 16 bits?**
A: The binary-to-Gray line scales automatically since it's a vector operation. The Gray-to-binary chain would need to be rewritten with a `generate`/`for` loop parameterized by `WIDTH` rather than hand-written per bit.

### 🚧 Known Gap / Next Step
- No `parameter WIDTH` / generate-loop version — fixed at 4 bits, would need manual editing to scale.
- Testbench relies on waveform inspection only, not self-checking assertions.