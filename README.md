# TinyRISC – 5-Stage Pipelined RISC Processor in Verilog

A simple 32-bit RISC CPU (“TinyRISC”) with a classic five-stage pipeline, implemented in Verilog and targeted for FPGA (Vivado).  

## Table of Contents

1. [Architecture Overview](#architecture-overview)  
2. [Repository Layout](#repository-layout)  
3. [Prerequisites](#prerequisites)  
4. [Getting Started](#getting-started)  
   - [Synthesis & Implementation (Vivado)](#synthesis--implementation-vivado)  
   - [Simulation (Icarus & ModelSim)](#simulation-icarus--modelsim)  
5. [Pipeline Stages](#pipeline-stages)  
6. [Instruction Set](#instruction-set)  
7. [Testbench & Verification](#testbench--verification)  
8. [Constraints & Timing](#constraints--timing)  
9. [Future Work](#future-work)  
10. [License & Acknowledgments](#license--acknowledgments)  

---

## Architecture Overview

TinyRISC is a basic 32-bit load/store RISC processor with:

- Five pipeline stages: Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), Write-Back (WB)  
- A 32×32-bit register file  
- Simple ALU supporting ADD, SUB, AND, OR, XOR, SLT, shifts  
- Single-cycle memory interface in MEM stage  
- Static branch prediction (always not-taken) with pipeline flush on taken branches  

---

## Repository Layout


---

## Prerequisites

- Xilinx Vivado 20XX or later  
- Icarus Verilog (for open-source simulation)  
- ModelSim/Questa (optional, for more advanced verification)  
- GNU Make (optional, for automation scripts)  

---

## Getting Started

### Synthesis & Implementation (Vivado)

1. Open Vivado and create a new project, point to the `src/` and `constrs/` folders.  
2. Set `top.v` (or your top-level name) as the top module.  
3. Launch Synthesis → Implementation → Generate Bitstream.  
4. Program your FPGA (e.g. on Artix-7, Zybo, Nexys A7, etc.).  

Or from the command line:

```bash
vivado -mode batch -source scripts/synth.tcl
