/*
  Module to parse UART data and serve it up
*/

`default_nettype none

// objects will SURELY be no bigger than 128 bytes...
parameter integer MAX_UART_DATA_BYTES = 128;

module uart_memflash_rtx (
  input wire clk,
  input wire rst,

  input wire uart_rx_valid,
  input wire [7:0] uart_rx_byte,

  output logic flash_active,
  output logic [7:0] flash_cmd,
  output logic [MAX_DATA_BYTES*8-1:0] flash_data,
  output logic flash_wen
);
  localparam integer CAM_BYTES = (FP_VEC3_BITS + 7) / 8;
  localparam integer OBJ_IDX_BYTES = (OBJ_IDX_WIDTH + 7) / 8;
  localparam integer OBJ_BYTES = ($bits(object) + 7) / 8;
  localparam integer NUM_OBJS_BYTES = (OBJ_IDX_WIDTH + 7) / 8;
  localparam integer MAX_BOUNCES_BYTES = 1;

  // Maximum number of bytes that can be sent
  localparam integer MAX_DATA_BYTES = MAX_UART_DATA_BYTES;

  // Goal: allow writing words to consecutive memory addresses
  /*
    Protocol:
      - UART sends command type (one byte)
      - UART sends data
  */

  typedef enum {
    IDLE,
    DATA
  } flash_state;

  flash_state state;

  logic [$clog2(MAX_DATA_BYTES)-1:0] byte_idx;
  logic [$clog2(MAX_DATA_BYTES)-1:0] last_byte_idx;
  
  always_ff @(posedge clk) begin
    if (rst) begin
      flash_active <= 1'b0;
      flash_wen <= 1'b0;
      state <= IDLE;
      byte_idx <= 0;
      
    end else begin
      case (state)
        IDLE: begin
          flash_wen <= 1'b0;

          if (uart_rx_valid) begin
            casez (uart_rx_byte)
              8'h00: last_byte_idx <= (CAM_BYTES - 1);
              8'h01: last_byte_idx <= (CAM_BYTES - 1);
              8'h02: last_byte_idx <= (CAM_BYTES - 1);
              8'h03: last_byte_idx <= (CAM_BYTES - 1);

              8'h04: last_byte_idx <= (OBJ_IDX_BYTES - 1);
              8'h05: last_byte_idx <= (OBJ_BYTES - 1);
              8'h06: last_byte_idx <= (NUM_OBJS_BYTES - 1);
              8'h07: last_byte_idx <= (MAX_BOUNCES_BYTES - 1);
            endcase

            flash_active <= 1'b1;
            flash_cmd <= uart_rx_byte;
            state <= DATA;

          end else begin
            flash_active <= 1'b0;
          end
        end
        DATA: begin
          if (uart_rx_valid) begin
            // UART bytes are transmitted *MSB*
            // Shift data register to left 1 byte and get new byte
            flash_data <= {flash_data[MAX_DATA_BYTES*8-9:0], uart_rx_byte};

            if (byte_idx == last_byte_idx) begin
              byte_idx <= 0;
              flash_wen <= 1'b1;
              state <= IDLE;
            end else begin
              byte_idx <= byte_idx + 1;
            end
          end
        end
      endcase
    end
  end

endmodule

`default_nettype wire
