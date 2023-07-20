module ROM(clk, addr, data_out);

    input [15:0] addr;
    output reg [15:0] data_out

    reg [15:0] mem [0:1023];

    always @(posedge)
        data_out <= mem[addr]

    initial
    begin
        mem[16'h0000] = 16'h0;
        mem[16'h0001] = 16'h0;
        mem[16'h0002] = 16'h0;
        mem[16'h0003] = 16'h0;
        mem[16'h0004] = 16'h0;
        mem[16'h0005] = 16'h0;
        mem[16'h0007] = 16'h0;
        mem[16'h0008] = 16'h0;
        mem[16'h0009] = 16'h0;
        mem[16'h000a] = 16'h0;
        mem[16'h000b] = 16'h0;

    end

endmodule