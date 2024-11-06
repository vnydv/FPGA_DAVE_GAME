; add two numbers
; r0 = r1 + r2
LOAD R0 5
LOAD R1 3
nop -- added by python  since w/r ops
ADD R0 R1
nop -- added by assembler(python) -- since w/r ops
STORE R0 0

IMem[0] = 32'hff_ff_ff_ff; // NOP
        IMem[1] = 32'h00_00_00_05; // LOAD_IMM R1 0
        IMem[2] = 32'h01_00_00_03; // LOAD_IMM R0 0
        IMem[3] = 32'hff_ff_ff_ff; // NOP // required anyways for this case
        IMem[4] = 32'h60_10_00_00; // ADD R1, R0 -> R0
        IMem[5] = 32'hff_ff_ff_ff; // // NOP // required anyways for this case
        IMem[6] = 32'h40_00_00_00; // STORE_DIR R0 0
        IMem[7] = 32'hff_ff_ff_ff; // NOP

#---------------------


; from memory
#define VAR_A           0x00 
#define VAR_B           0x01
#define VAR_C           0x02

LOAD R0 VAR_A
LOAD R1 VAR_B
ADD R0 R1
STORE R0 VAR_C
