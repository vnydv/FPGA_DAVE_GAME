; for RAM
_define: ;memory regions (replace names with hex address)




.update_name_table:

.init_player:

.check_irq:

.check_collision:

.game_over:

.update_player_pos:

.wait_for_ppu_nametable_load:

.main:
    jmp wait_for_ppu_nametable_load    
    jmp init_player

    .loop:
        cmp TIMER_UP_FLAG one
        beq exit

        jmp check_irq

        cmp INPUT_AVAILABLE_FLAG zero
        beq loop
        
        jmp check_collision

        cmp FIRE_COLLISION_FLAG zerp
        beq next_if
        add PLAYER_LIVES -1
        cmp PLAYER_LIVES zero
        beq if_player_lives_zero        
        ;else
        jmp init_player
        jmp final

        .if_player_lives_zero:
            str AF, 0
            jmp game_over
            jmp exit
        
        .next_if:
            cmp COLLECTABLE_COLLISION_FLAG zerp
            beq final

            .is_sprite_heart:
                add PLAYER_SCORE 100
                jmp final

            .is_sprite_key:
                jmp update_name_table
                add PLAYER_SCORE 100
                jmp final
            
            .is_sprite_gate:
                str AF, 1
                jmp game_over
                jmp exit

        .final:
            jmp update_player_pos
            jmp loop

    .exit

        

