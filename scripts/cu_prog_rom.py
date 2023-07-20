# some flags and data to store in CPU_RAM
# program is read from CPU_ROM

# later---
# can use FPS counter for timer - since 50 fps -> 1000/50 - 20 ms

# CPU 16 bit
# RAM, ROM also 16 bit


IRQ_FLAG = 0xfd
INPUT_AVAILABLE_FLAG = 0x12
FIRE_COLLISION_FLAG = 0x14
TIMER_UP_FLAG = 0x33
COLLECTABLE_COLLISION_FLAG = 0x16

PPU_RAM_NAMETABLE_ADR = 0x16

# wheter can jump
JUMP_ENABLED_FLAG = 0x12

# is in jump state
JUMP_STATE_FLAG = 0x14

moveVel = 0x12
jumpVel = 0x14
#-------------------------


def update_name_table(atAdr, newVal):
    # update nametable @ (atAdr <- newVal)

    # run conditions are resolved internally by RAM module
    # using a dual_port RAM in PPU
    # ntb_addr + atAdr (offset)
    PPU_RAM_NAMETABLE_ADR = newVal

    pass #nop
    return

def init_player():
    # reset player to origin (near )
    # reset player in NameTable also
    playerX = 12
    playerY = 13

    update_name_table("player_init_pos", "sprite_addr_player_normal_standing")
    current_player_sprite = "sprite_addr_player_normal_standing"
    pass #nop
    return

def check_irq():
    # only for animation - no job right now
    # chekc if irq alvailable
    while IRQ_FLAG:
        # do IRQ stuff
        pass # nop
        continue
    
    return

def check_collision():
    # check if player colliding
    # raise collision direction flag if TILE_collision

    # get next possible position
    # check if any sprite alread there from nametable
    atAdr = 0x16


    # use a dual_port RAM in PPU
    # to prevent same address RW check if PPU reading @atAdr
    # if free
    if PPU_RAM_NAMETABLE_ADR_at == "sprite_blank":
        NOT_COLLIDING
    else:
        COLLIDING
        # get direction of collision


    pass #nop
    return 

def game_over(winLoss):
    # @ the last row (which is blank)
    if winLoss == 0:
        # set nametable to show YOU LOST
        pass
    else:
        pass
        # set nametable to show YOU WON

    return 

def update_player_pos():
    # update player position and in nametable
    # as per collision data received for TILE_collision

    if "bottom_collision":
        # put player to one-row-up in nametable
        JUMP_ENABLED_FLAG = 1
        pass

    if "right_collision":
        # put player to one-col-left in nametable
        pass

    if "left_collision":
        # put player to one-col-right in nametable        
        pass

    if "top_collision":
        # put player to one-row-below in nametable
        JUMP_STATE_FLAG = 0
        current_player_sprite = "sprite_addr_player_normal_standing"
        pass

    
    if FIRE_COLLISION_FLAG:
        # disable_input for 60 loops (60 fps) - a counter in CPU_RAM will work
        current_player_sprite = "sprite_addr_player_burning"
    else:
        if "key_right":
            playerX += moveVel
            if current_player_sprite == "sprite_addr_player_moving_right":
                if JUMP_STATE_FLAG == 0:
                    current_player_sprite = "sprite_addr_player_facing_right"
            else:
                current_player_sprite = "sprite_addr_player_moving_right"

        if "key_left":
            playerX -= moveVel
            if current_player_sprite == "sprite_addr_player_moving_left":
                if JUMP_STATE_FLAG == 0:
                    current_player_sprite = "sprite_addr_player_facing_left"
            else:
                current_player_sprite = "sprite_addr_player_moving_left"

        if "key_up":
            JUMP_ENABLED_FLAG = 1
            JUMP_STATE_FLAG = 1
            playerY += jumpVel
        
        if "key_down":
            # no need of down key
            pass

    return

def wait_for_ppu_nametable_load():
    pass

def main():

    wait_for_ppu_nametable_load()

    init_player()

    while True:
        
        if TIMER_UP_FLAG:
            game_over(0)
            break

        check_irq()

        if INPUT_AVAILABLE_FLAG:
            check_collision()

            if FIRE_COLLISION_FLAG:
                playerLives -= 1
                
                if (playerLives == 0):
                    game_over(0)
                    break
                else:
                    init_player()
            
            elif COLLECTABLE_COLLISION_FLAG:
                if "HEART":
                    playerScore += 100
                elif "KEY":
                    # display gate
                    update_name_table("gate_pos", "sprite_addr_gate")
                    playerScore += 500
                elif "GATE":
                    game_over(1)
                    break
            
            update_player_pos()