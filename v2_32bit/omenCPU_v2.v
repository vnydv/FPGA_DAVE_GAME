// has no solution to Read-Write Hazards -- just use nops

`timescale 1ns / 1ps

module cpu32(input wire clk);

    //Program Counter and Intermediate Latches (instruction register)
    reg[31:0] PC = 0, IF_ID_IR, IF_ID_NPC;
    
    //Required for Execute stage
    reg[31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A,ID_EX_B, ID_EX_Imm;
    //type of instruction (elaborated below) 
    reg[2:0]  ID_EX_type, EX_MEM_type, MEM_WB_type;

    reg[31:0] EX_MEM_IR,    EX_MEM_ALUOut, EX_MEM_A;

    //Branch Condition
    reg       EX_MEM_cond;
    reg[31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;

    reg[31:0] Reg[0:16];    //Register Bank
    reg[31:0] IMem[0:30];    //Memory -- 1024 x 32

    reg[9:0] DMem[0:30];    //Memory -- 1024 x 32

    // load inital memory
    initial begin

        Reg[0] = 32'h00_00_00_00; // R0
        Reg[1] = 32'h00_00_00_00; // R1
        Reg[2] = 32'h00_00_00_00; // R2
        Reg[3] = 32'h00_00_00_00; // R3
        Reg[4] = 32'h00_00_00_00; // R4

        DMem[0] = 10'd3; //
        DMem[1] = 10'd4; //
        DMem[2] = 10'd0; //
        DMem[3] = 10'd0; //

        // containd the memory values in binary
        IMem[0] = 32'hff_ff_ff_ff; // NOP
        IMem[1] = 32'h11_00_00_00; // LOAD_DIR R1 0
        IMem[2] = 32'h10_00_00_01; // LOAD_DIR R0 0
        IMem[3] = 32'hff_ff_ff_ff; // NOP // required anyways -- no other way to remove it
        IMem[4] = 32'h60_10_00_00; // ADD R1, R0 -> R0
        IMem[5] = 32'hff_ff_ff_ff; // NOP // required anyways -- no other way to remove it
        IMem[6] = 32'h40_00_00_03; // STORE_DIR R0 3
        IMem[7] = 32'hff_ff_ff_ff; // NOP        
        IMem[8] = 32'h34_10_00_00; // MOV R4 R1; R1 -> R4 = 3

        // print the memory
        for (integer i=0; i < 10; i=i+1) begin
            $display("%0t: IMem[%0d]: x%h",  $time, i, IMem[i]);
        end
    end

    //Instruction types
    // Instruction types
    parameter   LOAD_IMM    = 4'h0,  // 0x0
                LOAD_DIR    = 4'h1,  // 0x1
                LOAD_IDIR   = 4'h2,  // 0x2
                MOVE        = 4'h3,  // 0x3
                STORE_DIR   = 4'h4,  // 0x4
                ADD_IMM     = 4'h5,  // 0x5
                ADD         = 4'h6,  // 0x6
                NEG         = 4'h7,  // 0x7
                AND         = 4'h8,  // 0x8
                OR          = 4'h9,  // 0x9
                COMP_EQ     = 4'hA,  // 0xA
                COMP_LT     = 4'hB,  // 0xB
                BNEQ_ADDR   = 4'hC,  // 0xC
                BLT_ADDR    = 4'hD,  // 0xD
                JUMP_ADDR   = 4'hE,  // 0xE
                NOP         = 4'hF;  // 0xF


    parameter   RR_ALU  =   3'h0,
                RM_ALU  =   3'h1,
                LOAD    =   3'h2,
                STORE   =   3'h3,
                BRANCH  =   3'h4,
                NOPE    =   3'h5 ;    // for type mentioned above
                

    //reg HALTED = 0;                 //Set after HLT instruction is completed ( in WriteBack stage)
    reg TAKEN_BRANCH;           //Required to disable further instructions after Branch

    // stages
    //------Instruction Fetch(IF) Stage----//
    always @(posedge clk)
        begin
            if (((EX_MEM_IR[31:28] == BNEQ_ADDR) && (EX_MEM_cond == 1))  || 
                ((EX_MEM_IR[31:28] == BLT_ADDR) && (EX_MEM_cond == 0)))
                begin
                    IF_ID_IR      <=  IMem[EX_MEM_ALUOut];
                    TAKEN_BRANCH  <=  1'b1;
                    IF_ID_NPC     <=  EX_MEM_ALUOut + 1;
                    PC            <=  EX_MEM_ALUOut + 1;
                end
            else
                begin
                    IF_ID_IR      <=  IMem[PC];
                    IF_ID_NPC     <=  PC + 1;
                    PC            <=  PC + 1;
                end

            // display all the registers
            $display("%0t: FETCH: PC: x%h, IF_ID_IR: x%h, IF_ID_NPC: x%h", $time, PC, IF_ID_IR, IF_ID_NPC);
        end

    //------Instruction Decode(ID) Stage----//
    always @(negedge clk)
        begin
            ID_EX_A      <=  Reg[IF_ID_IR[27:24]];   // "rt" // destinations
            ID_EX_B      <=  Reg[IF_ID_IR[23:20]];   // "rs" // source
            
            ID_EX_NPC   <= IF_ID_NPC;
            ID_EX_IR    <= IF_ID_IR;
            

            case(IF_ID_IR[31:28])                                    //type of instruction
                ADD, AND, OR, NEG: begin
                    ID_EX_type <= RR_ALU;
                    ID_EX_Imm   <= {8'b0,{IF_ID_IR[23:0]}};   // no sign extension --- doesn;t matter
                    $display("%0t: DECODE: ADD/AND/OR/NEG", $time);
                end
                ADD_IMM: begin
                    ID_EX_Imm   <= {{8{IF_ID_IR[23]}},{IF_ID_IR[23:0]}};   //Sign extension
                    ID_EX_type <= RM_ALU;
                    $display("%0t: DECODE: ADD_IMM", $time);
                end
                LOAD_IMM: begin
                    ID_EX_type <= LOAD;
                    ID_EX_Imm   <= {{8{IF_ID_IR[23]}},{IF_ID_IR[23:0]}};   //Sign extension
                    $display("%0t: DECODE: IMM", $time);
                end
                LOAD_DIR, MOVE, LOAD_IDIR: begin
                    ID_EX_type <= LOAD;
                    ID_EX_Imm   <= {8'b0,{IF_ID_IR[23:0]}};   // no sign extension since memory
                    $display("%0t: DECODE: LOAD", $time);
                end
                STORE_DIR: begin
                    ID_EX_type <= STORE;
                    ID_EX_Imm   <= {8'b0,{IF_ID_IR[23:0]}};   // no sign extension since memory
                    $display("%0t: DECODE: STORE", $time);
                end
                BNEQ_ADDR, BLT_ADDR, JUMP_ADDR: begin
                    ID_EX_type <= BRANCH;
                    ID_EX_Imm   <= {8'b0,{IF_ID_IR[23:0]}};   // no sign extension since memory
                    $display("%0t: DECODE: JUMP/BRANCH", $time);
                end
                NOP: ID_EX_type <= NOPE;
                default                : ID_EX_type <= NOPE;    //Invalid opcode
            endcase

            // display all the registers
            $display("%0t: DECODE: ID_EX_A: x%h, ID_EX_B: x%h, ID_EX_NPC: x%h, ID_EX_IR: x%h, ID_EX_Imm: x%h, ID_EX_type: x%h",  $time,ID_EX_A, ID_EX_B, ID_EX_NPC, ID_EX_IR, ID_EX_Imm, ID_EX_type);
        end

    //------Execute(EX) Stage----//
    always @(posedge clk)        
        begin
            EX_MEM_type   <= ID_EX_type;
            EX_MEM_IR     <= ID_EX_IR;
            TAKEN_BRANCH  <= 0;

            case (ID_EX_type)
                RR_ALU: begin
                    case(ID_EX_IR[31:28])                                //opcode                        
                        ADD     : EX_MEM_ALUOut <= ID_EX_A + ID_EX_B;
                        AND     : EX_MEM_ALUOut <= ID_EX_A & ID_EX_B;
                        OR      : EX_MEM_ALUOut <= ID_EX_A | ID_EX_B;
                        NEG     : EX_MEM_ALUOut <= -ID_EX_A;
                        default : EX_MEM_ALUOut <= 32'hxxxxxxxx; // change to 0 -- rn for testbench
                    endcase
                    $display("%0t: Execute: RR_ALU: EX_MEM_ALUOut: x%h", $time, EX_MEM_ALUOut);
                end

                RM_ALU: begin
                    case(ID_EX_IR[31:28])                                  //opcode
                        ADD_IMM    : EX_MEM_ALUOut <= ID_EX_A + ID_EX_Imm;                        
                        default : EX_MEM_ALUOut <= 32'hxxxxxxxx;
                    endcase
                    $display("%0t: Execute: RM_ALU: EX_MEM_ALUOut: x%h", $time, EX_MEM_ALUOut);
                end

                LOAD: begin // need case for LOAD INDIRECT
                    EX_MEM_ALUOut <= ID_EX_Imm; // diff between LOAD_IMM and LOAD_DIR later -- since Imm value is same
                    EX_MEM_A      <= ID_EX_B; // move
                    $display("%0t: Execute: LOAD: EX_MEM_ALUOut: x%h, EX_MEM_A: x%h", $time, EX_MEM_ALUOut, EX_MEM_A);
                end
                
                STORE: begin
                    EX_MEM_ALUOut <= ID_EX_Imm;
                    EX_MEM_A      <= ID_EX_A;
                    $display("%0t: Execute: LOAD/STORE: EX_MEM_ALUOut: x%h", $time, EX_MEM_ALUOut);
                end

                BRANCH: begin
                    EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_Imm;  // Target adress of branch... Imm is offset
                    EX_MEM_cond   <= (ID_EX_A ==0);          // Used in IF Stage
                    $display("%0t: Execute: BRANCH: EX_MEM_ALUOut: x%h, EX_MEM_cond: x%h", $time, EX_MEM_ALUOut, EX_MEM_cond);
                end

                NOPE: begin
                    EX_MEM_ALUOut <= 32'hxxxxxxxx;
                    $display("%0t: Execute: NOPE: EX_MEM_ALUOut: x%h",  $time, EX_MEM_ALUOut);
                end
        endcase
        
    end

    //------Memory(MEM) Stage----//
    always @(negedge clk)
        begin
            MEM_WB_type  <= EX_MEM_type;
            MEM_WB_IR    <= EX_MEM_IR;

            case(EX_MEM_type)
                RR_ALU,RM_ALU: begin
                    MEM_WB_ALUOut <= EX_MEM_ALUOut;
                end
                LOAD: begin
                    case(EX_MEM_IR[31:28])
                        LOAD_IMM: MEM_WB_LMD <= ID_EX_Imm;
                        LOAD_DIR, LOAD_IDIR: MEM_WB_LMD <= DMem[EX_MEM_ALUOut];
                        MOVE: MEM_WB_LMD <= EX_MEM_A;
                        default: MEM_WB_LMD <= 32'hxxxxxxxx;
                    endcase

                    $display("%0t: LOAD: MEM_WB_LMD: x%h", $time, MEM_WB_LMD);
                end
                STORE: begin
                    if(TAKEN_BRANCH == 0)  begin //Disable Write
                        DMem[EX_MEM_ALUOut]  <= EX_MEM_A[9:0];
                    end

                    $display("%0t: STORE: DMem[%0d]: x%h", $time, EX_MEM_ALUOut, DMem[EX_MEM_ALUOut]);
                end
                default: begin
                    $display("%0t: MEM: default", $time);
                end
            endcase

            $display("%0t: --------------", $time);
        end

    //------WriteBack(WB) Stage----//
    always @(posedge clk)
        begin
            if (TAKEN_BRANCH == 0) //Disable Write if branch is taken

            case(MEM_WB_type)
                RR_ALU: Reg[MEM_WB_IR[27:24]] <= MEM_WB_ALUOut;   //"rd"
                RM_ALU: Reg[MEM_WB_IR[27:24]] <= MEM_WB_ALUOut;   //"rt"
                LOAD: Reg[MEM_WB_IR[27:24]]   <= MEM_WB_LMD;      //"rt"
            endcase
            $display("%0t: ++++++++++++++++", $time);
        end

endmodule
