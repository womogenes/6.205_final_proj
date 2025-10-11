`default_nettype none

module tm_choice (
  input wire [7:0] d,     //data byte in
  output logic [8:0] q_m  //transition minimized output
);
  logic [3:0] n_ones;
  logic use_xnor; // if true, use xnor. else, use xor.

  always_comb begin
    n_ones = d[0] + d[1] + d[2] + d[3] +
             d[4] + d[5] + d[6] + d[7];
    use_xnor = (n_ones > 4 || (n_ones == 4 && d[0] == 0));
    
    q_m[0] = d[0];
    for (integer i = 0; i < 7; i = i+1) begin
      q_m[i+1] = use_xnor ? ~(q_m[i] ^ d[i+1]) : (q_m[i] ^ d[i+1]);
    end
    q_m[8] = ~use_xnor;
  end

endmodule

`default_nettype wire
