`default_nettype none

// Use automatic to allow multi-instantiation of functions

/*
  add_ve3:
    inputs: vec3 a, vec3b
    output: vec3 sum of a and b
  
  timing:
    purely combinational, 0 cycle delay
*/
function automatic vec3 add_vec3(vec3 a, vec3 b);
  return '{
    x: a.x + b.x,
    y: a.y + b.y,
    z: a.z + b.z
  };
endfunction

`default_nettype wire
