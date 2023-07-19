# program to calculate fibonacci
# note jump address can be of max 12 bit (upto 2KB)
jmp .main

.define:
    # #if = = -> constant in ROM and replace every occurance with address
    # = -> just replace every occurance with address
    # put address in serial order only
    inital_a=0x0001=1
    inital_b=0x0002=3

    # the sprite pixel data is stored at the end of the file

.end
# main is defined
.main:
    lda_rom_i inital_a
    ldb_rom_i inital_b

    .loop:
        mv AX AS
        add AX BX
        mv AS BX
        jmp .loop
    .end
.end
