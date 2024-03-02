/* Vedant Kelkar - vkelkar     Manas Kulkarni - manask */

`timescale 1ns / 1ns

// quotient = dividend / divisor

module divider_unsigned(
    input wire [31:0] i_dividend,
    input wire [31:0] i_divisor,
    output wire [31:0] o_quotient,
    output wire [31:0] o_remainder
);
    // Internal signals for connecting divu_1iter modules
    wire [31:0] dividend [0:32];
    wire [31:0] quotient [0:32];
    wire [31:0] remainder [0:32];


    // Connect the first set of inputs to the external inputs
    assign dividend[0] = i_dividend[31:0];
    assign quotient[0] = 32'b0;
    assign remainder[0] = 32'b0;

    generate
        
    // Instantiate 32 divu_1iter modules
    for (genvar i=0; i < 32; i++) begin : bit_div
        divu_1iter div_iter (
            .i_dividend(dividend[i]),
            .i_divisor(i_divisor),
            .i_remainder(remainder[i]),
            .i_quotient(quotient[i]),
            .o_dividend(dividend[i+1]),
            .o_remainder(remainder[i+1]),
            .o_quotient(quotient[i+1])
        );

    end
    endgenerate

    // Connect the last set of outputs to the external outputs
    assign o_remainder = remainder[32];
    assign o_quotient = quotient[32];

endmodule


module divu_1iter (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    input  wire [31:0] i_remainder,
    input  wire [31:0] i_quotient,
    output wire [31:0] o_dividend,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);

    
    logic [31:0] t_remainder;
    logic [31:0] t1_remainder;
    logic [31:0] quotient;
    logic [31:0] shifted_dividend;

    always_comb begin
        assign t_remainder = {i_remainder[30:0], i_dividend[31]};
        assign shifted_dividend = i_dividend << 1;

        // Update quotient conditionally
        assign quotient = (t_remainder < i_divisor) ? (i_quotient << 1) : ({i_quotient[30:0], 1'b1});
        assign t1_remainder = (t_remainder < i_divisor) ? t_remainder : t_remainder - i_divisor;
    end

    assign o_dividend = shifted_dividend;
    assign o_remainder = t1_remainder;
    assign o_quotient = quotient;
endmodule
