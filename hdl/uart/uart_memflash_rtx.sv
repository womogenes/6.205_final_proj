`default_nettype none

module uart_memflash_rtx (
  input wire clk,
  input wire rst,

  input wire uart_rx_valid,
  input wire [7:0] uart_rx_byte,

  output logic flash_active,
  output logic [7:0] flash_cmd,
  output logic [CAM_WIDTH-1:0] flash_cam_data,
  output logic [OBJ_WIDTH-1:0] flash_obj_data,
  output logic [NUM_OBJS_WIDTH-1:0] flash_num_objs_data,
  output logic [7:0] flash_max_bounces_data,
  output logic flash_wen
);
  localparam integer CAM_BYTES = ((FP_VEC3_BITS * 3) + 7) / 8;
  localparam integer CAM_WIDTH = CAM_BYTES * 8;
  localparam integer OBJ_BYTES = ($bits(object) + 7) / 8;
  localparam integer OBJ_WIDTH = OBJ_BYTES * 8;
  localparam integer NUM_OBJS_BYTES = (OBJ_IDX_WIDTH + 7) / 8;
  localparam integer NUM_OBJS_WIDTH = NUM_OBJS_BYTES * 8;

  // Goal: allow writing words to consecutive memory addresses
  /*
    Protocol:
      - UART sends command type:
          cam origin
          cam right
          cam forward
          cam up
          max bounces (?)
          scene object (with idx)
      - UART sends data
  */

  typedef enum {
    IDLE,
    DATA_CAM,
    DATA_OBJ,
    DATA_NUM_OBJS,
    DATA_MAX_BOUNCES
  } flash_state;

  flash_state state;

  logic [7:0] flash_cam_byte_idx;                                 // "good enough, we're never gonna have that many bytes"
  logic [$clog2(OBJ_BYTES)-1:0] flash_obj_byte_idx;               // N/8 bytes
  logic [$clog2(NUM_OBJS_BYTES)-1:0] flash_num_objs_byte_idx;  // probably 1, if we have <= 256 objects
  
  always_ff @(posedge clk) begin
    if (rst) begin
      flash_active <= 1'b0;
      flash_wen <= 1'b0;
      state <= IDLE;
      
    end else begin
      case (state)
        IDLE: begin
          flash_wen <= 1'b0;

          if (uart_rx_valid) begin
            casez (uart_rx_byte)
              8'b1????0??: state <= DATA_CAM;
              8'b0???????: state <= DATA_OBJ;
              8'b1????100: state <= DATA_NUM_OBJS;
              8'b1????101: state <= DATA_MAX_BOUNCES;
            endcase

            flash_active <= 1'b1;
            flash_cmd <= uart_rx_byte;
            flash_cam_byte_idx <= 0;
            flash_obj_byte_idx <= 0;
            flash_num_objs_byte_idx <= 0;

          end else begin
            flash_active <= 1'b0;
          end
        end
        DATA_CAM: begin
          /*
            COMMAND FORMAT:
              'b1xxxxx00 is cam.origin
              'b1xxxxx01 is cam.right
              'b1xxxxx10 is cam.forward
              'b1xxxxx11 is cam.up
              'b0xxxxxxx is object overwrite
          */
          if (uart_rx_valid) begin
            // UART bytes are transmitted *LSB*
            flash_cam_data <= {uart_rx_byte, flash_cam_data[CAM_WIDTH-1:8]};

            if (flash_cam_byte_idx == CAM_BYTES - 1) begin
              flash_cam_byte_idx <= 0;
              flash_wen <= 1'b1;
              state <= IDLE;
            end else begin
              flash_cam_byte_idx <= flash_cam_byte_idx + 1;
            end
          end
        end
        DATA_OBJ: begin
          if (uart_rx_valid) begin
            flash_obj_data <= {uart_rx_byte, flash_obj_data[OBJ_WIDTH-1:8]};

            if (flash_obj_byte_idx == OBJ_BYTES - 1) begin
              flash_obj_byte_idx <= 0;
              flash_wen <= 1'b1;
              state <= IDLE;
            end else begin
              flash_obj_byte_idx <= flash_obj_byte_idx + 1;
            end
          end
        end
        DATA_NUM_OBJS: begin
          if (uart_rx_valid) begin
            flash_num_objs_data <= {uart_rx_byte, flash_num_objs_data[NUM_OBJS_WIDTH-1:8]};

            if (flash_num_objs_byte_idx == NUM_OBJS_BYTES - 1) begin
              flash_num_objs_byte_idx <= 0;
              flash_wen <= 1'b1;
              state <= IDLE;
            end else begin
              flash_num_objs_byte_idx <= flash_num_objs_byte_idx + 1;
            end
          end
        end
        DATA_MAX_BOUNCES: begin
          if (uart_rx_valid) begin
            flash_max_bounces_data <= uart_rx_byte;
            flash_wen <= 1'b1;
            state <= IDLE;
          end
        end
      endcase
    end
  end

endmodule

`default_nettype wire
