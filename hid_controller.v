`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// DegicLab - Da Nang - Vietnam
// Engineer: Admin
// degic.center@gmail.com
// +84 935 737 800
// 
// Create Date: 04/25/2019 07:00:14 PM
// Design Name: 
// Module Name: hid_controller
// Project Name: HID Demo
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// HID controller
// version  1

// History
/*20190425: 
 - initial version
 - parity:   not yet
 - data decode:  not yet
 - data saving:  not yet
 - action: not yet
*/

`define IDLE        4'd0
`define DATA_ST     4'd1
`define DATA_HI     4'd2
`define DATA_LO     4'd3
`define PARI_HI     4'd4
`define PARI_LO     4'd5
`define STOP_HI     4'd6
`define STOP_LO     4'd7

`define CAP_CNT  10'd1000

module hid_controller (
  input wire        dspclk,
  input wire        reset,
  input wire        hid_clk,
  input wire        hid_dat,
  output reg        pari_err,
  output reg [7:0]  led
  );
  
reg             clk_sync0, clk_sync;
reg             dat_sync0, dat_sync;
reg     [9:0]   dsp_counter;
reg     [3:0]   state;
reg     [3:0]   next;
reg     [2:0]   cnt;
reg             rec_pari;

wire data_capture;
wire pari_capture;

always @ ( posedge dspclk or posedge reset ) begin
    if (reset == 1'b1 ) begin 
        clk_sync0   <=  1'b1;
        clk_sync    <=  1'b1;
        dat_sync0   <=  1'b1;
        dat_sync    <=  1'b1;
    end
    else begin
        clk_sync0   <=  hid_clk;
        clk_sync    <=  clk_sync0; 
        dat_sync0   <=  hid_dat;
        dat_sync    <=  dat_sync0;
 end
end

// capture counter
always @(posedge dspclk or posedge reset) begin
    if (reset == 1'b1)
        dsp_counter <= 10'd0;
    else begin
        if (state == `DATA_LO || state == `PARI_LO || state == `STOP_LO) begin 
            if (dsp_counter <= `CAP_CNT)    dsp_counter  <= dsp_counter + 10'd1;
            else                            dsp_counter  <= dsp_counter;
        end
        else                                dsp_counter  <= 10'd0;
    end
end

// state machine:
 always @ (posedge dspclk or posedge reset) begin
  if ( reset == 1'b1 ) state  <= `IDLE;
  else      state <=  next;
 end

// Next state 
always @ (*) begin
    case (state) 
        `IDLE:      if ( !clk_sync && !dat_sync )   next = `DATA_ST;
                    else                            next = `IDLE;
        `DATA_ST:   if ( clk_sync )                 next = `DATA_HI;
                    else                            next = `DATA_ST;
        `DATA_HI:   if ( !clk_sync )                next = `DATA_LO;
                    else                            next = `DATA_HI;
        `DATA_LO:   if ( clk_sync ) begin
                        if (cnt < 3'd7 )            next = `DATA_HI;
                        else                        next = `PARI_HI;
                    end         
                    else                            next = `DATA_LO;
        `PARI_HI:   if ( !clk_sync )                next = `PARI_LO;
                    else                            next = `PARI_HI;
        `PARI_LO:   if ( clk_sync )                 next = `STOP_HI;
                    else                            next = `PARI_LO;
        `STOP_HI:   if ( !clk_sync )                next = `STOP_LO;
                    else                            next = `STOP_HI;
        `STOP_LO:   if ( clk_sync )                 next = `IDLE;
                    else                            next = `STOP_LO;
        default:                                    next = `IDLE;      
    endcase
end

// DegicLab - Da Nang - Vietnam
// Engineer: Admin
// degic.center@gmail.com
// https://degiclab.blogspot.com/

 assign data_capture = ((state == `DATA_LO ) && (dsp_counter == `CAP_CNT)) ? 1'b1 : 1'b0;
 assign pari_capture = ((state == `PARI_LO ) && (dsp_counter == `CAP_CNT)) ? 1'b1 : 1'b0;
 
//bit counter
reg [7:0]   key_code;
always @ (posedge dspclk or posedge reset ) begin
    if (reset == 1'b1 ) begin  
        cnt         <=  3'd0;
    end
    else  begin 
        if ( state == `DATA_LO && clk_sync ) begin 
            cnt             <=  cnt + 3'd1;
        end
    end
end

always @ (posedge dspclk or posedge reset ) begin
    if (reset == 1'b1 ) begin  
        key_code    <=  8'h00;
    end
    else begin
        if (data_capture) begin
            case (cnt)
                3'd0: key_code   <=  {key_code[7:1], dat_sync};
                3'd1: key_code   <=  {key_code[7:2], dat_sync, key_code[0]};
                3'd2: key_code   <=  {key_code[7:3], dat_sync, key_code[1:0]};
                3'd3: key_code   <=  {key_code[7:4], dat_sync, key_code[2:0]};
                3'd4: key_code   <=  {key_code[7:5], dat_sync, key_code[3:0]};
                3'd5: key_code   <=  {key_code[7:6], dat_sync, key_code[4:0]};
                3'd6: key_code   <=  {key_code[7], dat_sync, key_code[5:0]};
                3'd7: key_code   <=  {dat_sync, key_code[6:0]};
            endcase 
         end
     end
end 
// DegicLab - Da Nang - Vietnam
// Engineer: Admin
// degic.center@gmail.com
// https://degiclab.blogspot.com/

  
//parity
wire cal_pari;
assign cal_pari = ~(((key_code[0] ^ key_code[1] ) ^ (key_code[2] ^ key_code[3] )) ^ ((key_code[4] ^ key_code[5] ) ^ (key_code[6] ^ key_code[7] )));


always @ ( posedge dspclk or posedge reset ) begin
    if ( reset == 1'b1 ) begin
        rec_pari        <= 1'b0;
    end
    else begin
        if ( pari_capture == 1'b1 ) begin
            rec_pari    <= dat_sync;
        end
    end 
end


// pari error 
always @ ( posedge dspclk or posedge reset ) begin
    if ( reset == 1'b1 ) begin
        pari_err    <= 1'b0; 
    end
    else begin
        if ( state == `STOP_LO ) begin
            if ( cal_pari == rec_pari ) begin 
                pari_err    <= 1'b0;
            end 
            else begin
                pari_err    <= 1'b1;
            end
        end
    end 
end

// LED
always @ ( posedge dspclk or posedge reset ) begin
    if ( reset == 1'b1 ) begin
        led     <= 8'h00; 
    end 
    else begin
        if (state == `STOP_LO ) begin
            if (key_code != 8'hF0) begin 
                led <= key_code;
            end
        end  
    end
end

endmodule
