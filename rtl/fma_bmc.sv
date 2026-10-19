// rtl/fma_bmc.sv
// A minimal sequential extension of fma.sv for demonstrating circt-bmc
// (bounded model checking). The original combinational fma logic is kept
// verbatim; we only add:
//   1. a clocked output register - gives circt-bmc sequential state to unroll
//   2. assume/assert properties  - the formal specification circt-bmc checks
module fma_bmc (
    input  wire       clk,   // added: the clock circt-bmc unrolls over
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [3:0] c,
    output wire [8:0] d
);
    // --- original fma.sv logic, unchanged ---
    wire [8:0] fma_out;
    assign fma_out = (a * b) + (c * 1'd1);

    // --- addition 1: register the result (one cycle of latency) ---
    logic [8:0] d_reg;
    always_ff @(posedge clk)
        d_reg <= fma_out;
    assign d = d_reg;

    // --- addition 2: properties (verif dialect) -----------------------
    // Property 1 (safety invariant): a*b <= 15*15 = 225 and c <= 15, so
    // the fma result always fits in 8 bits - bit 8 must never be set.
    assert property (@(posedge clk) fma_out[8] == 1'b0);

    // Assumption (environment constraint): only small input values occur.
    assume property (@(posedge clk) a <= 4'd2 && b <= 4'd2 && c <= 4'd3);

    // Property 2: under the assumption above the result is bounded by
    // 2*2 + 3 = 7. circt-bmc proves this holds in *every* checked cycle.
    assert property (@(posedge clk) fma_out <= 9'd7);

    // Property 3 (sequential): the registered output always holds the fma
    // of the inputs sampled one cycle earlier. BMC leaves the register's
    // initial state unconstrained, so d is only meaningful from the second
    // cycle on - which is exactly what |=> expresses here.
    assert property (@(posedge clk)
        1'b1 |=> d == ({5'd0, $past(a)} * {5'd0, $past(b)}) + {5'd0, $past(c)});

    // Exercise: the property below forgets the pipeline register. The
    // equivalent experiment on the BMC-ready MLIR (rtl/fma_bmc_bmc.mlir)
    // is Exercise 6 in the README.
    // assert property (@(posedge clk) 1'b1 |=> d == fma_out);

endmodule
