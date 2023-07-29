
`include "hvsync_generator.v"

`define LOAD_HPOS 10'd260
`define LOAD_VPOS 10'd235
`define LOAD_BLOCK_SIZE 10'd20
`define LOAD_MAX_COUNT 4'd12

module test_hvsync_top(clk, reset, hsync, vsync, rgb,load_hpos_cval);

  input clk, reset;
  output hsync, vsync;
  output [2:0] rgb;
  wire display_on;
  wire [9:0] hpos;
  wire [9:0] vpos;
  
  wire vmaxxed = (vpos == 480) || reset;
  
  output [9:0] load_hpos_cval;
  reg [3:0] load_counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(0),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
  );
  
  always @(posedge vmaxxed)
  begin
    if (reset || load_counter == `LOAD_MAX_COUNT)
      load_counter <= 0;    
    else if (load_counter < `LOAD_MAX_COUNT)
      load_counter <= load_counter + 4'b1;      
  end
  
  assign load_hpos_cval = `LOAD_HPOS + load_counter * `LOAD_BLOCK_SIZE;
        
  wire isLoadingDisplay = (hpos > `LOAD_HPOS) && (hpos < load_hpos_cval) && 
  (vpos > `LOAD_VPOS) && (vpos < (`LOAD_VPOS + `LOAD_BLOCK_SIZE));
  
  wire r = 0;
  wire g = display_on && (isLoadingDisplay);
  wire b = 0;
  assign rgb = {b,g,r};

endmodule
