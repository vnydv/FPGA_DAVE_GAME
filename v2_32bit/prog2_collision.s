/*
    (how many sprite -- size if 16/16 - 640/16 - 40 + 480/16 - 30 = 150 sprites -- 150*4*20/8 = 1500 bytes 1.5 KB of sprite data)

    sprite_data -- (3 words(32 bit) for 200 sprites - )
        -> sprite ID |flag - isactive, isfire, iscoin, isbrick
        -> position_x - upto 640 by 480 -- 10 bit | position_y - upto 640 by 480 -- 10 bit
        -> size_h - 10 bit | size_l - 10 bit
*/

; define to replace for immediate values
#define INPUT_UP_MASK           0x01
#define INPUT_DOWN_MASK         0x02
#define INPUT_LEFT_MASK         0x04
#define INPUT_RIGHT_MASK        0x08

#define SPRITE_IS_ACTIVE        0x01
#define SPRITE_IS_BRICK         0x02
#define SPRITE_IS_COIN          0x04
#define SPRITE_IS_FIRE          0x08
#define SPRITE_IS_GATE          0x10

#define PLAYER_IS_JUMPING_MASK       0x01
#define PLAYER_IS_FALLING_MASK       0x02
#define PLAYER_IS_ALIVE_MASK         0x04

#define PLAYER_SPEED            16
#define PLAYER_SPEED_NEGATIVE   -16 
#define PLAYER_JUMP_COUNTER     6

#define FLAG_ZERO               0x01
#define FLAG_TIMER_UP           0x02
#define FLAG_NEGATIVE           0x04

#define TIMER_ACTIVE            0x01
#define TIMER_TRIGGERED         0x02

#define SPRITE_COUNT            100

; define fixed memory locations -- update from memory map
#define PLAYER_POS_X            0x00
#define PLAYER_POS_Y            0x01
#define PLAYER_FLAGS            0x02

#define SPRITE_COUNT            0x03
#define SPRITE_START            0x04

#define SCORE_FILED             0x05

#define TIMER_STATUS            0x06

#define INPUT_FIELD             0x07


; this main program is linked at the end of the MEMORY file
; update the from memory map manually : TODO: can be automated ???

.main

    ; check timer triggers -- for init just send timer events to wifi

    ; load player pos
    LOAD R0 PLAYER_POS_X
    LOAD R1 PLAYER_POS_Y
    LOAD R9 PLAYER_JUMP_COUNTER

    ; check input field & change player pos
    LOAD R2 INPUT_FIELD

.up
    LOAD R3 INPUT_UP_MASK
    AND R2 R3
    COMP_EQ R2 R3
    bneq .left
    ; jump calc -- if aldready jumping and jump counter > 0
    ; else check falling and jump_counter etc.
    ; then is collision if jumping and collision down -> set jumping to not jumping

    ;LOAD R9 PLAYER_JUMP_COUNTER ; will inc to max then dec falliing to 0
    COMP_EQ R9 R_ZERO ; if equal -> player in air
    bneq .newJump      ; check if falling then dec, if jumping then inc
    ; since already jumping -- do a/c to falling or jumping
    LOAD R3 PLAYER_FLAGS
    LOAD R4 PLAYER_IS_FALLING_MASK
    AND R3 R4
    COMP_EQ R3 R4
    bneq .jumping_up   ; if not equal then jumping up
    ; falling down
    ADD R1 PLAYER_SPEED_NEGATIVE
    ADD R9 -1

    jump .left

.jumping_up
    ; check if jump counter is max -- set to falling
    COMP_EQ R9 PLAYER_JUMP_COUNTER
    bneq .startFalling ; max is reached
    ; else inc y pos
    ADD R1 PLAYER_SPEED
    ADD R9 1
    jump .left

.startFalling
    LOAD R3 PLAYER_FLAGS
    LOAD R4 PLAYER_IS_FALLING_MASK
    OR R3 R4
    ; set is jumping to 0
    LOAD R4 PLAYER_IS_JUMPING_MASK
    NEG R4
    AND R3 R4
    jump .left
    
.newJump
    ; set falling to 0
    LOAD R3 PLAYER_FLAGS
    LOAD R4 PLAYER_IS_FALLING_MASK
    NEG R4
    AND R3 R4

    ; set jumping to 1
    LOAD R4 PLAYER_IS_JUMPING_MASK
    OR R3 R4

    ; inc player pos and jump counter
    ADD R1 PLAYER_SPEED
    ; set player jump counter to 1
    LOAD R9 1

    
; .down -- no down movement
;     LOAD R3 INPUT_DOWN_MASK
;     AND R2 R3
;     COMP_EQ R2 R3
;     bneq .left
;     ; down move calc

.left
    LOAD R3 INPUT_LEFT_MASK
    AND R2 R3
    COMP_EQ R2 R3
    bneq .right
    ; left move calc
    ADD R0 PLAYER_SPEED_NEGATIVE

.right
    LOAD R3 INPUT_RIGHT_MASK
    AND R2 R3
    COMP_EQ R2 R3
    benq .end
    ; right move calc
    ADD R0 PLAYER_SPEED


.end
    ; store player pos
    STORE R0 PLAYER_POS_X
    STORE R1 PLAYER_POS_Y
    
.collisionCheck
    ; Check collisions and resolve player position + trigger events + change sprite active state
    ; R0, R1, R9 are player pos and jump counter
    ; use other regs

    LOAD R2 SPRITE_COUNT
    LOAD R3 SPRITE_START
    LOAD R4 0           

.collisionLoop
    COMP_EQ R4 R2       
    BNEQ .checkSprite
    jump .main       

.checkSprite
    ; Load sprite properties: X position, Y position, flags
    ; keep 3 word dist
    LOAD R8 3
    ADD R8 R4
    ADD R8 R3
    LOAD R5 [R8]

    ; y
    LOAD R9 1
    ADD R9 R8
    LOAD R6 [R9]

    ; flgags
    LOAD R10 2
    ADD R10 R8
    LOAD R7 [R10]

    LOAD R8 SPRITE_IS_ACTIVE
    AND R7 R8
    COMP_EQ R7 R8
    BNEQ .nextSprite

    COMP_EQ R0 R5
    BNEQ .checkYCollision

.checkYCollision
    COMP_EQ R1 R6
    BNEQ .nextSprite     

    ; If both X and Y positions match, handle collision based on sprite type
    ; Check collision with different sprite types

    LOAD R8 SPRITE_IS_COIN
    AND R7 R8
    COMP_EQ R7 R8
    BNEQ .handleCoinCollision

    ; Collision with fire
    LOAD R8 SPRITE_IS_FIRE
    AND R7 R8
    COMP_EQ R7 R8
    BNEQ .handleFireCollision

    LOAD R8 SPRITE_IS_GATE
    AND R7 R8
    COMP_EQ R7 R8
    BNEQ .handleGateCollision

    ; Collision with brick
    LOAD R8 SPRITE_IS_BRICK
    AND R7 R8
    COMP_EQ R7 R8
    BNEQ .handleBrickCollision

.nextSprite
    ADD R4 1            
    jump .collisionLoop 

.handleCoinCollision
    LOAD R8 SCORE_FILED
    ADD R8 1
    STORE R8 SCORE_FILED

    ; Deactivate the coin sprite
    LOAD R7 SPRITE_IS_ACTIVE
    NEG R7
    LOAD R8 3
    ADD R8 R4
    ADD R8 R3
    LOAD R9 2
    ADD R8 R9
    jump .nextSprite

.handleFireCollision
    LOAD R8 PLAYER_FLAGS
    LOAD R9 PLAYER_IS_ALIVE_MASK
    NEG R9
    AND R8 R9
    STORE R8 PLAYER_FLAGS

    jump .end

.handleGateCollision
    LOAD R8 PLAYER_FLAGS
    LOAD R9 PLAYER_IS_ALIVE_MASK
    NEG R9
    OR R8 R9
    STORE R8 PLAYER_FLAGS

    jump .end

.handleBrickCollision
    ; downwards
    LOAD R8 PLAYER_IS_JUMPING_MASK
    LOAD R9 PLAYER_FLAGS
    NEG R8
    AND R8 R9

    LOAD R1 PLAYER_POS_Y 
    ADD R1 PLAYER_SPEED_NEGATIVE
    STORE R1 PLAYER_POS_Y

    jump .nextSprite     

.end

; save values
.timerCheck
    LOAD R8 TIMER_STATUS
    LOAD R9 TIMER_TRIGGERED
    AND R8 R9
    COMP_EQ R8 R9
    BNEQ .noStore

    ; Store player position
    STORE R0 PLAYER_POS_X
    STORE R1 PLAYER_POS_Y

    ; reset
    LOAD R8 TIMER_STATUS
    LOAD R9 TIMER_TRIGGERED
    NEG R9
    AND R8 R9
    STORE R8 TIMER_STATUS

.noStore
    jump .main
