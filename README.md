# Dual IS: Instruction Set Modality for Efficient Instruction Level Parallelism

**Introduction**

To achieve high performance, scalability, and energy efficiency in modern embedded systems, processors must efficiently handle both control-intensive and data-parallel workloads. Traditional strategies for exploiting instruction-level parallelism (ILP) have included either statically scheduled Very Long Instruction Word (VLIW) architectures or dynamically scheduled superscalar processors. While VLIW designs benefit from simplified hardware and reduced scheduling complexity through compiler-managed instruction packing, they often suffer from poor ILP utilization in sequential workloads, resulting in increased code size and instruction stream energy due to excessive no-operation (NOP) instructions. Superscalar processors address this by performing complex hardware-based dynamic scheduling, but at the cost of increased silicon area, power consumption, and control logic complexity.

To bridge this trade-off, we propose a Dual-IS processor architecture that tightly integrates a standard RISC-V core with a Transport Triggered Architecture (TTA)-based multi-issue execution datapath. RISC-V, being a modular, open-source, and extensible ISA, provides a lightweight base suitable for reactive and control-dominated tasks, with a clean separation between fetch/decode stages and backend execution. TTA, on the other hand, follows an exposed datapath model where computation is orchestrated by explicitly programmed data movements, enabling fine-grained control over ILP and efficient scheduling of independent operations. The instruction model of TTA avoids centralized instruction decoding and control, allowing for flexible and low-power data transport among function units (FUs).

The Dual-IS pipeline begins with a conventional RISC-V frontend (IF, ID stages) which handles instruction fetch and decoding. A dependency checker evaluates groups of four RISC-V instructions to identify data dependencies using static register-read/write analysis. If the instructions are independent, they are transformed into move operations and dispatched over an explicit interconnection network to the TTA backend, which comprises dedicated ALUs, load-store units (LSUs). This enables parallel execution of instructions without dynamic hazard detection logic or scoreboard mechanisms. If dependencies are detected, instructions are routed back to the single-issue RISC-V execution pipeline, ensuring correct execution order.

This architecture allows selective offloading of compute-intensive, parallelizable instruction sequences to the TTA execution engine, which performs efficient ILP exploitation at compile time. The shared memory interface, register file, unified control logic, and reusability of RISC-V frontend infrastructure significantly reduce the hardware cost of integration. Moreover, the TTA backend’s modular nature makes it easily extensible for domain-specific accelerators (e.g., DSP blocks, cryptographic units) while retaining general-purpose programmability.

Key benefits of Dual-IS include:

* Energy Efficiency: Reduced dynamic power through simplified control logic in TTA and statically scheduled execution.

* Area Efficiency: Lower area overhead compared to full superscalar hardware due to modular datapath and instruction decomposition.

* Code Density Optimization: Compact execution paths for control-heavy code via RISC-V, with high-throughput scheduling of compute blocks via TTA.

* Compiler Flexibility: The exposed datapath model of TTA allows the compiler to make optimal scheduling, FU allocation, and transport decisions.

* Extensibility: RISC-V's modularity combined with TTA's loosely coupled datapath allows the system to scale based on workload requirements or application-specific customization.

This hybrid execution model provides a flexible platform for optimizing performance, energy, and code size dynamically, depending on the workload characteristics, making it well-suited for next-generation embedded SoCs that operate under tight area and energy budgets.

**Related Work**

Prior research in dual-mode and multi-ISA processor architectures has explored several strategies to combine the benefits of different execution models to improve performance, energy efficiency, and code density. FuMicro \[1\] introduces a fused microarchitecture that supports both in-order superscalar and VLIW execution within a unified pipeline, with mode switching handled entirely in software. While this simplifies hardware and enables performance improvements for compute-intensive code segments, it retains a shared ISA and requires compiler support for VLIW code generation. Similarly, a unified processor architecture with RISC and DSP modes has been proposed \[2\], allowing instruction-by-instruction switching through hierarchical encoding. This approach minimizes hardware overhead and leverages a distributed register organization optimized for stream processing, though it lacks explicit control support in DSP mode.

Alternative strategies address the trade-off between code size and execution time. Selective code transformation \[3\] enables dynamic switching between reduced and full instruction sets in dual-ISA processors, providing fine-grained optimization for embedded systems with strict memory and real-time constraints. In contrast to these dual-ISA strategies, composite-ISA cores \[4\] aim to replicate the flexibility of multi-ISA heterogeneity by using a single, expansive ISA superset, allowing runtime ISA adaptation while maintaining performance and energy efficiency across diverse application phases.

From a low-power embedded systems perspective, work such as HAMSA-DI \[5\] demonstrates how a dual-issue, in-order RISC-V processor with Xpulp extensions can achieve substantial improvements in performance and energy efficiency without the need for additional cores or instruction sets. While this approach focuses on enhancing scalar RISC-V performance, it does not explicitly address ILP exploitation through alternative datapath architectures like VLIW or exposed datapath models.

Our proposed Dual-IS architecture builds on these foundations by integrating a standard RISC-V frontend with a Transport Triggered Architecture (TTA) backend, allowing instruction-level parallelism to be exploited only when instruction dependencies allow. Unlike \[1\] and \[2\], we utilize an exposed datapath and a SIMD lane based ALU cluster with shared memory interface and register file for the TTA side, offering finer control over resource utilization. Compared to \[3\] and \[4\], our design does not rely on ISA encoding modifications or supersets but instead leverages microcode-driven translation and static scheduling to dispatch independent instruction groups to the TTA datapath. This yields a balance between flexibility, energy efficiency, and performance across control- and data-dominated workloads while maintaining a consistent memory interface and minimal area overhead.

**Implementation**

This work implements a hybrid processor core that integrates a standard 32-bit RISC-V pipeline with a Transport Triggered Architecture (TTA)-style datapath. The design leverages both instruction-driven (RISC-V) and transport-triggered (TTA) execution models to exploit instruction-level parallelism and fine-grained hardware control. The core is designed in Verilog with parameterized memory and register file widths and supports both scalar and pseudo-SIMD operation over four functional lanes (N \= 4).

#### 1\. Architecture Overview

The top-level module `riscv` operates with two primary execution modes:

* RISC-V Mode (`mode = 0`): Executes standard RISC-V instructions using traditional decoding, register fetch, and execution.

* TTA Mode (`mode = 1`): Allows instruction-level micro-control over data movements to functional units, similar to SIMD where each lane performs a potentially independent operation.

Switching between these modes is dynamically controlled using a `switch` signal based on data dependency analysis done in hardware.

#### 2\. Instruction and Data Memory

* The `instruction_mem` and `data_mem` arrays are both initialized with `MEMLEN` entries (default 10).

* Four instructions are fetched in parallel and stored in the `fused_instr` array to simulate SIMD-style parallel decode and dispatch.

* The design uses a 4-lane setup (`N = 4`), where each lane can independently fetch operands, trigger operations, and store results.

#### 3\. Register File and Pipeline

* The scalar register file (`x`) is 32 entries wide, each 32-bits.

* Instruction decoding splits immediate generation, operand fetch (`rs1`, `rs2`), and destination register identification (`rd`) across each of the four lanes.

* Basic pipeline stages (`if_id`, `id_ex`, `ex_mem`, and `mem_wb`) are maintained for control and operand forwarding logic.

#### 4\. Functional Units

Each arithmetic and logic unit is instantiated in a vectorized fashion over 4 lanes:

* Add/Sub Units: Triggered using `trigger_add[i]` or `trigger_sub[i]` per lane.

* Logical Units: Perform AND, OR, XOR operations conditionally per lane.

* Shift Units: Perform SRL and SRA with support for signed shifts.

* Comparison Unit: Implements SLT using signed comparisons.

All units execute conditionally based on trigger signals, mimicking TTA-style fine-grained control.

#### 5\. Instruction Decoding and Execution Control

A dynamic mode switch is employed:

* If `switch == 1` or `mode == 1`, the core decodes and dispatches TTA-style instructions.

* Dependency detection logic determines whether RISC-V instruction fusion is possible, and if not, dispatches independent TTA transport instructions.

* This hybrid model enables both sequential scalar execution and parallel vector-style execution.

The decoder supports:

* R-type: ADD, SUB, AND, OR, XOR, SLT, SRL, SRA

* I-type: ADDI, ANDI, ORI, XORI, SLTI, SRLI, SRAI

* Memory: LW and SW

TTA-like instructions are generated internally and mapped to trigger signals and operand ports (`src1`, `src2`, `dest`).

#### 6\. Data Path and Operand Transport

The core explicitly routes data using hardware transport registers:

* `src1`, `src2`: Source operand registers

* `dest`: Destination register

* `trigger_<unit>[i]`: Triggers the operation for lane `i`

* Operands and results are buffered for each lane, maintaining transport isolation.

This matches the core principle of TTA—moving data between functional units over a transport bus, rather than executing encoded opcodes.

#### 7\. Instruction Fusion and Dependency Check

The design includes a primitive instruction fusion checker:

* Instructions are checked for read-after-write (RAW) hazards.

* If dependencies are detected, execution defaults to scalar RISC-V; otherwise, the core attempts to fuse instructions into 4-lane transport operations.

* This boosts parallelism without requiring external software optimization.

#### 8\. Parameterization and Simulation Readiness

* The core uses parameterized memory (`MEMLEN`) and register width (`XLEN`) for easy scaling.

* All input/output interfaces are simulation-ready and can be integrated with testbenches for program loading and result verification.

* Memory initialization and register dumping can be added externally to monitor execution.

**Instructions Handled**

LUI AUIPC JAL JALR BEQ BNE BLT BGE BLTU BGEU LB LH LW LBU LHU SB SH SW ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI ADD SUB SLL SLT SLTU XOR SRL SRA OR AND

**Novelty/Use case**

The proposed architecture introduces a novel hybrid execution model combining the conventional RISC-V pipeline with a Transport Triggered Architecture (TTA) datapath consisting of four specialized instruction-based hardware units. These units are independently capable of executing `ADD/SUB/AND/OR`, `LW`, `SW`, and logical operations in a parallel fashion, resembling a SIMD lane structure. A key innovation lies in the hardware-level dependency detection mechanism: runtime data hazards are analyzed in the control logic, and based on the operand readiness and instruction dependencies, the processor dynamically switches from RISC-V execution to a TTA-style transport-execution mode. This dual-mode operation enables higher instruction-level parallelism while retaining compatibility with a standard RISC-V ISA, reducing stall cycles and improving overall throughput in data-heavy workloads.

### Advantages

1. Instruction-Level Parallelism (ILP):

   * The TTA lanes allow multiple instructions (ADD, SUB, LW, SW, etc.) to be executed in parallel when dependencies are absent, exploiting ILP.

   * Efficient for loop-based workloads with minimal branching and high data reuse.

2. Dynamic Dependency Resolution in Hardware:

   * The processor checks register dependencies at runtime and dynamically decides to switch to TTA mode, reducing stalls.

   * This avoids the need for compiler-based static scheduling or software-inserted NOPs.

3. Reduced Control Overhead in TTA Mode:

   * In TTA mode, control signals are explicit in the instruction—no need for complex decode logic.

   * Simpler control paths can reduce power consumption during steady-state dataflow operations.

4. SIMD-like Lane Utilization:

   * The 4 independent hardware execution units resemble SIMD lanes but allow heterogeneity (e.g., a lane for ADD, another for LW), offering more flexibility than traditional SIMD.

   * Useful for irregular compute patterns or memory-heavy code.

5. Reconfigurability and FPGA-Friendly:

   * Modular design makes it easy to scale lanes or reconfigure them for different instruction sets.

   * FPGA prototyping supports experimentation with various datapath widths and unit mixes.

### Disadvantages

1. Area Overhead:

   * Instantiating 4 independent hardware units (ADD, SUB, LW, SW) incurs significant area and resource usage compared to a unified ALU with control multiplexing.

   * Potential underutilization if the instruction mix is skewed toward certain operations.

2. Control Logic Complexity for Switching:

   * Dependency checking and mode switching require additional FSMs or hazard detection units, increasing design complexity.

   * Adds more testing and verification overhead compared to single-mode execution.

3. Instruction Transport and memory Cost in TTA:

   * TTA requires explicit operand transport via bus interconnects or register move instructions, which can increase instruction count and control bus congestion.

   * For shorter programs, overhead may outweigh the benefit of parallel execution.

**Synthesis Reports**

**RISCV part:**

**Timing Summary:**  
\===========================================================================  
report\_tns  
\============================================================================  
tns 0.00

\===========================================================================  
report\_wns  
\============================================================================  
wns 0.00

\===========================================================================  
report\_worst\_slack \-max (Setup)  
\============================================================================  
worst slack 17.28

\===========================================================================  
report\_worst\_slack \-min (Hold)  
\============================================================================  
worst slack 0.08  
**Area Report:**  
63\. Printing statistics.

\=== riscv \===

   Number of wires:                188  
   Number of wire bits:            188  
   Number of public wires:          54  
   Number of public wire bits:      54  
   Number of memories:               0  
   Number of memory bits:            0  
   Number of processes:              0  
   Number of cells:                187  
     sky130\_fd\_sc\_hd\_\_a21o\_2         2  
     sky130\_fd\_sc\_hd\_\_a21oi\_2        5  
     sky130\_fd\_sc\_hd\_\_a2bb2o\_2       1  
     sky130\_fd\_sc\_hd\_\_a31o\_2         2  
     sky130\_fd\_sc\_hd\_\_a31oi\_2        1  
     sky130\_fd\_sc\_hd\_\_and2\_2         6  
     sky130\_fd\_sc\_hd\_\_and2b\_2        6  
     sky130\_fd\_sc\_hd\_\_and3\_2        10  
     sky130\_fd\_sc\_hd\_\_and4\_2        11  
     sky130\_fd\_sc\_hd\_\_buf\_1         21  
     sky130\_fd\_sc\_hd\_\_conb\_1         1  
     sky130\_fd\_sc\_hd\_\_dfxtp\_2       53  
     sky130\_fd\_sc\_hd\_\_inv\_2          3  
     sky130\_fd\_sc\_hd\_\_mux2\_2         9  
     sky130\_fd\_sc\_hd\_\_nand2\_2        5  
     sky130\_fd\_sc\_hd\_\_nand3\_2        1  
     sky130\_fd\_sc\_hd\_\_nor2\_2        16  
     sky130\_fd\_sc\_hd\_\_nor3\_2         2  
     sky130\_fd\_sc\_hd\_\_o211a\_2        1  
     sky130\_fd\_sc\_hd\_\_o21a\_2         1  
     sky130\_fd\_sc\_hd\_\_o21ba\_2        1  
     sky130\_fd\_sc\_hd\_\_o22a\_2         1  
     sky130\_fd\_sc\_hd\_\_or2\_2          2  
     sky130\_fd\_sc\_hd\_\_or2b\_2         1  
     sky130\_fd\_sc\_hd\_\_or3\_2          1  
     sky130\_fd\_sc\_hd\_\_or4\_2          8  
     sky130\_fd\_sc\_hd\_\_or4bb\_2        1  
     sky130\_fd\_sc\_hd\_\_xnor2\_2        6  
     sky130\_fd\_sc\_hd\_\_xor2\_2         9

   Chip area for module '\\riscv': 2263.420800

**DFF Report:**  
55\. Printing statistics.

\=== riscv \===

   Number of wires:                159  
   Number of wire bits:            328  
   Number of public wires:          12  
   Number of public wire bits:     119  
   Number of memories:               0  
   Number of memory bits:            0  
   Number of processes:              0  
   Number of cells:                230  
     $\_ANDNOT\_                      24  
     $\_AND\_                          1  
     $\_MUX\_                         49  
     $\_NAND\_                        15  
     $\_NOR\_                          2  
     $\_NOT\_                          2  
     $\_ORNOT\_                        2  
     $\_OR\_                          48  
     $\_XNOR\_                        15  
     $\_XOR\_                         19  
     sky130\_fd\_sc\_hd\_\_dfxtp\_2       53

**Power Report:**  
\===========================================================================  
 report\_power  
\============================================================================  
\======================= Typical Corner \===================================

Group                  Internal  Switching    Leakage      Total  
                          Power      Power      Power      Power (Watts)  
\----------------------------------------------------------------  
Sequential             1.06e-04   0.00e+00   4.54e-10   1.06e-04 100.0%  
Combinational          0.00e+00   0.00e+00   4.68e-10   4.68e-10   0.0%  
Clock                  0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%  
Macro                  0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%  
Pad                    0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%  
\----------------------------------------------------------------  
Total                  1.06e-04   0.00e+00   9.22e-10   1.06e-04 100.0%  
                         100.0%       0.0%       0.0%

**Layout:**  
![][image1]![][image2]

**RISCV \+ TTA Part:**  
**Version 1: 2 TTA Lanes, Version 2: 4 TTA Lanes**  
**Timing Report:**

**Version 1: Lesser TTA Lanes**

\===========================================================================  
report\_tns  
\============================================================================  
tns 0.00

\===========================================================================  
report\_wns  
\============================================================================  
wns 0.00

\===========================================================================  
report\_worst\_slack \-max (Setup)  
\============================================================================  
worst slack 14.48

\===========================================================================  
report\_worst\_slack \-min (Hold)  
\============================================================================  
worst slack 0.18

**Version 2: More TTA Lanes**  
\===========================================================================  
report\_tns  
\============================================================================  
tns 0.00

\===========================================================================  
report\_wns  
\============================================================================  
wns 0.00

\===========================================================================  
report\_worst\_slack \-max (Setup)  
\============================================================================  
worst slack 15.84

\===========================================================================  
report\_worst\_slack \-min (Hold)  
\============================================================================  
worst slack 0.16

**Area Report:**

**Version 1: Lesser TTA Lanes**

63\. Printing statistics.

\=== riscv \===

   Number of wires:                205  
   Number of wire bits:            205  
   Number of public wires:          55  
   Number of public wire bits:      55  
   Number of memories:               0  
   Number of memory bits:            0  
   Number of processes:              0  
   Number of cells:                203  
     sky130\_fd\_sc\_hd\_\_a2111o\_2       1  
     sky130\_fd\_sc\_hd\_\_a21bo\_2        2  
     sky130\_fd\_sc\_hd\_\_a21oi\_2       12  
     sky130\_fd\_sc\_hd\_\_a22o\_2         2  
     sky130\_fd\_sc\_hd\_\_a22oi\_2        1  
     sky130\_fd\_sc\_hd\_\_a31o\_2         1  
     sky130\_fd\_sc\_hd\_\_a31oi\_2        1  
     sky130\_fd\_sc\_hd\_\_a32o\_2         1  
     sky130\_fd\_sc\_hd\_\_a41o\_2         1  
     sky130\_fd\_sc\_hd\_\_and2\_2         7  
     sky130\_fd\_sc\_hd\_\_and2b\_2        1  
     sky130\_fd\_sc\_hd\_\_and3\_2        10  
     sky130\_fd\_sc\_hd\_\_and4\_2        10  
     sky130\_fd\_sc\_hd\_\_buf\_1         16  
     sky130\_fd\_sc\_hd\_\_dfxtp\_2       53  
     sky130\_fd\_sc\_hd\_\_inv\_2          5  
     sky130\_fd\_sc\_hd\_\_mux2\_2        10  
     sky130\_fd\_sc\_hd\_\_nand2\_2        7  
     sky130\_fd\_sc\_hd\_\_nor2\_2        19  
     sky130\_fd\_sc\_hd\_\_o2111a\_2       1  
     sky130\_fd\_sc\_hd\_\_o21a\_2         5  
     sky130\_fd\_sc\_hd\_\_o21ai\_2        3  
     sky130\_fd\_sc\_hd\_\_o21ba\_2        3  
     sky130\_fd\_sc\_hd\_\_o22a\_2         1  
     sky130\_fd\_sc\_hd\_\_o2bb2a\_2       2  
     sky130\_fd\_sc\_hd\_\_or2\_2          2  
     sky130\_fd\_sc\_hd\_\_or2b\_2         1  
     sky130\_fd\_sc\_hd\_\_or3\_2          2  
     sky130\_fd\_sc\_hd\_\_or3b\_2         1  
     sky130\_fd\_sc\_hd\_\_or4\_2          8  
     sky130\_fd\_sc\_hd\_\_xnor2\_2        2  
     sky130\_fd\_sc\_hd\_\_xor2\_2        12

   Chip area for module '\\riscv': 2419.820800

**Version 2: More TTA Lanes**

63\. Printing statistics.

\=== riscv \===

   Number of wires:                652  
   Number of wire bits:            652  
   Number of public wires:         113  
   Number of public wire bits:     113  
   Number of memories:               0  
   Number of memory bits:            0  
   Number of processes:              0  
   Number of cells:                650  
     sky130\_fd\_sc\_hd\_\_a2111o\_2       1  
     sky130\_fd\_sc\_hd\_\_a2111oi\_2      2  
     sky130\_fd\_sc\_hd\_\_a211o\_2        4  
     sky130\_fd\_sc\_hd\_\_a211oi\_2       2  
     sky130\_fd\_sc\_hd\_\_a21bo\_2        3  
     sky130\_fd\_sc\_hd\_\_a21o\_2        13  
     sky130\_fd\_sc\_hd\_\_a21oi\_2       21  
     sky130\_fd\_sc\_hd\_\_a221o\_2        1  
     sky130\_fd\_sc\_hd\_\_a22o\_2         9  
     sky130\_fd\_sc\_hd\_\_a22oi\_2        2  
     sky130\_fd\_sc\_hd\_\_a2bb2o\_2       4  
     sky130\_fd\_sc\_hd\_\_a311o\_2        1  
     sky130\_fd\_sc\_hd\_\_a31o\_2        11  
     sky130\_fd\_sc\_hd\_\_a31oi\_2        6  
     sky130\_fd\_sc\_hd\_\_a32o\_2         1  
     sky130\_fd\_sc\_hd\_\_a41o\_2         2  
     sky130\_fd\_sc\_hd\_\_a41oi\_2        1  
     sky130\_fd\_sc\_hd\_\_and2\_2        14  
     sky130\_fd\_sc\_hd\_\_and2b\_2        1  
     sky130\_fd\_sc\_hd\_\_and3\_2        26  
     sky130\_fd\_sc\_hd\_\_and3b\_2        2  
     sky130\_fd\_sc\_hd\_\_and4\_2        19  
     sky130\_fd\_sc\_hd\_\_and4b\_2        1  
     sky130\_fd\_sc\_hd\_\_and4bb\_2       2  
     sky130\_fd\_sc\_hd\_\_buf\_1         99  
     sky130\_fd\_sc\_hd\_\_dfxtp\_2      111  
     sky130\_fd\_sc\_hd\_\_inv\_2         12  
     sky130\_fd\_sc\_hd\_\_mux2\_2        78  
     sky130\_fd\_sc\_hd\_\_nand2\_2       37  
     sky130\_fd\_sc\_hd\_\_nand3\_2        3  
     sky130\_fd\_sc\_hd\_\_nand4\_2        4  
     sky130\_fd\_sc\_hd\_\_nor2\_2        28  
     sky130\_fd\_sc\_hd\_\_nor2b\_2        1  
     sky130\_fd\_sc\_hd\_\_nor3\_2         3  
     sky130\_fd\_sc\_hd\_\_nor4\_2         1  
     sky130\_fd\_sc\_hd\_\_o2111a\_2       2  
     sky130\_fd\_sc\_hd\_\_o211a\_2        5  
     sky130\_fd\_sc\_hd\_\_o211ai\_2       2  
     sky130\_fd\_sc\_hd\_\_o21a\_2        10  
     sky130\_fd\_sc\_hd\_\_o21ai\_2        4  
     sky130\_fd\_sc\_hd\_\_o21ba\_2        3  
     sky130\_fd\_sc\_hd\_\_o21bai\_2       1  
     sky130\_fd\_sc\_hd\_\_o221a\_2        6  
     sky130\_fd\_sc\_hd\_\_o22a\_2         8  
     sky130\_fd\_sc\_hd\_\_o2bb2a\_2       4  
     sky130\_fd\_sc\_hd\_\_o31a\_2         3  
     sky130\_fd\_sc\_hd\_\_o31ai\_2        4  
     sky130\_fd\_sc\_hd\_\_or2\_2         26  
     sky130\_fd\_sc\_hd\_\_or2b\_2         4  
     sky130\_fd\_sc\_hd\_\_or3\_2          4  
     sky130\_fd\_sc\_hd\_\_or4\_2          6  
     sky130\_fd\_sc\_hd\_\_or4b\_2         2  
     sky130\_fd\_sc\_hd\_\_or4bb\_2        1  
     sky130\_fd\_sc\_hd\_\_xnor2\_2       11  
     sky130\_fd\_sc\_hd\_\_xor2\_2        18

   Chip area for module '\\riscv': 6910.377600

**DFF Report:**

**Version 1: Lesser TTA Lanes**

55\. Printing statistics.

\=== riscv \===

   Number of wires:                333  
   Number of wire bits:            570  
   Number of public wires:          13  
   Number of public wire bits:     120  
   Number of memories:               0  
   Number of memory bits:            0  
   Number of processes:              0  
   Number of cells:                410  
     $\_ANDNOT\_                      46  
     $\_AND\_                         27  
     $\_MUX\_                         93  
     $\_NAND\_                        29  
     $\_NOR\_                         11  
     $\_NOT\_                          5  
     $\_ORNOT\_                        7  
     $\_OR\_                          76  
     $\_XNOR\_                         7  
     $\_XOR\_                         56  
     sky130\_fd\_sc\_hd\_\_dfxtp\_2       53

**Version 2: More TTA Lanes**  
55\. Printing statistics.

\=== riscv \===

   Number of wires:                846  
   Number of wire bits:           1599  
   Number of public wires:          38  
   Number of public wire bits:     413  
   Number of memories:               0  
   Number of memory bits:            0  
   Number of processes:              0  
   Number of cells:                967  
     $\_ANDNOT\_                     153  
     $\_AND\_                         27  
     $\_MUX\_                        163  
     $\_NAND\_                        37  
     $\_NOR\_                         33  
     $\_NOT\_                         17  
     $\_ORNOT\_                       17  
     $\_OR\_                         269  
     $\_XNOR\_                        27  
     $\_XOR\_                        113  
     sky130\_fd\_sc\_hd\_\_dfxtp\_2      111

**Power Report:**  
**Version 1: Lesser TTA Lanes**

\===========================================================================  
 report\_power  
\============================================================================  
\======================= Typical Corner \===================================

Group                  Internal  Switching    Leakage      Total  
                          Power      Power      Power      Power (Watts)  
\----------------------------------------------------------------  
Sequential             1.27e-04   1.26e-05   4.45e-10   1.39e-04  78.1%  
Combinational          2.74e-05   1.16e-05   5.41e-10   3.90e-05  21.9%  
Clock                  0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%  
Macro                  0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%  
Pad                    0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%  
\----------------------------------------------------------------  
Total                  1.54e-04   2.42e-05   9.86e-10   1.78e-04 100.0%  
                          86.4%      13.5%       0.0%

**Version 2: More TTA Lanes**  
\===========================================================================  
 report\_power  
\============================================================================  
\======================= Typical Corner \===================================

Group                  Internal  Switching    Leakage      Total  
                          Power      Power      Power      Power (Watts)  
\----------------------------------------------------------------  
Sequential             2.48e-04   1.57e-05   9.38e-10   2.63e-04  81.8%  
Combinational          4.14e-05   1.72e-05   1.79e-09   5.86e-05  18.2%  
Clock                  0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%  
Macro                  0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%  
Pad                    0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%  
\----------------------------------------------------------------  
Total                  2.89e-04   3.29e-05   2.73e-09   3.22e-04 100.0%  
                          89.8%      10.2%       0.0%

**Layout: (4 TTA Lanes)**  
**![][image3]![][image4]**

**Implementation Results on Basys3 FPGA:**

**RISCV part:**  
**Timing Summary:**  
**![][image5]**  
**Power:**  
**![][image6]**  
**Utilisation:**  
**![][image7]**  
**Elaborated Design Schematic:**  
**![][image8]**  
**Implementation Schematic:**  
**![][image9]**

**RISCV \+ TTA Part (More TTA Lanes):**  
**Timing Summary:**  
**![][image10]**  
**Power:**  
**![][image11]**  
**Utilisation:**  
**![][image12]**  
**Elaborated Design Schematic:**  
**![][image13]**  
**Implementation Schematic:**  
**![][image14]**

**TTA with 2 lanes is has comparable area and power with RISCV but has a higher propagation delay. TTA with 4 lanes has the least delay but very high area and power.**

**Simulation Waveforms**

**RISCV Mode:![][image15]**  
**![][image16]**

The Program Counter (pc) is observed to increment by 4 every clock cycle, correctly reflecting the sequential fetching of 32-bit instructions.

In the Instruction Fetch (IF) stage, the fetched instruction is stored in the if\_id\_instr register. As it progresses to the Decode (ID) stage, the instruction fields—such as opcode, rd, rs1, rs2, funct3, and imm—are separated and held in the id\_ex\_\* pipeline registers.

In this snapshot, the decoded instruction has:  
opcode indicating an ADD operation.  
rd \= x3 (destination register),  
rs1 \= x1, rs2 \= x0 and later x2 in subsequent instructions.

The source register values are forwarded to the Execute (EX) stage via alu\_src1 and alu\_src2:  
alu\_src1 is consistently 0x08, the value of register x1.  
alu\_src2 transitions from 0x00 to 0x06, representing the values of x0 and x2, respectively.

The ALU Result (alu\_result) corresponds to the sum of alu\_src1 and alu\_src2. The result changes from 0x08 (8 \+ 0\) to 0x0E (8 \+ 6), confirming correct arithmetic execution.

In the Write Back (WB) stage:  
write\_data carries the ALU result to be written back to the register file.  
The destination register x3 is updated accordingly.  
This is confirmed by observing the x\[3\] waveform, which holds 0x08 initially and then updates to 0x0E.

**![][image17]**

**TTA Mode:**  
**![][image18]![][image19]![][image20]**

The waveform snapshot illustrates the operation of the processor executing in Transport Triggered Architecture (TTA) mode. Initially, the processor behaves like a conventional RISC-V pipeline during the fetch and decode stages for four instructions. This is evident from the signals `if_id_pc`, `if_id_instr[0]` to `if_id_instr[3]`, and the corresponding decoded fields: `opcode`, `rd`, `rs1`, and `rs2`.

Once the decoding is completed, the `switch` signal transitions high, indicating the detection of independent instructions that can be dispatched in parallel—leveraging the explicit data movement model of TTA. At this point, the decoded instruction fields (`rd`, `rs1`, `rs2`) are forwarded to the TTA instruction set datapath.

* The operands from source registers `rs1` and `rs2` are transferred to the TTA datapath via `add_in1` and `add_in2` respectively.  
* These inputs are processed concurrently by the TTA’s arithmetic units.  
* The computation results are captured in the `alu_result` signal.  
* The results are then committed to the appropriate destination registers in the write-back stage.

From the waveform, the following register operations and final values are observed:

* x11 \= x2 \+ x0 → `0x06 + 0x00 = 0x06`  
* x15 \= x5 \+ x5 → `0x05 + 0x05 = 0x0A`  
* x25 \= x6 \+ x10 → `0x06 + 0x0A = 0x10`

**Applications/Future Work**

The proposed Dual-IS processor architecture—integrating a standard RISC-V core with a Transport Triggered Architecture (TTA) datapath—holds strong potential across a range of embedded system domains that require a balance of performance, energy efficiency, and flexibility.

#### Applications

* Edge AI and Signal Processing: Many edge applications, such as keyword spotting, object detection, and biosignal filtering, involve repetitive, compute-intensive workloads interspersed with control-dominated logic. The Dual-IS approach allows these compute-heavy kernels to be dispatched to the TTA backend, accelerating operations like matrix multiplications, convolutions, or FIR filtering, while maintaining tight control flow with the RISC-V core.

* IoT Devices and Wearables: Energy-constrained systems benefit from selective parallelism without a significant power or code size overhead. The modular TTA backend can accelerate short bursts of DSP-style processing (e.g., vibration or motion classification), while the compact RISC-V frontend handles peripheral interfacing and event-driven logic.

* Real-Time Systems: In real-time applications such as automotive control or radar signal processing, predictable execution and minimal jitter are critical. The statically scheduled dispatch to the TTA provides deterministic timing for instruction sequences, supporting hard real-time constraints.

#### Future Work

* Dynamic Scheduling Enhancements: While the current implementation relies on static hazard analysis and microcode-driven dispatch, future versions could incorporate limited dynamic scheduling within the TTA datapath to improve utilization under unpredictable workloads.

* Compiler Integration and Auto-Partitioning: Further development of compiler toolchains to automatically identify and annotate instruction groups suitable for TTA execution will streamline software development and maximize performance gains.

* Support for Floating-Point and Custom Instructions: Extending the TTA backend with vectorized floating-point ALUs or domain-specific accelerators (e.g., cryptographic units or FFT engines) would broaden the range of applicable workloads.

* Hardware Reconfigurability and Bitstream Updates: The architecture can be adapted for runtime reconfiguration on FPGA platforms, enabling different TTA datapath topologies or execution units to be loaded based on application phase or power budgets.

* Fine-Grained Performance Monitoring: Integration of performance counters and telemetry interfaces would facilitate dynamic workload migration decisions between the RISC-V and TTA backends based on actual instruction throughput, energy, or thermal metrics.

* Multi-core Scaling: The Dual-IS concept can be extended to multi-core systems, where clusters of RISC-V+TTA units collaboratively execute heterogeneous workloads, enabling system-level ILP and task parallelism.

**References**

\[1\] Hou, Y., He, H., Yang, X., Guo, D., Wang, X., Fu, J. and Qiu, K., 2016\. FuMicro: A Fused Microarchitecture Design Integrating In‐Order Superscalar and VLIW. *VLSI Design*, *2016*(1), p.8787919.  
\[2\] Lin, T.J., Chao, C.M., Liu, C.H., Hsiao, P.C., Chen, S.K., Lin, L.C., Liu, C.W. and Jen, C.W., 2005, April. A unified processor architecture for RISC & VLIW DSP. In *Proceedings of the 15th ACM Great Lakes symposium on VLSI* (pp. 50-55).  
\[3\] Lee, S., Lee, J., Park, C.Y. and Min, S.L., 2007\. Selective code transformation for dual instruction set processors. *ACM Transactions on Embedded Computing Systems (TECS)*, *6*(2), pp.10-es.  
\[4\] Venkat, A., Basavaraj, H. and Tullsen, D.M., 2019, February. Composite-ISA cores: Enabling multi-ISA heterogeneity using a single ISA. In *2019 IEEE International Symposium on High Performance Computer Architecture (HPCA)* (pp. 42-55). IEEE.  
\[5\] Kra, Y., Shoshan, Y., Rudin, Y. and Teman, A., 2023\. HAMSA-DI: A low-power dual-issue RISC-V core targeting energy-efficient embedded systems. *IEEE Transactions on Circuits and Systems I: Regular Papers*, *71*(1), pp.223-236.
