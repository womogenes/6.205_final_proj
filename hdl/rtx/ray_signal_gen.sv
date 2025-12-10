`default_nettype none

module ray_signal_gen #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input wire clk,
  input wire rst,

  input wire new_ray,

  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v
);

  always_ff @(posedge clk) begin
    if (rst) begin
      pixel_h <= WIDTH - 1;
      pixel_v <= HEIGHT - 1;

    end else begin
      if (new_ray) begin
        if (pixel_v == HEIGHT - 1) begin
          pixel_v <= 0;
          if (pixel_h == WIDTH - 1) begin
            pixel_h <= 0;
          end else begin
            pixel_h <= pixel_h + 1;
          end
        end else begin
          pixel_v <= pixel_v + 1;
        end
      end
    end
  end    
endmodule

`default_nettype wire
