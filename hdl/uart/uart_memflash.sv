`default_nettype none

module uart_memflash (
  input wire clk,
  input wire rst,

  input wire uart_rx_valid,
  input wire [7:0] uart_rx_byte,

  output logic flash_active,
  output logic [31:0] flash_addr,
  output logic [31:0] flash_data,
  output logic flash_wen
);
  // Goal: allow writing words to consecutive memory addresses
  /*
    Protocol:
      - UART sends 0xAA byte (start)
      - UART sends address (4 bytes)
      - UART sends length (4 bytes)
      - UART sends byte stream
  */

  typedef enum {
    IDLE,
    ADDRESS,
    LENGTH,
    BYTESTREAM
  } flash_state;

  flash_state state;
  logic [31:0] addr_base;
  logic [1:0] addr_base_byte_idx;
  logic [31:0] msg_len;
  logic [1:0] msg_len_byte_idx;

  logic [31:0] byte_idx;
  
  always_ff @(posedge clk) begin
    if (rst) begin
      flash_active <= 1'b0;
      flash_wen <= 1'b0;
      state <= IDLE;
      flash_addr <= 0;

      addr_base <= 0;
      addr_base_byte_idx <= 0;
      msg_len <= 0;
      msg_len_byte_idx <= 0;
      byte_idx <= 0;
      
    end else begin
      case (state)
        IDLE: begin
          if (uart_rx_valid && uart_rx_byte == 'hAA) begin
            state <= ADDRESS;
            flash_active <= 1'b1;

            // TODO: do we need all this duplicate resetting logic?
            flash_wen <= 1'b0;
            flash_addr <= 0;

            addr_base <= 0;
            addr_base_byte_idx <= 0;
            msg_len <= 0;
            msg_len_byte_idx <= 0;
            byte_idx <= 0;
          end
        end
        ADDRESS: begin
          if (uart_rx_valid) begin
            addr_base <= { uart_rx_byte, addr_base[31:8] };
            addr_base_byte_idx <= addr_base_byte_idx + 1;
            if (addr_base_byte_idx == 3) begin
              state <= LENGTH;
            end
          end
        end
        LENGTH: begin
          if (uart_rx_valid) begin
            // Get next byte in length message
            msg_len <= { uart_rx_byte, msg_len[31:8] };
            msg_len_byte_idx <= msg_len_byte_idx + 1;
            if (msg_len_byte_idx == 3) begin
              state <= BYTESTREAM;
            end
          end
        end
        BYTESTREAM: begin
          // Round message length down
          msg_len <= { msg_len[31:2], 2'b00 };

          if (flash_wen) begin
            flash_wen <= 1'b0;
          end

          // Record the bytes
          if (uart_rx_valid) begin
            // Shift in byte
            flash_data <= { uart_rx_byte, flash_data[31:8] };

            // Enable writing if we just finished a word
            if ((byte_idx & 2'b11) == 2'b11) begin
              flash_wen <= 1'b1;

              // WORD address!
              // Don't need the -3, technically, because
              //   addr_base % 4 == 0 and byte_idx % 4 == 3
              flash_addr <= (addr_base + byte_idx - 3) >> 2;
            end

            // Increment counter and end if at end
            byte_idx <= byte_idx + 1;
            if (byte_idx + 1 >= addr_base + msg_len) begin
              state <= IDLE;
              flash_active <= 1'b0;
            end
          end
        end
      endcase
    end
  end

endmodule

`default_nettype wire
