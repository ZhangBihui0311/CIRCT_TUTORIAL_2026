// rtl/fma_bmc_bmc.mlir
// BMC-ready version of the fma_bmc design (compiled from rtl/fma_bmc.sv).
//
// circt-bmc (firtool-1.147.0) cannot consume the circt-verilog output
// directly; it requires the design in a canonical form:
//   1. the clock is a !seq.clock module port and every register is clocked
//      directly by that port (no seq.to_clock wrappers),
//   2. properties are plain verif.assert / verif.assume ops (not their
//      clocked variants),
//   3. all assertions are combined into a single verif.assert,
//   4. $past(...) is realized with explicit delay registers.
// This file is exactly the circt-verilog output of rtl/fma_bmc.sv rewritten
// in that form.
//
// Run with --ignore-asserts-until=1: the register initial state is left
// symbolic, so the sequential property is only meaningful from the second
// cycle on.
module {
  hw.module @fma_bmc(in %clk : !seq.clock, in %a : i4, in %b : i4, in %c : i4, out d : i9) {
    %true = hw.constant true
    %c0_i5 = hw.constant 0 : i5
    %c3_i4 = hw.constant 3 : i4
    %c4_i4 = hw.constant 4 : i4
    %c8_i9 = hw.constant 8 : i9

    // --- original fma logic, unchanged ---
    %a_ext = comb.concat %c0_i5, %a : i5, i4
    %b_ext = comb.concat %c0_i5, %b : i5, i4
    %prod = comb.mul %a_ext, %b_ext : i9
    %c_ext = comb.concat %c0_i5, %c : i5, i4
    %fma_out = comb.add %prod, %c_ext : i9

    // --- sequential state: the registered output ---
    %d_reg = seq.compreg %fma_out, %clk : i9

    // --- one-cycle delay registers realizing $past(a), $past(b), $past(c) ---
    %a_d = seq.compreg %a, %clk : i4
    %b_d = seq.compreg %b, %clk : i4
    %c_d = seq.compreg %c, %clk : i4

    // Property 1: the fma result always fits in 8 bits (bit 8 never set).
    %bit8 = comb.extract %fma_out from 8 : (i9) -> i1
    %prop1 = comb.xor %bit8, %true : i1

    // Assumption: only small input values occur.
    %a_small = comb.icmp ult %a, %c3_i4 : i4
    %b_small = comb.icmp ult %b, %c3_i4 : i4
    %c_small = comb.icmp ult %c, %c4_i4 : i4
    %env = comb.and %a_small, %b_small, %c_small : i1
    verif.assume %env : i1

    // Property 2: under the assumption the result is bounded by 7.
    %prop2 = comb.icmp ult %fma_out, %c8_i9 : i9

    // Property 3: the registered output holds the fma of the inputs sampled
    // one cycle earlier.
    %a_d_ext = comb.concat %c0_i5, %a_d : i5, i4
    %b_d_ext = comb.concat %c0_i5, %b_d : i5, i4
    %prod_d = comb.mul %a_d_ext, %b_d_ext : i9
    %c_d_ext = comb.concat %c0_i5, %c_d : i5, i4
    %fma_d = comb.add %prod_d, %c_d_ext : i9
    %prop3 = comb.icmp eq %d_reg, %fma_d : i9

    // circt-bmc supports a single assertion: conjoin the properties.
    %all = comb.and %prop1, %prop2, %prop3 : i1
    verif.assert %all : i1

    hw.output %d_reg : i9
  }
}
