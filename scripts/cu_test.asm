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
    # load and init init the counter
    ldaiROM max_counter
    mv BS AX
    mv AS zero

    # load values of A and B
    ldaROM AX
    ldbROM BX

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
        # exit if counter reached
        beq .exit
        jmp .loop
    .end
    .exit:
        nop
    .end
.end
