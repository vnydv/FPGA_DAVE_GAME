# program to calculate fibonacci
# note jump address can be of max 12 bit (upto 2KB)
jmp .main

.define:
    # #if = = -> constant in ROM and replace every occurance with address
    # = -> just replace every occurance with address
    # put address in serial order only
    inital_a=0x0001=1
    inital_b=0x0002=3
    max_counter=0x0003=10

    # the sprite pixel data is stored at the end of the file

.end
# main is defined
.main:
    # init the counter
    mv BS zero
    lda max_counter
    lda_rom AX
    mv CS AX

    # load address of a and b
    lda inital_a
    ldb inital_b

    # load values of A and B
    lda_rom AX
    ldb_rom BX

    # count fibonacci until counter == 10
    .loop:
        add BS one
        mv AS AX
        add AX BX
        mv BX AS
        cmp BS CS 
        beq .exit
        jmp .loop
    .end
    .exit:
        nop
    .end
.end
