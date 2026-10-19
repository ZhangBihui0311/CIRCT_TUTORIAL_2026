module {
  hw.module @fma_bmc(in %clk : i1, in %a : i4, in %b : i4, in %c : i4, out d : i9) {
    %c8_i9 = hw.constant 8 : i9
    %c4_i4 = hw.constant 4 : i4
    %c3_i4 = hw.constant 3 : i4
    %true = hw.constant true
    %c0_i5 = hw.constant 0 : i5
    %0 = comb.concat %c0_i5, %a : i5, i4
    %1 = comb.concat %c0_i5, %b : i5, i4
    %2 = comb.mul %0, %1 : i9
    %3 = comb.concat %c0_i5, %c : i5, i4
    %4 = comb.add %2, %3 : i9
    %5 = seq.to_clock %clk
    %d_reg = seq.firreg %4 clock %5 : i9
    %6 = comb.extract %4 from 8 : (i9) -> i1
    %7 = comb.xor %6, %true : i1
    verif.clocked_assert %7, posedge %clk : i1
    %8 = comb.icmp ult %a, %c3_i4 : i4
    %9 = comb.icmp ult %b, %c3_i4 : i4
    %10 = comb.icmp ult %c, %c4_i4 : i4
    %11 = comb.and %8, %9, %10 : i1
    verif.clocked_assume %11, posedge %clk : i1
    %12 = comb.icmp ult %4, %c8_i9 : i9
    verif.clocked_assert %12, posedge %clk : i1
    %13 = ltl.past %a, 1 clk %clk : i4
    %14 = comb.concat %c0_i5, %13 : i5, i4
    %15 = ltl.past %b, 1 clk %clk : i4
    %16 = comb.concat %c0_i5, %15 : i5, i4
    %17 = comb.mul %14, %16 : i9
    %18 = ltl.past %c, 1 clk %clk : i4
    %19 = comb.concat %c0_i5, %18 : i5, i4
    %20 = comb.add %17, %19 : i9
    %21 = comb.icmp eq %d_reg, %20 : i9
    %22 = ltl.delay %true, 1, 0 : i1
    %23 = ltl.concat %22, %true : !ltl.sequence, i1
    %24 = ltl.implication %23, %21 : !ltl.sequence, i1
    verif.clocked_assert %24, posedge %clk : !ltl.property
    hw.output %d_reg : i9
  }
}
