jmp .main

.define:
    # sprite address - replace in code
    # 16 bit address
    SPRITE_BLANK=0x0001
    SPRITE_TILE=0x0002
    SPRITE_HEART=0x0102
    SPRITE_KEY=0x0202
    SPRITE_DAVE_NORMAL=0x0302
    SPRITE_DAVE_RIGHT_LOOK=0x0402
    SPRITE_DAVE_RIGHT_WALK=0x0502
    SPRITE_DAVE_RIGHT_JUMP=0x0602
    SPRITE_FIRE=0x0702
    SPRITE_GATE=0x0802
    SPRITE_TUNNEL=0x0902
    SPRITE_DIGIT_0=0x0a02
    SPRITE_DIGIT_1=0x0b02
    SPRITE_DIGIT_2=0x0c02
    SPRITE_DIGIT_3=0x0d02
    SPRITE_DIGIT_4=0x0e02
    SPRITE_DIGIT_5=0x0f02
    SPRITE_DIGIT_6=0x1002
    SPRITE_DIGIT_7=0x1102
    SPRITE_DIGIT_8=0x1202
    SPRITE_DIGIT_9=0x1302
    SPRITE_LIVES=0x1402
    SPRITE_COINS=0x1502
    SPRITE_W=0x1602
    SPRITE_O=0x1702
    SPRITE_N=0x1802
    SPRITE_L=0x1902
    SPRITE_O=0x1a02
    SPRITE_S=0x1b02
    SPRITE_T=0x1c02

    NAMETABLE_TABLE_START_ROM=0x0001=0x0001
    NAMETABLE_ROW_COUNT=12
    NAMETABLE_COL_COUNT=20
    
    NAMETABLE_TABLE_START_RAM=0x0000
    # count unitl reach 0

    # in RAM
    NAMETABLE_DATA_COUNT=0x0001=40
    RGB_VAL=0x00f1

    PPU_RAM_READY=0x0002=1
.end
# screen in 480 x 640



# 0x1fff -> start IP at this address in ROM
.main:
    
    # set ppu_ram_ready to 0
    lda zero
    sta PPU_RAM_READY

    lda zero
    mv AX BS

    lda_i NAMETABLE_TABLE_START_ROM
    ldb_i NAMETABLE_TABLE_START_RAM

    mv AX AS
    # load_name_table into RAM
    .load_name_table:
        lda_rom AS
        sta BX
        
        add BX one
        add AS one
        add BS one

        cmp BS NAMETABLE_DATA_COUNT
        blt .load_name_table
    .end
    # set ppu_ram_ready to 1
    # ----

    lda one
    sta PPU_RAM_READY
    
    # hpos, vpos values are passed as separate register
    # from VGA_module
    .loop:
        # get current sprite index
        # srow = vpos / 16
        lda vpos
        shiftR AX 4
        
        # scol = hpos / 16
        ldb hpos
        shiftR BX 4
        
        # sprite index in nametable
        # srow * 16 + srow * 4 + scol
        mv AX AS
        shiftL AX 2
        shiftL AS 4
        add AX AS
        add AX BX

        # AX has sprite address in nametable
        # PPU reads from port 1 to PPU_RAM
        # CPU reads from port 2 to PPU_RAM
        lda AX
        cmp AX zero
        jmp .loop

        # voff = hpos - scow * 16
        # AS << 4 already done
        neg AS
        add AS hpos
        add AS one
        
        # hoff = vpos - srow * 16
        shiftL BX 4
        neg BX
        add BX vpos
        add BX one

        # final pixel index
        # hoff * 16 + voff
        shiftL BX 4
        add BX AS

        # BX has sprite pixel value
        # final value is
        add AX BX
        ldb_rom AX
        mv BX RGB_VAL
    .end
.end        