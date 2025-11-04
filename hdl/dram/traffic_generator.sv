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
        input wire [15:0]    write_axis_data,
        input wire [23:0]    write_axis_addr,
        input wire           write_axis_tlast,
        input wire           write_axis_valid,
        output logic         write_axis_ready,

        output logic [5:0] debug,

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

    assign write_axis_ready = !memrequest_busy && (
      (state == WB_RTX) && 
      ((req_type == READ_FETCH_RTX) ||
      (req_type == READ_FETCH_RTX_OW)));

    // Not an AXI-Stream, but the signals that define when we actually issue a read request.

    logic read_request_valid; // defined further below, based on state machine + address info
    assign read_request_valid = ~read_axis_af && state == RD_HDMI;
    logic read_request_ready;
    assign read_request_ready = !memrequest_busy && state == RD_HDMI;

    localparam MAX_ADDR_READ = 115200;
    localparam MAX_WRITE_COUNT = 921600;

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
    evt_counter #(.MAX_COUNT(MAX_WRITE_COUNT)) w_counter (
        .clk(clk),
        .rst(rst),
        .evt(write_axis_ready && write_axis_valid),
        .count(pixels_written_counter)
    );

    // count how many frames have been written total
    logic [15:0] frame_count;
    evt_counter #(.MAX_COUNT(8)) frame_counter (
        .clk(clk),
        .rst(rst),// || (write_axis_ready && write_axis_valid && write_axis_tlast &&
        //   pixels_written_counter == 0)),
        .evt(write_axis_ready && write_axis_valid && (write_axis_addr == 0)),
        .count(frame_count)
    );

    // Feed the read output from the memory controller to the axi-stream output
    // the queued_command_write_enable won't be set until you've instantiated your FIFO below.
    assign read_axis_valid = memrequest_complete && (queued_command_req_type == READ_HDMI);
    assign read_axis_data = memrequest_resp_data;

    logic [23:0] rtx_fetch_addr;
    assign rtx_fetch_addr = (write_axis_addr >> 1) | {3'b001, 21'b0};
    
    logic fetch_rtx_req_complete;
    assign fetch_rtx_req_complete = (memrequest_complete && (
      (queued_command_req_type == READ_FETCH_RTX) ||
      (queued_command_req_type == READ_FETCH_RTX_OW)));
    logic overwrite;
    assign overwrite = queued_command_req_type == READ_FETCH_RTX_OW;

    // fetch request complete, do math and either writeback or queue a writeback
    logic [20:0] fetched_red;
    logic [21:0] fetched_green;
    logic [20:0] fetched_blue;
    logic [127:0] repacked_rtx_data;

    logic [20:0] added_red;
    logic [21:0] added_green;
    logic [20:0] added_blue;
    assign added_red = overwrite ? queued_command_data[4:0] : fetched_red + queued_command_data[4:0];
    assign added_green = overwrite ? queued_command_data[10:5] : fetched_green + queued_command_data[10:5];
    assign added_blue = overwrite ? queued_command_data[15:11] : fetched_blue + queued_command_data[15:11];

    logic [63:0] added_color;
    assign added_color = {added_blue, added_green, added_red};

    always_comb begin
      // only operate on the relevant one of the packed data 
      if (queued_command_address[0]) begin
        fetched_red = memrequest_resp_data[20:0];
        fetched_green = memrequest_resp_data[42:21];
        fetched_blue = memrequest_resp_data[63:43];
        repacked_rtx_data = {memrequest_resp_data[127:64], added_color};
      end else begin
        fetched_red = memrequest_resp_data[80:64];
        fetched_green = memrequest_resp_data[106:85];
        fetched_blue = memrequest_resp_data[127:107];
        repacked_rtx_data = {added_color, memrequest_resp_data[63:0]};
      end
    end

    // FIFO to store build up wb_rtx requests when:
    // -a response is received while mem is busy
    // -a response is received but another wb had more priority
    logic wb_rtx_needed;
    assign wb_rtx_needed = fetch_rtx_req_complete || !wb_rtx_fifo_empty;
    
    logic wb_rtx_fifo_full;
    logic wb_rtx_fifo_empty;
    logic [23:0] queued_wb_rtx_address;
    logic [127:0] queued_wb_rtx_data;
    logic can_issue_immediate_wb_rtx;
    assign can_issue_immediate_wb_rtx = (
      req_type == WRITE_BACK_RTX &&
      !memrequest_busy && 
      wb_rtx_fifo_empty && 
      wb_fb_fifo_empty && 
      !fetch_fb_req_complete);
    command_fifo #(.DEPTH(8),.WIDTH(152)) wb_rtx_fifo (
        .clk(clk),
        .rst(rst),
        .write(fetch_rtx_req_complete && !can_issue_immediate_wb_rtx),
        .command_in({queued_command_address, repacked_rtx_data}),
        .full(wb_rtx_fifo_full),

        .command_out({queued_wb_rtx_address, queued_wb_rtx_data}),
        .read((req_type == WRITE_BACK_RTX) && memrequest_en),
        .empty(wb_rtx_fifo_empty)
    );

    logic [127:0] rtx_wb_data; // the full data, including other one packed with it
    assign rtx_wb_data = can_issue_immediate_wb_rtx ? repacked_rtx_data : queued_wb_rtx_data;
    logic [23:0] rtx_wb_addr; // the address it tells the memory module
    assign rtx_wb_addr = (can_issue_immediate_wb_rtx ? 
      queued_command_address >> 1 : queued_wb_rtx_address >> 1) | {3'b001, 21'b0};

    // average the data if frame is a power of 2
    logic [3:0] shift_amt;
    logic frame_power_of_2;
    always_comb begin
      // how much to shift the result if a frame buffer writeback is also needed
      frame_power_of_2 = 1;
      shift_amt = 0;
      // case (frame_count)
      //   1: begin
      //     shift_amt = 0;
      //     frame_power_of_2 = 1;
      //   end
      //   2: begin
      //     shift_amt = 1;
      //     frame_power_of_2 = 1;
      //   end
      //   4: begin
      //     shift_amt = 2;
      //     frame_power_of_2 = 1;
      //   end
      //   8: begin
      //     shift_amt = 3;
      //     frame_power_of_2 = 1;
      //   end
      //   16: begin
      //     shift_amt = 4;
      //     frame_power_of_2 = 1;
      //   end
      //   32: begin
      //     shift_amt = 5;
      //     frame_power_of_2 = 1;
      //   end
      //   64: begin
      //     shift_amt = 6;
      //     frame_power_of_2 = 1;
      //   end
      //   128: begin
      //     shift_amt = 7;
      //     frame_power_of_2 = 1;
      //   end
      //   256: begin
      //     shift_amt = 8;
      //     frame_power_of_2 = 1;
      //   end
      //   512: begin
      //     shift_amt = 9;
      //     frame_power_of_2 = 1;
      //   end
      //   1024: begin
      //     shift_amt = 10;
      //     frame_power_of_2 = 1;
      //   end
      //   2048: begin
      //     shift_amt = 11;
      //     frame_power_of_2 = 1;
      //   end
      //   4096: begin
      //     shift_amt = 12;
      //     frame_power_of_2 = 1;
      //   end
      //   8192: begin
      //     shift_amt = 13;
      //     frame_power_of_2 = 1;
      //   end
      //   16384: begin
      //     shift_amt = 14;
      //     frame_power_of_2 = 1;
      //   end
      //   32768: begin
      //     shift_amt = 15;
      //     frame_power_of_2 = 1;
      //   end
      //   default begin
      //     shift_amt = 0;
      //     frame_power_of_2 = 0;
      //   end
      // endcase
    end

    logic [4:0] avg_red;
    logic [5:0] avg_green;
    logic [4:0] avg_blue;
    logic [15:0] avg_color;
    assign avg_red = fetched_red >> shift_amt;
    assign avg_green = fetched_green >> shift_amt;
    assign avg_blue = fetched_blue >> shift_amt;
    assign avg_color = {avg_blue, avg_green, avg_red};    

    // queue for fetch commands to be sent for the frame buffer
    logic fetch_fb_fifo_full;
    logic fetch_fb_fifo_empty;

    logic fetch_fb_queued;
    logic [23:0] queued_fetch_fb_address;
    logic [15:0] queued_fetch_fb_data;

    // saved the queued fb data to be written once there is free time
    // queues the command as soon as a new average is calculated
    command_fifo #(.DEPTH(8),.WIDTH(40)) fetch_fb_fifo(
        .clk(clk),
        .rst(rst),
        .write(frame_power_of_2 && fetch_rtx_req_complete),
        .command_in({ queued_command_address, avg_color }),
        .full(fetch_fb_fifo_full),

        .command_out({ queued_fetch_fb_address, queued_fetch_fb_data }),
        .read((req_type == READ_FETCH_FB) && memrequest_en),
        .empty(fetch_fb_fifo_empty)
    );
    logic fetch_fb_needed;
    assign fetch_fb_needed = ~fetch_fb_fifo_empty;
    logic [23:0] fb_fetch_addr; // the address it tells the memory module
    assign fb_fetch_addr = queued_fetch_fb_address >> 3;

    // FIFO to store build up wb_rtx requests when:
    // -a response is received while mem is busy
    // -a response is received but another wb had more priority
    logic fetch_fb_req_complete;
    assign fetch_fb_req_complete = (memrequest_complete && queued_command_req_type == READ_FETCH_FB);

    // replace that singular color with the new averaged one
    logic [127:0] repacked_fb_data;
    always_comb begin
      repacked_fb_data = memrequest_resp_data;
      // repacked_fb_data = {
      //   queued_command_data,
      //   queued_command_data,
      //   queued_command_data,
      //   queued_command_data,
      //   queued_command_data,
      //   queued_command_data,
      //   queued_command_data,
      //   queued_command_data
      // };
      case (queued_command_address[2:0])
        3'b000: repacked_fb_data[15:0] = queued_command_data;
        3'b001: repacked_fb_data[31:16] = queued_command_data;
        3'b010: repacked_fb_data[47:32] = queued_command_data;
        3'b011: repacked_fb_data[63:48] = queued_command_data;
        3'b100: repacked_fb_data[79:64] = queued_command_data;
        3'b101: repacked_fb_data[95:80] = queued_command_data;
        3'b110: repacked_fb_data[111:96] = queued_command_data;
        3'b111: repacked_fb_data[127:112] = queued_command_data;

        // 3'b111: repacked_fb_data[15:0] = queued_command_data;
        // 3'b110: repacked_fb_data[31:16] = queued_command_data;
        // 3'b101: repacked_fb_data[47:32] = queued_command_data;
        // 3'b100: repacked_fb_data[63:48] = queued_command_data;
        // 3'b011: repacked_fb_data[79:64] = queued_command_data;
        // 3'b010: repacked_fb_data[95:80] = queued_command_data;
        // 3'b001: repacked_fb_data[111:96] = queued_command_data;
        // 3'b000: repacked_fb_data[127:112] = queued_command_data;
      endcase
    end

    logic wb_fb_needed;
    assign wb_fb_needed = fetch_fb_req_complete || !wb_fb_fifo_empty;
    
    logic wb_fb_fifo_full;
    logic wb_fb_fifo_empty;
    logic [23:0] queued_wb_fb_address;
    logic [127:0] queued_wb_fb_data;
    logic can_issue_immediate_wb_fb;
    assign can_issue_immediate_wb_fb = (
      req_type == WRITE_BACK_FB &&
      !memrequest_busy && 
      wb_fb_fifo_empty);
    command_fifo #(.DEPTH(32),.WIDTH(152)) wb_fb_fifo (
        .clk(clk),
        .rst(rst),
        .write(fetch_fb_req_complete && !can_issue_immediate_wb_fb),
        .command_in({queued_command_address, repacked_fb_data}),
        .full(wb_fb_fifo_full),

        .command_out({queued_wb_fb_address, queued_wb_fb_data}),
        .read((req_type == WRITE_BACK_FB) && memrequest_en),
        .empty(wb_fb_fifo_empty)
    );

    logic [127:0] fb_wb_data; // the full data, including other ones packed with it
    assign fb_wb_data = can_issue_immediate_wb_fb ? repacked_fb_data : queued_wb_fb_data;
    logic [23:0] fb_wb_addr; // the address it tells the memory module
    assign fb_wb_addr = (can_issue_immediate_wb_fb ? 
      queued_command_address >> 3 : queued_wb_fb_address >> 3);

    typedef enum bit [2:0] { 
      NONE,           // no request
      READ_HDMI,      // read 8 packed hdmi values
      READ_FETCH_RTX, // read 1 of 2 packed rtx buffer values
      READ_FETCH_RTX_OW, // same as last, but overwrite instead of adding
      WRITE_BACK_RTX, // writeback 1 of 2 packed rtx buffer values
      READ_FETCH_FB,  // read 8 packed frame buffer values
      WRITE_BACK_FB   // writeback 1 of 8 packed frame buffer values
     } memreq_type;
    memreq_type req_type;

    // logic to determine what the current command should be
    // priority goes to wb rtx -> wb fb -> fetch rtx -> fetch fb
    //
    always_comb begin
      if (state == RD_HDMI) begin
        req_type = READ_HDMI;
      end else if (state == WB_RTX) begin
        if (wb_fb_needed) begin
          req_type = WRITE_BACK_FB;
        end else if (wb_rtx_needed) begin
          req_type = WRITE_BACK_RTX;
        end else begin
          if (fetch_fb_needed) begin
            req_type = READ_FETCH_FB;
          end else if (write_axis_valid) begin
            //TODO fix always overwriting, temp debugging
            req_type = write_axis_tlast ? READ_FETCH_RTX_OW : READ_FETCH_RTX;
          end else begin
            req_type = NONE;
          end
        end 
      end else begin
        req_type = NONE;
      end
    end

    // Your command FIFO, getting used to write down commands
    logic cf_full;
    logic cf_empty;
    logic [23:0] queued_command_address;
    logic [15:0] queued_command_data;
    logic [23:0] req_address;
    logic [15:0] req_data;
    always_comb begin
      case (req_type)
        READ_HDMI: begin
          req_address = read_request_address;
          req_data = 0;
        end
        READ_FETCH_RTX: begin
          req_address = write_axis_addr;
          req_data = write_axis_data;
        end
        READ_FETCH_RTX_OW: begin
          req_address = write_axis_addr;
          req_data = write_axis_data;
        end
        READ_FETCH_FB: begin
          req_address = queued_fetch_fb_address;
          req_data = queued_fetch_fb_data;
        end
        WRITE_BACK_RTX: begin
          req_address = rtx_wb_addr;
          req_data = 0;
        end
        WRITE_BACK_FB: begin
          req_address = fb_wb_addr;
          req_data = 0;
        end
        default: begin
          req_address = 0;
          req_data = 0;
        end
      endcase
    end
    memreq_type queued_command_req_type;
    
    command_fifo #(.DEPTH(64),.WIDTH(43)) mcf(
        .clk(clk),
        .rst(rst),
        .write(memrequest_en && !memrequest_busy),
        .command_in({ req_address, req_data, req_type }),
        .full(cf_full),

        .command_out({ queued_command_address, queued_command_data, queued_command_req_type }),
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

    assign debug[0] = (state == WB_RTX) && memrequest_en;
    assign debug[1] = (req_type == READ_FETCH_RTX_OW || req_type == READ_FETCH_RTX) && write_axis_data != 0;

    assign debug[5] = req_type == READ_FETCH_FB && queued_fetch_fb_data == 0;
    // assign debug[2] = fetch_fb_req_complete && req_type == WRITE_BACK_FB; //immediately send wb
    // assign debug[3] = fetch_fb_req_complete && !memrequest_busy;
    // assign debug[4] = fetch_fb_req_complete && wb_fb_fifo_empty;
    // assign debug[5] = fetch_fb_req_complete && !can_issue_immediate_wb_fb && repacked_fb_data == 0;
    // assign debug[5] = req_type == WRITE_BACK_FB && fb_wb_data
    // assign debug[5:2] = frame_count;

    // communication signals to send to the controller in each state; assigned combinationally
    always_comb begin
      case(state)
        RST, WAIT_INIT: begin
            memrequest_addr = 0;
            memrequest_en = 0;
            memrequest_write_data = 0;
            memrequest_write_enable = 0;
        end
        WB_RTX: begin
          case (req_type)
            READ_FETCH_RTX: begin // read 1 of 2 packed rtx buffer values
              memrequest_addr = rtx_fetch_addr;
              memrequest_en = write_axis_valid && !memrequest_busy;
              memrequest_write_enable = 0;
              memrequest_write_data = 0;
            end
            READ_FETCH_RTX_OW: begin // read 1 of 2 packed rtx buffer values
              memrequest_addr = rtx_fetch_addr;
              memrequest_en = write_axis_valid && !memrequest_busy;
              memrequest_write_enable = 0;
              memrequest_write_data = 0;
            end
            WRITE_BACK_RTX: begin // writeback 1 of 2 packed rtx buffer values
              memrequest_addr = rtx_wb_addr;
              memrequest_en = !memrequest_busy;
              memrequest_write_enable = !memrequest_busy;
              memrequest_write_data = rtx_wb_data;
            end
            READ_FETCH_FB: begin  // read 8 packed frame buffer values
              memrequest_addr = fb_fetch_addr;
              memrequest_en = !memrequest_busy;
              memrequest_write_enable = 0;
              memrequest_write_data = 0;
            end
            WRITE_BACK_FB: begin  // writeback 1 of 8 packed frame buffer values
              memrequest_addr = fb_wb_addr;
              memrequest_en = !memrequest_busy;
              memrequest_write_enable = !memrequest_busy;
              memrequest_write_data = fb_wb_data;
            end
            default: begin
              memrequest_addr = 0;
              memrequest_en = 0;
              memrequest_write_enable = 0;
              memrequest_write_data = 0;
            end
          endcase
        end
        RD_HDMI: begin
            memrequest_addr = read_request_address;
            memrequest_en = read_request_valid && !memrequest_busy;
            memrequest_write_enable = 0;
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
