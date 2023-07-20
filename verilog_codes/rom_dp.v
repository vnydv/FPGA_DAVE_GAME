module RAM_DP(clk, addr1, din1, dout1, we1, addr2, din2, dout2, we2);
  
  parameter A = 16; // # of address bits
  parameter D = 16;  // # of data bits
  
  input  clk;		// clock
  input  [A-1:0] addr1;	// address
  input  [A-1:0] addr2;	// address
  input  [D-1:0] din1;	// data input
  input  [D-1:0] din2;	// data input
  input  we1;		// write enable
  input  we2;		// write enable
  
  output reg [D-1:0] dout1;	// data output
  output reg [D-1:0] dout2;	// data output
  
  // using 2 KB of RAM - 
  reg [D-1:0] mem [0:2047]; // (1<<A)xD bit memory
  
  always @(posedge clk) begin
    if (we1)		// if write enabled
      mem[addr1[11:0]] <= din1;	// write memory from din
    dout1 <= mem[addr1[11:0]];	// read memory to dout (sync)
    
    if (we2)		// if write enabled
      mem[addr2[11:0]] <= din2;	// write memory from din
    dout2 <= mem[addr2[11:0]];	// read memory to dout (sync)
  end

endmodule