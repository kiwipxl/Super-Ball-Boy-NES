init_player:
	LDA #$07
    STA OAM_RAM_ADDR + 1
    LDA #$03
    STA OAM_RAM_ADDR + 2

    RTS
    
update_player:
	;clamp speed_x
    CALL clamp_signed, speed_x, #$FE, #$02
    LDA rt_val_1
    STA speed_x

    ;clamp gravity
    CALL clamp_signed, gravity, #$FB, #$04
    LDA rt_val_1
    STA gravity
	
	;if speed_x is >= 1, then apply friction and slow it down by 64
    IF_SIGNED_GT_OR_EQU speed_x, #$01, posxgtelse
        CALL sub_short, speed_x, speed_x + 1, #$40
        ST_RT_VAL_IN speed_x, speed_x + 1
		
    posxgtelse:
	
	;if speed_x is <= 255, then apply friction and slow it down by 64
    IF_SIGNED_LT_OR_EQU speed_x, #$FF, posxltelse
        CALL add_short, speed_x, speed_x + 1, #$40
        ST_RT_VAL_IN speed_x, speed_x + 1
    posxltelse:

    LEFT_BUTTON_DOWN lbnotdown
        CALL sub_short, speed_x, speed_x + 1, #$80
        ST_RT_VAL_IN speed_x, speed_x + 1
    lbnotdown:

    RIGHT_BUTTON_DOWN rbnotdown
        CALL add_short, speed_x, speed_x + 1, #$80
        ST_RT_VAL_IN speed_x, speed_x + 1
    rbnotdown:

	CALL read_controller

    DIV8 pos_x, #$00, #$00, coord_x
    DIV8 pos_x, #$00, #$02, coord_x + 1
    DIV8 pos_x, #$02, #$00, coord_x + 2

    DIV8 pos_y, #$00, #$00, coord_y
    DIV8 pos_y, #$04, #$00, coord_y + 1
    DIV8 pos_y, #$00, #$04, coord_y + 2

    SET_POINTER_TO_VAL current_room, leftc_pointer + 1, leftc_pointer
    CALL mul_short, leftc_pointer + 1, coord_y, #$20
    ST_RT_VAL_IN leftc_pointer + 1, leftc_pointer
    ST_RT_VAL_IN rightc_pointer + 1, rightc_pointer

    SET_POINTER_TO_VAL current_room, downc_pointer + 1, downc_pointer
    CALL mul_short, downc_pointer + 1, coord_y + 1, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer

    SET_POINTER_TO_VAL current_room, upc_pointer + 1, upc_pointer
    CALL mul_short, upc_pointer + 1, coord_y + 2, #$20
    ST_RT_VAL_IN upc_pointer + 1, upc_pointer

    CALL check_collide_down
    LDA rt_val_1
    BEQ cte0_
        STA current_tile
        IF_SIGNED_GT_OR_EQU gravity, #$00, notmovingdowncollide
            LDA current_tile
            CMP #$0A
            BNE spring_no_collide
                MUL8 c_coord_y
                STA pos_y

                LDA #$EF
                STA gravity
                LDA #$00
                STA gravity + 1
				
				CALL create_tile_animation, #HIGH(SPRING_ANI), #LOW(SPRING_ANI), #$01, #$00, c_coord_x, c_coord_y, current_VRAM_addr, current_VRAM_addr + 1
				
                JMP notmovingdowncollide
            spring_no_collide:

            CMP #$0B
            BNE respawn_endif
                CALL respawn
                JMP notmovingdowncollide
            respawn_endif:
        notmovingdowncollide:
    cte0_:

    CALL add_short, downc_pointer + 1, downc_pointer, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer

    CALL check_collide_down
    LDA rt_val_1
    IS_SOLID_TILE nscdownendif
        IF_SIGNED_GT_OR_EQU gravity, #$00, nscdownendif
            MUL8 c_coord_y
            CLC
            ADC #$03
            STA pos_y

            LDA #$FC
            STA gravity
            LDA #$7F
            STA gravity + 1
    nscdownendif:

    CALL check_collide_up
    IS_SOLID_TILE nscupendif
        IF_SIGNED_LT_OR_EQU gravity, #$00, nscupendif
            MUL8 c_coord_y
            SEC
            SBC #$01
            STA pos_y

            LDA #$01
            STA gravity
    nscupendif:

    IF_UNSIGNED_GT pos_x, #$04, nscleftendif
    CALL check_collide_left
    IS_SOLID_TILE nscleftendif
        IF_SIGNED_LT_OR_EQU speed_x, #$00, nscleftendif
            MUL8 c_coord_x, #$01, #$00, pos_x

            LDA #$00
            STA speed_x
    nscleftendif:

    IF_UNSIGNED_LT pos_x, #$FB, nscrightendif
    CALL check_collide_right
    IS_SOLID_TILE nscrightendif
        IF_SIGNED_GT_OR_EQU speed_x, #$00, nscrightendif
            MUL8 c_coord_x, #$00, #$01, pos_x

            LDA #$00
            STA speed_x
    nscrightendif:

    CALL add_short, gravity, gravity + 1, #$40
    ST_RT_VAL_IN gravity, gravity + 1

    ;add gravity to pos_y and set it as the player's y sprite position
    ADD pos_y, gravity
    STA pos_y
    STA OAM_RAM_ADDR

    ADD pos_x, speed_x
    STA pos_x

    RTS