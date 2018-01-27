\brief This file includes the DOXYGEN documentation entry page of the DSP Library.

\page DSP_LIBRARY DSP Library Overview

Introduction
============

The DSP library
* collection of types, functions and procedures in addition to the ieee.numeric_std library ... see ieee_extension
* support of rounding, clipping/saturation and overflow detection
* abstraction layer to hide FPGA device specific DSP primitives

The main goal of this library is to simplify the process of moving designs between
different FPGA device types and vendors with different DSP cell primitives.
This only works for basic operations and features that are supported by all DSP cells.
Highly optimized solutions will always be device and vendor specific and are not considered here.

Contents
========

Currently the focus is on the following device families:
* Altera Stratix V (with primitive \b \e stratixv_mac )
* Altera Arria 10 (with primitive \b \e twentynm_mac )
* Altera Stratix 10 (with primitive \b \e fourteennm_mac )
* Xilinx UltraScale/UltraScale+ (with primitive \b \e dsp48e2 )

It is recommended to only use the following generic entities in the design.

|Entity Name               | Stratix V  | Arria 10  | UltraScale | Stratix 10 | Description
|:-------------------------|:----------:|:---------:|:----------:|:----------:|:-----------------
|signed_mult               | derived    | TODO      | derived    | TODO       | N parallel and synchronous signed multiplications
|signed_mult_accu          | chained    | TODO      | chained    | TODO       | N signed multiplications and accumulation of all results
|signed_mult_sum           | chained    | TODO      | chained    | TODO       | N signed multiplications and summation of all results

The following entities should not be instantiated in the design. They are used by the more generic entities above.

|Entity Name               | Virtex 4  | Stratix V  | Arria 10  | UltraScale | Description
|:-------------------------|:---------:|:----------:|:---------:|:----------:|:-----------------
|signed_mult1_accu         | PRIMITIVE | PRIMITIVE  | PRIMITIVE | PRIMITIVE  | one signed multiplication and accumulation of all results
|signed_mult1add1_accu     | ---       | PRIMITIVE  | PRIMITIVE | PRIMITIVE  | one value +/- signed product and accumulation of all results
|signed_mult1add1_sum      | ---       | derived    | derived   | PRIMITIVE  | one value +/- signed product
|signed_mult2              | ---       | PRIMITIVE  | PRIMITIVE | ---        | two parallel and synchronous signed multiplications
|signed_mult2_accu         | ---       | PRIMITIVE  | PRIMITIVE | chained    | two signed multiplications and accumulation of all results
|signed_mult2_sum          | ---       | derived    | derived   | chained    | two signed multiplications and sum product results
|signed_mult3              | ---       | PRIMITIVE  | ---       | ---        | three parallel and synchronous signed multiplications
|signed_mult4_sum          | ---       | PRIMITIVE  | ---       | chained    | four signed multiplications and sum product results
|signed_preadd_mult1_accu  | ---       | PRIMITIVE  | PRIMITIVE | PRIMITIVE  | multiply sum of two signed with another signed and accumulate results

* PRIMITIVE = this implementation directly instantiates the DSP primitive
* derived = this implementation is derived from another implementation
* chained = this implementation uses chaining of other implementations

More FPGA devices and types might be added later.


Composition and Naming Convention
=================================

Todays DSP cells are made up of similar basic components like preadders, multipliers, negation
and add/subtract/accumulation stages. Furthermore, chaining of multiple DSP cells is supported.
To have a common and generic naming convention the name of DSP entities is split into three parts:
* the number format (e.g. signed, unsigned)
* the basic operation (e.g. mult) 
* final consolidation (e.g. sum, accumulation)

Operations can be performed multiple times in parallel and therefore also carry a number (e.g.
mult2 for two multiplications). In the final consolidation step also chaining of DSP cells is
possible though not supported by all implementations and FPGA device types. Please refer
the device specific implementation description for all details and limitations.
The architectures of the DSP entities are typically named according to the FPGA
device, e.g. "stratixv" or "ultrascale".

@image html dsp_composition_naming.svg "" width=1000px

\b Example: A signed DSP operation which adds two values and then multiplies the result with a
third value is called "signed_preadd_mult1". If the results of this operation can additionally
be accumulated over several cycles the postfix "accu" is added. Hence, the complete entity is
called "signed_preadd_mult1_accu".

---
MIT License : Copyright (c) 2017 Fixitfetish
 - <https://opensource.org/licenses/MIT>
 - <https://en.wikipedia.org/wiki/MIT_License>