`timescale 1ns / 1ps
`default_nettype none

/*
 * traffic_generator
 *
 * Module to provide the memory interface IP with the signals it needs,
 * decides what commands are issued in what order. Arbitrates between
 * write requests issued by write_axis, and read requests cycling through
 * the 720p frame buffer, whose responses are fed into read_axis.
 *
 * We've provided the state machine that manages the arbitration between
 * these requests, and the connections to each AXI-Stream. Your job is
 * to determine the address needed for each read and write request, likely
 * using some evt_counters!
 */

module traffic_generator(
        input wire           clk,      // should be ui clk of DDR3!
        input wire           rst,

        // UberDDR3 Control Signals
        output logic [23:0]  memrequest_addr,
        output logic         memrequest_en,
        output logic [127:0] memrequest_write_data,
        output logic         memrequest_write_enable,
        input wire [127:0]   memrequest_resp_data,
        input wire           memrequest_complete,
        input wire           memrequest_busy,
        // Write AXIS FIFO input
        input wire [15:0]   write_axis_data,
        input wire [23:0]    write_axis_addr,
        input wire           write_axis_tlast,
        input wire           write_axis_valid,
        output logic         write_axis_ready,
        // Read AXIS FIFO output
        output logic [127:0] read_axis_data,
        output logic         read_axis_tlast,
        output logic         read_axis_valid,
        input wire           read_axis_af, // almost full signal
        input wire           read_axis_ready
);


    // state machine used to alternate between read & write requests
    typedef enum {
        RST,
      	WAIT_INIT,
      	RD_HDMI,
        WB_RTX
    } tg_state;
    tg_state state;

    // Define ready/valid signals to output to our input+output AXI Streams!

    // give the write FIFO a "ready" signal when the MI is ready and our state machine
    // indicates it's the write AXIS' turn.

    assign write_axis_ready = !memrequest_busy && (state == WB_RTX) && !fetching_rtx;

    // Not an AXI-Stream, but the signals that define when we actually issue a read request.

    logic read_request_valid; // defined further below, based on state machine + address info
    assign read_request_valid = ~read_axis_af && state == RD_HDMI;
    logic read_request_ready;
    assign read_request_ready = !memrequest_busy && state == RD_HDMI;

    localparam MAX_ADDR_READ = 115200;
    localparam MAX_ADDR_WRITE = 460800;

    // read address tracker
    logic [23:0] read_request_address;
    evt_counter #(.MAX_COUNT(MAX_ADDR_READ)) r_addr_counter (
        .clk(clk),
        .rst(rst),
        .evt(read_request_ready && read_request_valid),
        .count(read_request_address)
    );

    // count how many pixels have been written to this frame
    logic [23:0] pixels_written_counter;
    evt_counter #(.MAX_COUNT(MAX_ADDR_WRITE)) w_counter (
        .clk(clk),
        .rst(rst),
        .evt(write_axis_ready && write_axis_valid),
        .count(pixels_written_counter)
    );

    // count how many frames have been written total
    logic [15:0] frame_count;
    evt_counter #(.MAX_COUNT(2**16)) frame_counter (
        .clk(clk),
        .rst(rst),
        .evt(write_axis_ready && write_axis_valid && (pixels_written_counter == 0)),
        .count(frame_count)
    );
    
    // Your command FIFO, getting used to write down commands
    logic cf_full;
    logic cf_empty;
    logic [23:0] queued_command_address;
    logic memreq_type queued_command_req_type;

    // Feed the read output from the memory controller to the axi-stream output
    // the queued_command_write_enable won't be set until you've instantiated your FIFO below.
    assign read_axis_valid = memrequest_complete && (queued_command_req_type == READ_HDMI);
    assign read_axis_data = memrequest_resp_data;
    
    logic [23:0] saved_rtx_addr;
    logic [15:0] saved_rtx_data;
    logic fetching_rtx;
    logic fetch_rtx_req_complete;
    assign fetch_rtx_req_complete = (memrequest_complete && queued_command_req_type == READ_FETCH_RTX);
    always_ff @(posedge clk) begin
      if (rst) begin
        fetching_rtx <= 0;
      end else begin
        // if consuming an rtx value from the fifo, it will fetch it first
        if (write_axis_ready && write_axis_valid) begin
          fetching_rtx <= 1;
        
        // finished fetching, no longer fetching
        end else if (fetch_rtx_req_complete) begin
          fetching_rtx <= 0;
        end
      end
    end

    // fetch request complete, do math and writeback this cycle
    logic [127:0] rtx_wb_data; // the full data, including other one packed with it
    logic [23:0] rtx_wb_addr; // the address it tells the memory module

    logic [20:0] fetched_red;
    logic [21:0] fetched_green;
    logic [20:0] fetched_blue;

    logic [3:0] shift_amt;
    logic frame_power_of_2;
    assign frame_power_of_2 = frame_count != 0 && (frame_count & (frame_count - 1)) == 0;
    always_comb begin
      // how much to shift the result if a frame buffer writeback is also needed
      shift_amt = 0
      if (frame_power_of_2) begin
        // disgusting shit to find shift amount assuming one-hot encoding
        shift_amt[0] = (
          frame_count[1] | 
          frame_count[3] |
          frame_count[5] |
          frame_count[7] |
          frame_count[9] |
          frame_count[11] |
          frame_count[13] |
          frame_count[15] );
        shift_amt[1] = (
          frame_count[2] | 
          frame_count[3] |
          frame_count[6] |
          frame_count[7] |
          frame_count[10] |
          frame_count[11] |
          frame_count[14] |
          frame_count[15] );
        shift_amt[2] = (
          frame_count[4] | 
          frame_count[5] |
          frame_count[6] |
          frame_count[7] |
          frame_count[12] |
          frame_count[13] |
          frame_count[14] |
          frame_count[15] );
        shift_amt[3] = (
          frame_count[8] | 
          frame_count[9] |
          frame_count[10] |
          frame_count[11] |
          frame_count[12] |
          frame_count[13] |
          frame_count[14] |
          frame_count[15] );
      end

      // only operate on the relevant one of the packed data 
      if (saved_rtx_addr[0]) begin
        fetched_red = memrequest_resp_data[20:0];
        fetched_green = memrequest_resp_data[42:21];
        fetched_blue = memrequest_resp_data[63:43];
        rtx_wb_data = {memrequest_resp_data[127:64], new_blue, new_green, new_red};
      end else begin
        fetched_red = memrequest_resp_data[80:64];
        fetched_green = memrequest_resp_data[106:85];
        fetched_blue = memrequest_resp_data[127:107];
        rtx_wb_data = {new_blue, new_green, new_red, memrequest_resp_data[63:0]};
      end
    end

    logic [20:0] new_red;
    logic [21:0] new_green;
    logic [20:0] new_blue;
    assign new_red = fetched_red + saved_rtx_data[4:0];
    assign new_green = fetched_green + saved_rtx_data[10:5];
    assign new_blue = fetched_blue + saved_rtx_data[15:11];

    logic [4:0] avg_red;
    logic [5:0] avg_green;
    logic [4:0] avg_blue;
    logic [15:0] avg_color;
    assign new_red = fetched_red >> shift_amt;
    assign new_green = fetched_green >> shift_amt;
    assign new_blue = fetched_blue >> shift_amt;
    assign avg_color = {avg_blue, avg_green, avg_red};

    // queue for fetch commands to be sent for the frame buffer
    logic fetch_fb_fifo_full;
    logic fetch_fb_fifo_empty;

    logic fetch_fb_queued;
    logic [23:0] fetch_fb_addr;
    logic [15:0] fetch_fb_data;
    logic fetch_fb_req_complete;
    assign fetch_fb_req_complete = (memrequest_complete && queued_command_req_type == READ_FETCH_FB);
    // saved the queued fb data to be written once there is free time
    // queues the command as soon as a new average is calculated
    command_fifo #(.DEPTH(8),.WIDTH(40)) fetch_frame_buffer_queue(
        .clk(clk),
        .rst(rst),
        .write(frame_power_of_2 && fetch_rtx_req_complete),
        .command_in({ saved_rtx_addr, avg_color }),
        .full(fetch_fb_fifo_full),

        .command_out({ fetch_fb_addr, fetch_fb_data }),
        .read(fetch_fb_req_complete),
        .empty(fetch_fb_fifo_empty)
    );
    assign fetch_fb_queued = ~fetch_fb_fifo_empty;

    // replace that singular color with the new averaged one
    logic [127:0] repacked_fb_data;
    always_comb begin
      repacked_fb_data = memrequest_resp_data;
      if (fetch_fb_req_complete) begin
        case (queued_command_address[2:0])
          3'b000: repacked_fb_data[15:0] = fetch_fb_data;
          3'b001: repacked_fb_data[31:16] = fetch_fb_data;
          3'b010: repacked_fb_data[47:32] = fetch_fb_data;
          3'b011: repacked_fb_data[63:48] = fetch_fb_data;
          3'b100: repacked_fb_data[79:64] = fetch_fb_data;
          3'b101: repacked_fb_data[95:80] = fetch_fb_data;
          3'b110: repacked_fb_data[111:96] = fetch_fb_data;
          3'b111: repacked_fb_data[127:112] = fetch_fb_data;
        endcase
      end
    end

    logic wb_fb_queued;
    logic [23:0] wb_fb_addr;
    logic [127:0] wb_fb_data;
    logic wb_fb_req_complete;
    assign wb_fb_req_complete = (memrequest_complete && (queued_command_req_type == WRITE_BACK_FB));
    always_ff @(posedge clk) begin
      if (rst) begin
        wb_fb_queued <= 0;
        wb_fb_addr <= 0;
        wb_fb_data <= 0;
      end else begin
        // just finished fetching, queue this write command
        if (fetch_fb_req_complete) begin
          wb_fb_queued <= 1;
          wb_fb_addr <= fetch_fb_addr;
          wb_fb_data <= repacked_fb_data;
        // data will get consumed this cycle
        end else if (req_type == WRITE_BACK_FB && !memrequest_busy) begin
          wb_fb_queued <= 0;
        end
      end
    end

    typedef enum { 
      NONE,           // no request
      READ_HDMI,      // read 8 packed hdmi values
      READ_FETCH_RTX, // read 1 of 2 packed rtx buffer values
      WRITE_BACK_RTX, // writeback 1 of 2 packed rtx buffer values
      READ_FETCH_FB,  // read 8 packed frame buffer values
      WRITE_BACK_FB   // writeback 1 of 8 packed frame buffer values
     } memreq_type;
    memreq_type req_type;

    // logic to determine what the current command should be
    // priority goes to wb rtx -> fetch rtx -> wb fb -> fetch fb
    //
    always_comb begin
      if (state == RD_HDMI) begin
        req_type = READ_HDMI;
      end else if (state == WB_RTX) begin
        // currently fetching an rtx value, so can't fetch a new one till this is written back
        if (fetching_rtx) begin

          // done fetching an rtx value, next command should immediately be write back
          if (fetch_rtx_req_complete) begin
            req_type = WRITE_BACK_RTX;

          // there is a queued writeback for fb
          end else if (wb_fb_queued) begin
            req_type = WRITE_BACK_FB;

          // nothing is queued for writeback, should fetch next fb value
          // second clause is to ensure u dont immediately fetch since there is a minimum
          // one-cycle delay after fetching from fb before writing back
          end else if (fetch_fb_queued && !fetch_fb_req_complete) begin
            req_type = READ_FETCH_FB;
          
          end else begin
            req_type = NONE;
          end

        // there is a new rtx value to fetch and it is safe to do so
        end else if (write_axis_valid && write_axis_ready) begin
          req_type = READ_FETCH_RTX;

        // nothing else to do, check for fb stuff
        end else begin
          // need to write smth back from fetching fb
          if (fetch_wb_queued) begin
            req_type = WRITE_BACK_FB;

          // need to fetch smth from fb
          end else if (fetch_fb_queued) begin
            req_type = READ_FETCH_FB;
          end else begin
            req_type = NONE;
          end
        end
      end else begin
        req_type = NONE;
      end
    end

    

    always_ff @(posedge clk) begin
      // AXI READY/VALID HANDSHAKE
      if (write_axis_valid && write_axis_ready) begin
        fetching_rtx <= 1;
        wb_addr <= write_axis_taddr;
        wb_data <= write_axis_data;
      end else if (fetching_rtx) begin
        // The fetch request is done, a write request will be sent this cycle
        // it is safe to give the fetch clear signal
        if (fetch_req_complete) begin
          fetching_rtx <= 0;
        end
      end
    end
    
    command_fifo #(.DEPTH(64),.WIDTH(27)) mcf(
        .clk(clk),
        .rst(rst),
        .write(memrequest_en && !memrequest_busy),
        .command_in({ memrequest_addr, req_type }),
        .full(cf_full),

        .command_out({ queued_command_address, queued_command_req_type }),
        .read(memrequest_complete),
        .empty(cf_empty)
    );
    
    assign read_axis_tlast = (queued_command_address == (MAX_ADDR_READ - 1));

    // -----------------------------------
    // For lab 06, no need to change anything below here!
    // but yes for ts :(
    
    // State Machine behavior
    
    // Signals for determining our conditions to switch between states:
    // By tying these signals to 1, we switch between issuing a read command
    // and a write command every clock cycle. The signals could be made
    // more complex in order to send commands in bursts, which could
    // increase throughput of data out of the memory chip.
    logic go_to_wr, go_to_rd, initialization_complete;
    assign go_to_wr = 1'b1;
    assign go_to_rd = 1'b1;
    assign initialization_complete = 1'b1;

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= RST;
        end else begin
            case(state)
                RST: begin
                    state <= WAIT_INIT;
                end
                WAIT_INIT: begin
                    state <= initialization_complete ? RD_HDMI : WAIT_INIT;
                end
                RD_HDMI: begin
                    state <= go_to_wr ? WB_RTX : RD_HDMI;
                end
                WB_RTX: begin
                    state <= go_to_rd ? RD_HDMI : WB_RTX;
                end
            endcase // case (state)
        end
    end

    //TODO somewhere idk but make sure to account for good data coming back WHILE memrequest_busy

    // communication signals to send to the controller in each state; assigned combinationally
    always_comb begin
      case(state)
        RST, WAIT_INIT: begin
            memrequest_addr = 0;
            memrequest_en = 0;
            memrequest_write_data = 0;
            memrequest_write_enable = 0;
        end
        WB_RTX: begin //TODO fix these
          case (memreq_type)
            READ_FETCH_RTX: begin // read 1 of 2 packed rtx buffer values
              memrequest_addr = write_address;
              memrequest_en = write_axis_valid && !memrequest_busy;
              memrequest_write_enable = write_axis_valid && !memrequest_busy;
              memrequest_write_data = write_axis_data;
            end
            WRITE_BACK_RTX: begin // writeback 1 of 2 packed rtx buffer values
              
            end
            READ_FETCH_FB: begin  // read 8 packed frame buffer values
              
            end
            WRITE_BACK_FB: begin  // writeback 1 of 8 packed frame buffer values
              
            end
          endcase
        end
        RD_HDMI: begin
            memrequest_addr = read_request_address;
            memrequest_en = read_request_valid && !memrequest_busy;
            memrequest_write_enable = 1'b0;
            memrequest_write_data = 0;
        end
        default: begin
            memrequest_addr = 0;
            memrequest_en = 0;
            memrequest_write_data = 0;
            memrequest_write_enable = 0;
        end
      endcase // case (state)
    end // always_comb
endmodule

`default_nettype wire
