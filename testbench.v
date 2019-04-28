`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/25/2019 10:22:31 PM
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench();

    reg         dspclk;
    reg         reset;
    reg         hid_clk;
    reg         hid_dat;
    wire [7:0]  led;
    wire        pari_err;
    
    integer k = 0 ;
    integer i = 0 ;
          //integer j;
  
  hid_controller dut (  
  dspclk,
  reset,
  hid_clk,
  hid_dat,
  pari_err,
  led
  );
  
  always begin
        #5; dspclk = !dspclk; 
  end
  
  initial begin
     dspclk  = 1'b0;
     reset   = 1'b0;
     hid_clk = 1'b1;
     hid_dat = 1'b1;
  end
  
  initial begin
    // reset 
    #100; reset = 1'b1;
    #100; reset = 1'b0;
    #100;
    
    // test
    delay(1000); //1ms
    key_send(8'h1C);
    delay(1000); //1ms
    key_send(8'h1C);  delay(10);
    key_send(8'hF0);  key_send(8'h1C);  
  end
    
task key_send;
      input [7:0] data;
        begin
            // start
            hid_dat = 1'b0;     delay(8'd20);
            hid_clk = 1'b0;     delay(8'd40);
            // data
            for (k = 0; k < 8; k = k + 1 ) begin
                hid_clk = 1'b1;     delay(8'd5);
                hid_dat = data[k];  delay(8'd35);
                hid_clk = 1'b0;     delay(8'd40);                
            end
            // parity
                hid_clk = 1'b1;     delay(8'd5);
                hid_dat = 1'b0;     delay(8'd35);
                hid_clk = 1'b0;     delay(8'd40);
            // stop
                hid_clk = 1'b1;     delay(8'd5);
                hid_dat = 1'b1;     delay(8'd35);
                hid_clk = 1'b0;     delay(8'd40);  
                hid_clk = 1'b1;     delay(8'd40);           
        end
endtask

task delay;
    input [7:0] usecond;
        begin
            for ( i = 0; i < usecond; i = i + 1) begin
                #1000;
            end
            //i = 0;
        end 
endtask

endmodule

