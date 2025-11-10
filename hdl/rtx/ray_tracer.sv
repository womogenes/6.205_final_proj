`default_nettype none

module ray_tracer #(
  parameter integer WIDTH = 1280,
  parameter integer HEIGHT = 720
) (
  input wire clk,
  input wire rst,

  input wire [10:0] pixel_h_in,
  input wire [9:0] pixel_v_in,

  input fp24_vec3 ray_origin,
  input fp24_vec3 ray_dir,
  input wire ray_valid,
  
  input logic [47:0] lfsr_seed,

  output logic ray_done,
  output fp24_vec3 pixel_color,
  output logic [10:0] pixel_h_out,
  output logic [9:0] pixel_v_out,

  // Interface to scene buffer
  output logic [$clog2(SCENE_BUFFER_DEPTH)-1:0] obj_idx,
  input object obj,
  input wire obj_last
);
  typedef enum { IDLE, INTX, REFLECT } tracer_state;

  // This is an FSM
  tracer_state state;

  logic ray_valid_intx;
  logic ray_done_intx;
  logic ray_valid_rflx;
  logic ray_done_reflect;

  fp24_vec3 cur_ray_origin;
  fp24_vec3 cur_ray_dir;
  fp24_color cur_income_light;
  fp24_color cur_ray_color;

  // Intersector results
  material intx_hit_mat;
  fp24_vec3 intx_hit_pos;
  fp24_vec3 intx_hit_norm;
  logic intx_hit_any;

  // Reflector results
  fp24_vec3 rflx_new_dir;
  fp24_vec3 rflx_new_origin;
  fp24_vec3 rflx_new_color;
  fp24_vec3 rflx_new_income_light;

  logic [$clog2(MAX_BOUNCES)-1:0] bounce_count;

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      ray_valid_intx <= 1'b0;
      ray_done <= 1'b0;
      bounce_count <= 0;

    end else begin
      // three-state FSM wahoo
      case (state)
        IDLE: begin
          ray_valid_intx <= 1'b0;   // redundant i think but to be safe
          ray_done <= 1'b0;
          bounce_count <= 0;

          if (ray_valid) begin
            // Capture input values
            cur_ray_origin <= ray_origin;
            cur_ray_dir <= ray_dir;
            cur_income_light <= 0;                  // (0, 0, 0)
            cur_ray_color <= 72'h3f00003f00003f0000;  // (1, 1, 1)

            // Trigger the intersector
            ray_valid_intx <= 1'b1;
            state <= INTX;
          end
        end
        INTX: begin
          ray_valid_intx <= 1'b0;

          if (ray_done_intx) begin
            if (intx_hit_any) begin
              // Capture results from intersector
              cur_ray_origin <= intx_hit_pos;

              ray_valid_rflx <= 1'b1;
              state <= REFLECT;

            end else begin
              // We didn't hit anything :( ray is done for
              // TODO: ambient light
              state <= IDLE;
              pixel_color <= cur_income_light;
              ray_done <= 1'b1;
            end
          end
        end
        REFLECT: begin
          ray_valid_rflx <= 1'b0;

          if (ray_done_reflect) begin
            // Latch reflector values and keep going
            cur_ray_dir <= rflx_new_dir;
            cur_ray_origin <= rflx_new_origin;    // ??
            cur_ray_color <= rflx_new_color;
            cur_income_light <= rflx_new_income_light;
            pixel_color <= rflx_new_income_light;

            if (bounce_count >= MAX_BOUNCES - 1) begin
              // Bounced max no. of times, exit loop
              state <= IDLE;
              ray_done <= 1'b1;
              
            end else begin
              // Transition the next state
              ray_valid_intx <= 1'b1;
              bounce_count <= bounce_count + 1;
              state <= INTX;
            end
          end
        end
      endcase
    end
  end

  ray_intersector ray_intx (
    .clk(clk),
    .rst(rst),
    .ray_origin(cur_ray_origin),
    .ray_dir(cur_ray_dir),
    .ray_valid(ray_valid_intx),

    // Outputs
    .hit_mat(intx_hit_mat),
    .hit_pos(intx_hit_pos),
    .hit_normal(intx_hit_norm),
    .hit_dist_sq(),
    .hit_any(intx_hit_any),
    .hit_valid(ray_done_intx),

    // Scene buffer interface
    .obj_idx(obj_idx),
    .obj(obj),
    .obj_last(obj_last)
  );

  ray_reflector ray_reflect (
    .clk(clk),
    .rst(rst),

    // Inputs
    .ray_dir(cur_ray_dir),
    .ray_color(cur_ray_color),
    .income_light(cur_income_light),

    .lfsr_seed(lfsr_seed),

    .hit_pos(intx_hit_pos),
    .hit_normal(intx_hit_norm),
    .hit_mat(intx_hit_mat),
    .hit_valid(ray_valid_rflx),

    // Outputs
    .new_dir(rflx_new_dir),
    .new_origin(rflx_new_origin),
    .new_color(rflx_new_color),
    .new_income_light(rflx_new_income_light),
    .reflect_done(ray_done_reflect)
  );

  // pipeline #(.WIDTH(11), .DEPTH(2)) pixel_h_pipe (.clk(clk), .in(pixel_h_in), .out(pixel_h_out));
  // pipeline #(.WIDTH(10), .DEPTH(2)) pixel_v_pipe (.clk(clk), .in(pixel_v_in), .out(pixel_v_out));

  // I think we can assume this because inputs should be held constant?
  assign pixel_h_out = pixel_h_in;
  assign pixel_v_out = pixel_v_in;
endmodule

`default_nettype wire
