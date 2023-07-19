module CPU16(clk, reset, hold, busy,
             address, data_in, data_out, write);

    input             clk;
    input             reset;
    input	            hold;
    output reg        busy;
    output reg [15:0] address;
    input      [15:0] data_in;
    output reg [15:0] data_out;
    output reg        write;

    reg [15:0] regs[0:10]; // 10 16-bit registers  
    localparam SP = 6; 
    localparam IP = 7; 
    localparam zero = 9;
    localparam one = 10;

    reg [2:0] state; // CPU state
    // CPU states
    localparam S_RESET   = 0;
    localparam S_SELECT  = 1;
    localparam S_DECODE  = 2;
    localparam S_COMPUTE = 3;
    localparam S_DECODE_WAIT = 4;
    localparam S_COMPUTE_WAIT = 5;
    
    reg lessThan;	// less than flag
    reg equal;	// equal flag

    // for ALU
    wire [15:0] Y;	// ALU 16-bit output
    reg [3:0] aluop;	// ALU operation

    reg [15:0] opcode; // to decode ALU inputs 
    wire [3:0] rdest = opcode[5:2];
    wire [3:0] rsrc = opcode[9:6];
    wire Bconst = opcode[10]  // ALU B = 10 bit constant
    wire Bload = opcode[11]   // ALU B = data_bus to get data in
  
    ALU alu(
        .A(regs[rdest]),
        .B(Bconst ? {6'b0, opcode[9:0]}
            : Bload ? data_in 
                    : regs[rsrc]),
        .Y(Y),
        .aluop(aluop));

    always @(posedge clk)
        if (reset)
            begin
                state <= S_RESET;
                busy <= 1;
            end
        else begin
            case(state)
                // state 0: reset/begin new
                S_RESET: begin
                    regs[IP] <=16'h0;
                    write <= 0;
                    state <= S_SELECT;
                end
                // state 1: select opcode address
                S_SELECT: begin
                    write <= 0;
                    if (hold) begin
                        busy <= 1;
                        state <= S_SELECT;
                    end else begin
                        busy <=0;
                        address <= regs[IP];
                        regs[IP] <= regs[IP] + 1;
                        state <= RAM_WAIT ? S_DECODE_WAIT : S_DECODE;
                    end 
                end
                // state 2: read/decode opcode
                S_DECODE: begin
                    state <= RAM_WAIT && data_in[11] ? S_COMPUTE_WAIT : S_COMPUTE;
                    casez (data_in)
                        //  1001aaaabbbb0000	operation (add) A B, A+B->A
                        16'b1001????????0000: 
                        // logical neg, AND, OR, XOR
                        16'b1011????????0000:
                        16'b1100????????0000: 
                        16'b1101????????0000:
                        16'b1110????????0000:begin
                            aluop <= data_in[15:12];
                        end
                        // operation A -> mem16[#]
                        16'b0001????????????:begin                            
                            address <= data_in[15:12];
                            data_out <= regs[0];
                            write <= 1;
                            state <= S_SELECT;
                        end
                        // operation B -> mem16[#]
                        16'b0010????????????:begin                            
                            address <= data_in[15:12];
                            data_out <= regs[1];
                            write <= 1;
                            state <= S_SELECT;
                        end
                        // operation mv R1 R2, R1 -> R2
                        16'b0100????????0000:begin
                            regs[data[11:8]] <= regs[data[7:4]]
                        end
                    endcase
                end
                // state 3: compute ALU output and flags
                S_COMPUTE: begin
                    // send Y to destination register
                    regs[rdest] <= Y[15:0];
                    // set flags
                    lessThan = Y[15];
                    equal = Y[14];
                end

                // wait 1 cycle for RAM read
                S_DECODE_WAIT: begin
                    state <= S_DECODE;
                end
                S_COMPUTE_WAIT: begin
                    state <= S_COMPUTE;
            endcase
        end

endmodule