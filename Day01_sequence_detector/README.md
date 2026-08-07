# Day 1 - Sequence Detector (Moore FSM) | Verilog RTL

## 📌 Problem Statement

Design a **Moore Finite State Machine (FSM)** in Verilog that detects the binary sequence **1011** in a serial input stream.

The detector must support **overlapping sequences**.

### Example

Input:
```

1011011

```

Output:
```

0001001

```

The detector asserts `detect = 1` whenever the sequence **1011** is received.

---

# 🎯 Objectives

- Design a Moore FSM.
- Detect the sequence **1011**.
- Allow overlapping sequence detection.
- Use synchronous reset.
- Implement state encoding using `localparam`.
- Verify functionality using a Verilog testbench.

---

# 📖 What is a Sequence Detector?

A sequence detector is a digital circuit that continuously monitors a serial input stream and asserts an output whenever a predefined sequence of bits appears.

Example:

Input:
```

110101101

```

The detector continuously checks every incoming bit to determine whether the target sequence has been received.

---

# 🧠 Moore FSM

In a **Moore Machine**, the output depends **only on the current state**, not directly on the input.

```
Output = f(Current State)
```

Therefore, the output changes only after entering the detection state.

---

# 🔄 Why Overlapping Detection?

Overlapping means that after detecting one sequence, the FSM **does not discard useful bits** that can begin another sequence.

Example:

```
Input

1011011

|----|
1011

   |----|
   1011
```

There are **two valid occurrences** of `1011`.

Instead of returning to the initial state after detection, the FSM transitions to the longest valid partial-match state.

---

# 🏗 State Description

| State | Meaning |
|------|-----------|
| S0 | No bits matched |
| S1 | Matched `1` |
| S2 | Matched `10` |
| S3 | Matched `101` |
| S4 | Matched `1011` (Sequence Detected) |

---

# 🔀 State Transition Table

| Current State | Input = 0 | Input = 1 | Detect |
|--------------|-----------|-----------|--------|
| S0 | S0 | S1 | 0 |
| S1 | S2 | S1 | 0 |
| S2 | S0 | S3 | 0 |
| S3 | S2 | S4 | 0 |
| S4 | S2 | S1 | 1 |

---

# 📂 Project Structure

```

Day-01-Sequence-Detector/
│
├── sequence_detector.v
├── tb_sequence_detector.v
├── waveform.png
└── README.md

```

---

# ⚙ RTL Design

The FSM consists of three parts:

### 1. State Register

Stores the current state.

```
always @(posedge clk)
```

Updates the state every rising edge of the clock.

---

### 2. Next-State Logic

Determines the next state based on:

- Current State
- Serial Input (`din`)

Implemented using:

```
always @(*)
```

---

### 3. Output Logic

Since this is a Moore FSM,

```
detect = 1
```

only when the FSM reaches state **S4**.

---

# 🔬 Testbench

The testbench performs the following tasks:

- Generates a clock.
- Applies synchronous reset.
- Streams serial input bits.
- Tests the sequence:

```

101101101101011

```

- Observes the `detect` signal.

---

# 📊 Expected Output

Input Stream:

```

101101101101011

```

Expected Detect:

```

000100100100001

```

`detect` becomes HIGH every time the sequence `1011` is detected.

---

# 📈 Simulation

Simulation confirms that:

- FSM correctly detects `1011`.
- Overlapping sequences are detected.
- Reset initializes the FSM correctly.
- Moore output changes only after entering the detection state.

---

# ⏱ Hardware Resources

The synthesized hardware contains:

- 5 FSM States
- State Register (Flip-Flops)
- Combinational Next-State Logic
- Output Logic

---

# 🚀 Applications

- Serial Communication Protocols
- Packet Detection
- Pattern Matching
- Data Stream Monitoring
- Communication Receivers
- Error Detection Systems

---

# 🎤 Interview Questions

## 1. What is a Sequence Detector?

A sequential circuit that detects a predefined bit pattern from a serial input stream.

---

## 2. Why did you use a Moore FSM?

Because the output depends only on the current state, making the output more stable and reducing glitches.

---

## 3. What is the difference between Moore and Mealy FSM?

| Moore | Mealy |
|--------|--------|
| Output depends only on state | Output depends on state and input |
| More stable output | Faster response |
| Usually one clock cycle later | Immediate response |

---

## 4. What is overlapping sequence detection?

After detecting one sequence, the FSM reuses the longest valid suffix that can also be the beginning of another sequence instead of restarting.

Example:

```

1011011

```

contains two occurrences of `1011`.

---

## 5. Why does S4 transition to S1 or S2 instead of S0?

To support overlapping detection.

The last received bits may already match the beginning of another sequence.

---

## 6. Why use `localparam`?

- Improves readability.
- Makes the code easier to maintain.
- Avoids using hard-coded state numbers.

---

## 7. Why use synchronous reset?

The state changes only on the rising edge of the clock, making the design more predictable and synthesis-friendly.

---

## 8. Why is `detect` HIGH only in S4?

Because this is a Moore FSM, where the output depends only on the current state.

---

## 9. How many states are required?

Five states:

- S0
- S1
- S2
- S3
- S4

---

## 10. Can this detector be implemented as a Mealy FSM?

Yes.

A Mealy FSM would require fewer states and can assert the output in the same clock cycle as the final input bit.

---

# 📚 Key Learnings

- Finite State Machines (FSM)
- Moore FSM Design
- State Encoding using `localparam`
- Synchronous Reset
- Next-State Logic
- Overlapping Sequence Detection
- Testbench Development
- RTL Simulation and Verification

---

# ✅ Status

- ✔ Moore FSM Implemented
- ✔ Overlapping Detection Supported
- ✔ Synchronous Reset Implemented
- ✔ Testbench Completed
- ✔ Simulation Verified

---

