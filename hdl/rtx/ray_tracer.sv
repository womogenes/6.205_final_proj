`default_nettype none

module ray_tracer #(
  parameter integer WIDTH = 1280,
  parameter integer HEIGHT = 720
) (
  input wire clk,
  input wire rst,

  input wire [10:0] pixel_h_in,
  input wire [9:0] pixel_v_in,

  input fp_vec3 ray_origin,
  input fp_vec3 ray_dir,
  input wire ray_valid,

  output logic ray_done,
  output fp_vec3 pixel_color,
  output logic [10:0] pixel_h_out,
  output logic [9:0] pixel_v_out,

  // Interface to scene buffer
  input wire [$clog2(MAX_NUM_OBJS)-1:0] num_objs,
  input object obj,

  // Dynamic parameter: # of bounces
  input wire [7:0] max_bounces,

  // DEBUG: to be used only for testbench
  input wire [95:0] lfsr_seed
);
  typedef enum { IDLE, INTX, REFLECT } tracer_state;

  // This is an FSM
  tracer_state state;

  logic ray_valid_intx;
  logic ray_done_intx;
  logic ray_valid_rflx;
  logic ray_done_reflect;

  fp_vec3 cur_ray_origin;
  fp_vec3 cur_ray_dir;
  fp_color cur_income_light;
  fp_color cur_ray_color;

  // Intersector results
  material intx_hit_mat;
  fp_vec3 intx_hit_pos;
  fp_vec3 intx_hit_norm;
  logic intx_hit_any;

  // Reflector results
  fp_vec3 rflx_new_dir;
  fp_vec3 rflx_new_origin;
  fp_color rflx_new_color;
  fp_color rflx_new_income_light;

  logic [7:0] bounce_count;

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      ray_valid_intx <= 1'b0;
      ray_done <= 1'b0;
      bounce_count <= 0;

    end else begin
      // three-state FSM wahoo
      // TODO: remove the FSM and if the intersector is not busy, select between
      //   new ray and the reflector output

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
            cur_ray_color <= {FP_ONE, FP_ONE, FP_ONE};  // (1, 1, 1)
            pixel_color <= {FP_ZER0, FP_ZER0, FP_ZER0}; // (1, 0, 1) debug color

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
              ray_valid_rflx <= 1'b1;
              state <= REFLECT;

            end else begin
              // We didn't hit anything :( ray is done for
              // TODO: ambient light
              state <= IDLE;
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

            if (bounce_count >= max_bounces - 1) begin
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
    .hit_dist(),
    .hit_any(intx_hit_any),
    .hit_valid(ray_done_intx),

    // Scene buffer interface
    .num_objs(num_objs),
    .obj(obj)
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
  // pipeline #(.WIDTH(10), .DEPTH(2)) pixel_v_pipe (.clk(clk), .in(pixel_v_in), .out(pixel_v_out));
  // pipeline #(.WIDTH(10), .DEPTH(2)) pixel_v_pipe (.clk(clk), .in(pixel_v_in), .out(pixel_v_out));
  // I think we can assume this because inputs should be held constant?
  // TODO: optimize this
  assign pixel_h_out = pixel_h_in;
  assign pixel_v_out = pixel_v_in;
endmodule

`default_nettype wire
