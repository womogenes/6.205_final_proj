// TODO: reformat

`default_nettype none
module seven_segment_controller #(parameter COUNT_PERIOD = 100000)
    (   input wire           clk,
        input wire           rst,
        input wire [31:0]    val,
        output logic[6:0]    cat,
        output logic[7:0]    an
    );
    logic [7:0]   segment_state;
    logic [31:0]  segment_counter;
    logic [3:0]   sel_values;
    logic [6:0]   led_out;

    // current hex digit (select from segment_state)
    always_comb begin
        if (segment_state == 8'b00000001) begin
            sel_values = val[ 3: 0];
        end else if (segment_state == 8'b00000010) begin
            sel_values = val[ 7: 4];
        end else if (segment_state == 8'b00000100) begin
            sel_values = val[11: 8];
        end else if (segment_state == 8'b00001000) begin
            sel_values = val[15:12];
        end else if (segment_state == 8'b00010000) begin
            sel_values = val[19:16];
        end else if (segment_state == 8'b00100000) begin
            sel_values = val[23:20];
        end else if (segment_state == 8'b01000000) begin
            sel_values = val[27:24];
        end else if (segment_state == 8'b10000000) begin
            sel_values = val[31:28];
        end
    end
 
    bto7s mbto7s (.x(sel_values), .s(led_out));
    assign cat = ~led_out; //<--note this inversion is needed
    assign an = ~segment_state; //note this inversion is needed
 
    always_ff @(posedge clk) begin
        if (rst) begin
            segment_state <= 8'b0000_0001;
            segment_counter <= 32'b0;
        end else begin
            if (segment_counter == COUNT_PERIOD) begin
                segment_counter <= 32'd0;
                segment_state <= {segment_state[6:0], segment_state[7]};
            end else begin
                segment_counter <= segment_counter +1;
            end
        end
    end
endmodule // seven_segment_controller
 
`default_nettype wire
