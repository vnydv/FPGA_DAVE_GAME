module CPU16(clk, reset, busy,
             address, data_in, data_out, write);

    input             clk;
    input             reset;
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
    reg DATA_WAIT;

    // for ALU
    wire [15:0] Y;	// ALU 16-bit output
    reg [3:0] aluop;	// ALU operation

    reg [15:0] opcode; // to decode ALU inputs 
    wire [3:0] rdest = (opcode[15:12] & 4'h1) ? 4'h0 
                            : (opcode[15:12] & 4'h3) ? 4'h1 
                                    : opcode[5:2];

    wire [3:0] rsrc = opcode[9:6];

    wire Bconst = ~^opcode[11:10]  // ALU B = 10 bit constant (for immediate values) else Bload
    wire Bload = opcode[11] & (~opcode[10])   // ALU B = data_bus to get data in else a register
  
    ALU alu(
        .A(regs[rdest]),
        .B(Bconst ? {6'b0, opcode[9:0]}
            : Bload ? data_in 
                    : regs[rsrc]),
        .Y(Y),
        .aluop(aluop));

    initial begin
        regs[one] = {16{1'b1}};
        regs[zero] = 16'b0;
    end

    always @(posedge clk)
        if (reset)
            begin
                state <= S_RESET;
            end
        else begin
            case(state)
                // state 0: reset/begin new
                S_RESET: begin
                    regs[IP] <=16'h0;
                    write <= 0;
                    busy <=0;
                    state <= S_SELECT;
                end
                // state 1: select opcode address
                S_SELECT: begin
                    write <= 0;
                    busy <=0;
                    address <= regs[IP];
                    regs[IP] <= regs[IP] + 1;
                end
                // state 2: read/decode opcode
                S_DECODE: begin
                    opcode <= data_in;
                    casez (data_in)
                        //  1001aaaabbbb0000	operation (add) A B, A+B->A
                        // cmp
                        16'b1001??????????00:
                        16'b1010??????????00:
                        // logical neg, AND, OR, XOR
                        16'b1011??????????00:
                        16'b1100??????????00: 
                        16'b1101??????????00:
                        16'b1110??????????00:begin
                            aluop <= data_in[15:12];
                            DATA_WAIT <= 0;
                            state <=S_COMPUTE;
                        end
                        // operation A -> mem16[#]
                        16'b00010???????????:begin                            
                            address <= data_in[10:0];
                            data_out <= regs[0];
                            write <= 1;
                            state <= S_SELECT;
                        end
                        // operation B -> mem16[#]
                        16'b00100???????????:begin                            
                            address <= data_in[11:0];
                            data_out <= regs[1];
                            write <= 1;
                            state <= S_SELECT;
                        end
                        // operation A -> mem16[#]
                        16'b00011???????????:begin                            
                            address <= regs[rsrc];
                            data_out <= regs[0];
                            write <= 1;
                            state <= S_SELECT;
                        end
                        // operation B -> mem16[#]
                        16'b00101???????????:begin                            
                            address <= regs[rsrc];
                            data_out <= regs[1];
                            write <= 1;
                            state <= S_SELECT;
                        end
                        // opertation lda_ram from mem10[#]
                        // opertation ldb_ram from mem10[#]
                        16'b000111??????????:
                        16'b001111??????????:begin
                            address <= data_in[9:0];
                            // load B
                            aluop <=4'h3;
                            state <= S_COMPUTE_WAIT;
                        end
                        // opertation lda_ram from reg
                        // opertation ldb_ram from reg
                        16'b000101????????0?:
                        16'b001101????????0?:begin
                            address <= regs[rsrc];
                            // load B
                            aluop <= 4'h3;
                            state <= S_COMPUTE_WAIT;
                        end
                        // opertation lda_rom from reg
                        // opertation ldb_rom from reg
                        16'b000101????????1?:
                        16'b001101????????1?:begin
                            address <= regs[rsrc];
                            busy <= 1;
                            // load B
                            aluop <=4'h3;
                            state <= S_COMPUTE_WAIT;
                        end
                        // operation mv R1 R2, R1 -> R2
                        16'b0100????????0000:begin
                            regs[rdest] <= regs[rsrc]
                            state <= S_SELECT;
                        end
                        // operation shift right
                        16'b100001????????0:begin
                            aluop <=4'h7;
                            state <= S_COMPUTE_WAIT;
                        end
                        // operation shift left
                        16'b100001????????1:begin
                            aluop <=4'h8;
                            state <= S_COMPUTE_WAIT;
                        end
                        // operation jmp mem10[#]
                        16'b011100?????????:begin
                            regs[IP] <= data_in[9:0];
                            state <= S_SELECT;
                        end
                        // operation jmp mem16[Reg]
                        16'b011101????00000:begin
                            regs[IP] <= regs[rdest];
                            state <= S_SELECT;
                        end
                        // operation beq mem16[Reg]
                        16'b010101????00000:begin
                            if (equal):
                                regs[IP] <= regs[rdest];
                            state <= S_SELECT;
                        end
                        // operation beq mem10[#]
                        16'b010100?????????:begin
                            if (equal):
                                regs[IP] <= data_in[9:0];
                            state <= S_SELECT;
                        end
                        // operation blt mem16[Reg]
                        16'b011001????00000:begin
                            if (lessThan):
                                regs[IP] <= regs[rdest];
                            state <= S_SELECT;
                        end
                        // operation blt mem10[#]
                        16'b011000?????????:begin
                            if (lessThan):
                                regs[IP] <= data_in[9:0];
                            state <= S_SELECT;
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

                    state <= S_SELECT;
                end

                // wait 1 cycle for Data read
                S_DECODE_WAIT: begin
                    state <= S_DECODE;
                end
                // wait 1 cycle for ALU
                S_COMPUTE_WAIT: begin
                    state <= S_COMPUTE;
                end
            endcase
        end

endmodule