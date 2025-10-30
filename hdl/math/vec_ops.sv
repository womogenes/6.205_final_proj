`default_nettype none

// Use automatic to allow multi-instantiation of functions

/*
  add_vec3:
    inputs: vec3 a, vec3b
    output: vec3 sum of a and b
  
  timing:
    purely combinational, 0 cycle delay
*/
function automatic vec3 add_vec3(vec3 a, vec3 b);
  vec3 result;
  result.x = a.x + b.x;
  result.y = a.y + b.y;
  result.z = a.z + b.z;
  return result;
endfunction

/*
  mul_vec3:
    inputs: vec3 a, vec3b
    output: element-wise product of a and b
      drops insignificant bits
  
  timing:
    1 cycle delay
*/
module mul_vec3(
  input wire clk,
  input wire rst,

  input vec3 din_a,
  input vec3 din_b,
  input wire din_valid,

  output vec3 dout,
  output logic dout_valid
);
  mul_fixed mul_x (
    .clk(clk), .rst(rst),
    .din_a(din_a.x), .din_b(din_b.x), .dout(dout.x),
    .din_valid(din_valid), .dout_valid(dout_valid)
  );
  mul_fixed mul_y (
    .clk(clk), .rst(rst),
    .din_a(din_a.y), .din_b(din_b.y), .dout(dout.y),
    .din_valid(din_valid), .dout_valid()
  );
  mul_fixed mul_z (
    .clk(clk), .rst(rst),
    .din_a(din_a.z), .din_b(din_b.z), .dout(dout.z),
    .din_valid(din_valid), .dout_valid()
  );
endmodule

`default_nettype wire

