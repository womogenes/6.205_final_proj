`default_nettype none

module uart_memflash_rtx (
  input wire clk,
  input wire rst,

  input wire uart_rx_valid,
  input wire [7:0] uart_rx_byte,

  output logic flash_active,
  output logic [7:0] flash_cmd,
  output logic [71:0] flash_cam_data,
  output logic flash_wen
);
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
    DATA_CAM
  } flash_state;

  flash_state state;
  logic [3:0] flash_cam_byte_idx;         // 9 bytes for 72-bit cam vector
  
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
            state <= DATA_CAM;
            flash_active <= 1'b1;
            
            /*
              COMMAND REFERENCE:
                'hxx00 is cam.origin
                'hxx01 is cam.right
                'hxx10 is cam.forward
                'hxx11 is cam.up
            */
            flash_cmd <= uart_rx_byte;
            flash_cam_byte_idx <= 0;

          end else begin
            flash_active <= 1'b0;
          end
        end
        DATA_CAM: begin
          if (uart_rx_valid) begin
            // UART bytes are transmitted *LSB*
            flash_cam_data <= {uart_rx_byte, flash_cam_data[71:8]};

            if (flash_cam_byte_idx == 8) begin
              flash_cam_byte_idx <= 0;
              flash_wen <= 1'b1;
              state <= IDLE;
            end else begin
              flash_cam_byte_idx <= flash_cam_byte_idx + 1;
            end
          end
        end
      endcase
    end
  end

endmodule

`default_nettype wire
