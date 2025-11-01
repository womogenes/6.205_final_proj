`timescale 1ns / 1ps
`default_nettype none
 
module command_fifo #(
    parameter DEPTH=16, parameter WIDTH=16
) (
    input wire clk,
    input wire rst,
    input wire write,
    input wire [WIDTH-1:0] command_in,
    output logic full,

    output logic [WIDTH-1:0] command_out,
    input wire read,
    output logic empty
);
    // DEPTH should always be a power of 2 anyhow
    localparam integer ADDR_WIDTH = $clog2(DEPTH);

    logic [ADDR_WIDTH-1:0] write_ptr;
    logic [ADDR_WIDTH-1:0] read_ptr;
    logic [ADDR_WIDTH-1:0] next_write_ptr;

    // when read asynchronously/combinationally, will result in distributed RAM usage
    logic [WIDTH-1:0] fifo [DEPTH-1:0];

    // signals are combinationally derived
    always_comb begin
        next_write_ptr = write_ptr + 1'b1;
        full = next_write_ptr == read_ptr;
        empty = write_ptr == read_ptr;
        command_out = fifo[read_ptr];
    end

    // updates happen on clock edges
    always_ff @(posedge clk) begin
        if (rst) begin
            write_ptr <= 0;
            read_ptr <= 0;

        end else begin
            if (read && ~empty) begin
                read_ptr <= read_ptr + 1'b1;
            end
            if (write && ~full) begin
                write_ptr <= next_write_ptr;
                fifo[write_ptr] <= command_in;
            end
        end
    end
    
endmodule
`default_nettype wire
