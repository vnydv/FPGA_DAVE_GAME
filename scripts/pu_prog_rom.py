#define addresses

# 16 bit data/address/instruction busses
# data is wasted only is sprites

# PU_ROM
# address bus is 16 bit wide but is only (8 KB) - other address are invalid x000
# data bus is 16 bit wide
# ... region -> SPRITE_DATA, 10 lines empty, PROGRAM_DATA

# PU_RAM
# address bus is 16 bit wide but is only (< 2 KB) - other address are invalid x000
# data bus is 16 bit wide

# PPU
# instruction bus is 16 bit wide
# address bus is 16 bit wide
# data bus is 16 bit wide


NAMETABLE_ROW_COUNT = 12 @ 0x12
NAMETABLE_COL_COUNT = 20 @ 0x14

PPU_RAM_NAMETABLE_ADR_at = 0x13
PPU_RAM_NAMETABLE_ADR = 0x16

PPU_ROM_SPRITE_TABLE_ADR = 0x12

#------

def load_name_table(fromROMAdr, toRAMAdr):
    pass #nop
    return

def get_sprite_at_pos(hpos, vpos, *spriteAdr):
    # return spirte address from nametable at hpos, vpos

    # define local params - division by 16 is (vpos_bin >> 4)
    nametable_row = vpos % 16
    nametable_col = hpos % 16

    # multiplication by 16 is (bin << 4)
    offset = nametable_row * NAMETABLE_COL_COUNT + nametable_col

    PPU_RAM_NAMETABLE_ADR_at = offset

    [*spriteAdr] = PPU_RAM_NAMETABLE_ADR + offset

    return
    

def main():

    hpos = 0
    vpos = 0

    load_name_table(0x12, PPU_RAM_NAMETABLE_ADR)

    while True:
        spriteAdr = 0x00
        get_sprite_at_pos(hpos, vpos, *spriteAdr)

        sprite_hoffset = hpos - "startof_sprite_x"
        sprite_voffset = vpos - "startof_sprite_y"

        # check player states
        # else update and draw player if player in hpos vpos

        # read from ROM
        # 12 bit colour value
        # wire RGB to VGA
        rgb = PPU_ROM_SPRITE_TABLE_ADR + sprite_hoffset * 16 + sprite_voffset

