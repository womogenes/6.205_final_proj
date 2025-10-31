`default_nettype none
module ray_signal_gen #(
  parameter SIZE_H = 1280,
  parameter SIZE_V = 720
) (
  input wire clk,
  input wire rst,

  input wire new_ray,

  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
);

  always_ff @(posedge clk) begin
    if (rst) begin
      pixel_h <= 0;
      pixel_v <= 0;
    end else begin
      if (new_ray) begin
        if (pixel_h == SIZE_H - 1) begin
          pixel_h <= 0;
          if (pixel_v == SIZE_V - 1) begin
            pixel_v <= 0;
          end else begin
            pixel_v <= pixel_v + 1;
          end
        end else begin
          pixel_h <= pixel_h + 1;
        end
      end
    end
  end

    
endmodule
`default_nettype wire