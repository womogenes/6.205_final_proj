`timescale 1ns / 1ps
`default_nettype none

module prng_sphere_lfsr (
        input wire clk,
        input wire rst,
        input wire [47:0] seed,
        output fp24_vec3 rng_vec
    );
    logic [47:0] lfsr_reg;
    always_ff @(posedge clk) begin
        if (rst)
            lfsr_reg <= seed; // Nonzero seed. Never all-zeros!
        else begin
            lfsr_reg[0]    <= lfsr_reg[47];
            lfsr_reg[1]    <= lfsr_reg[0]  ^ lfsr_reg[47];
            lfsr_reg[26]   <= lfsr_reg[25] ^ lfsr_reg[47];
            lfsr_reg[27]   <= lfsr_reg[26] ^ lfsr_reg[47];
            lfsr_reg[25:2] <= lfsr_reg[24:1];
            lfsr_reg[47:28]<= lfsr_reg[46:27];
        end
    end
    logic [2:0][15:0] rand_ints;
    assign rand_ints = lfsr_reg;
    fp24 [2:0] rand_fp24s;
    generate
        genvar i;
        for (i = 0; i < 3; i = i + 1) begin
            make_fp24 #(.WIDTH(16)) converter (
                .clk(clk),
                .rst(rst),
                .n(rand_ints[i]),
                .x(rand_fp24s[i])
            );
        end
    endgenerate
    fp24_vec3 input_vec;
    assign input_vec = rand_fp24s;

    fp24_vec3_normalize normalizer (
        .clk(clk),
        .rst(rst),
        .v(input_vec),
        .normed(rng_vec)
    );

endmodule


`default_nettype wire
