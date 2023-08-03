# program to calculate fibonacci
# note jump address can be of max 12 bit (upto 2KB)
jmp .main

.define:
    # #if = = -> constant in ROM and replace every occurance with address
    # = -> just replace every occurance with address
    # put address in serial order only
    # ROM defined values
    inital_a=0x0001=1
    inital_b=0x0002=3
    max_counter=0x0003=10

    # RAM variables
    storage_c=0x0001
    loading_flag=0x0002
 
    # the sprite pixel data is stored at the end of the file

.end
# main is defined
.main:

    # set RAM initial variables
    mv AX zero
    sta_i storage_c
    mv AX one
    sta_i loading_flag

    # load and init init the counter
    ldaROM max_counter
    mv BS AX
    mv AS zero

    # load values of A and B
    ldaROM inital_a
    ldbROM inital_b

    # set loading flag to 0 -> ready to read data from RAM
    mv BX zero
    stb_i loading_flag

    # set load flag to 1

    # count fibonacci until counter == 10
    .loop:
        # move AX to 3rd var (temp var)
        mv CS AX
        # A = A+B
        add AX BX
        # B= temp
        mv BX CS        
        # inc. counter
        add AS one
        # comp counter with max val
        cmp BS CS

        # save A value to RAM
        sta_i storage_c

        # exit if counter reached
        beq .exit
        jmp .loop
    .end
    .exit:
        jmp .main
    .end
.end
