init_enemies:
	LDX enemy_max
	BEQ eacle_
	eil_:
		DEX
		BEQ eile_

		LDA #$00
		STA enemy_active, x

		JMP eil_
	eile_:

	RTS

;creates a tile enemy set with specified enemy parameters
;input - (enemy_label_hi, enemy_label_lo, enemy rate, loop (0 or > 0), tile_x, tile_y)
create_slime:
	;loops through all enemies to find a non active enemy
	LDX enemy_len
	eacl_:
		DEX
		CPX #$FF
		BEQ eacle_

		LDA enemy_active, x
		BEQ eaclfe_

		JMP eacl_
	eacle_:
		RTS
	eaclfe_:

	STX temp + 2
	LDY #$00

	MUL8 param_1
	STA enemy_pos_x, x

	MUL8 param_2
	STA enemy_pos_y, x

	LDA #$01
	STA enemy_active, x

	LDA #$00
	STA enemy_speed_x, x
	STA enemy_gravity, x
	STA enemy_type, x

	SET_POINTER_TO_VAL current_room, enemy_room + 1, x, enemy_room, x

	LDA temp + 2
	ASL a
	ASL a
	TAX

	LDA #$0C
	STA OAM_RAM_ADDR + 5, x
	LDA #$03
	STA OAM_RAM_ADDR + 6, x

	RTS

update_enemies:
	LDX enemy_len
	eul_:
		DEX
		CPX #$FF
		BEQ eule_

		LDA enemy_active, x
		BEQ eul_

		STX temp + 2
		TXA
	    ASL a
	    STA temp + 3
		ASL a
		STA temp + 4

		CALL handle_enemy_movement
	    CALL handle_enemy_collision

	    LDX temp + 3
		IF_EQU room_1, enemy_room, x, eulei_
			LDX temp + 2
			IF_UNSIGNED_LT_OR_EQU scroll_x, enemy_pos_x, x, eulhe_
			JMP eulns_
		eulei_:
			LDX temp + 2
			IF_UNSIGNED_GT_OR_EQU scroll_x, enemy_pos_x, x, eulhe_
		eulns_:

		LDX temp + 2
		LDA enemy_pos_y, x
		LDX temp + 4
		STA OAM_RAM_ADDR + 4, x

		LDX temp + 2
		LDA enemy_pos_x, x
		SEC
		SBC scroll_x
		LDX temp + 4
		STA OAM_RAM_ADDR + 7, x

		LDX temp + 2
		JMP eul_

		eulhe_:
			LDX temp + 4
			LDA #$FF
			STA OAM_RAM_ADDR + 4, x
			LDA #$FF
			STA OAM_RAM_ADDR + 7, x
			LDX temp + 2
			JMP eul_
	eule_:

    RTS

handle_enemy_movement:
	LDX temp + 2

	;clamp enemy_speed_x
    CALL clamp_signed, enemy_speed_x, x, #$FE, #$02
    LDA rt_val_1
    STA enemy_speed_x, x

    ;clamp enemy_gravity
    CALL clamp_signed, enemy_gravity, x, #$FB, #$04
    LDA rt_val_1
    STA enemy_gravity, x

	;if enemy_speed_x is >= 1, then apply friction and slow it down by 64
    IF_SIGNED_GT_OR_EQU enemy_speed_x, x, #$01, eposxgtelse
        CALL sub_short, enemy_speed_x, x, enemy_speed_x + 1, x, #$40
        ST_RT_VAL_IN enemy_speed_x, x, enemy_speed_x + 1, x
    eposxgtelse:
	
	;if enemy_speed_x is <= 255, then apply friction and slow it down by 64
    IF_SIGNED_LT_OR_EQU enemy_speed_x, x, #$FF, eposxltelse
        CALL add_short, enemy_speed_x, x, enemy_speed_x + 1, x, #$40
        ST_RT_VAL_IN enemy_speed_x, x, enemy_speed_x + 1, x
    eposxltelse:

    RTS

handle_enemy_collision:
	LDX temp + 2

	DIV8 enemy_pos_x, x, #$00, #$00, coord_x
    DIV8 enemy_pos_x, x, #$00, #$04, coord_x + 1
    DIV8 enemy_pos_x, x, #$04, #$00, coord_x + 2

    DIV8 enemy_pos_y, x, #$00, #$00, coord_y
    DIV8 enemy_pos_y, x, #$04, #$00, coord_y + 1
    DIV8 enemy_pos_y, x, #$00, #$04, coord_y + 2

    LDX temp + 3

    SET_POINTER enemy_room, x, enemy_room + 1, x, leftc_pointer + 1, leftc_pointer
    CALL mul_short, leftc_pointer + 1, coord_y, #$20
    ST_RT_VAL_IN leftc_pointer + 1, leftc_pointer
    ST_RT_VAL_IN rightc_pointer + 1, rightc_pointer

    SET_POINTER enemy_room, x, enemy_room + 1, x, downc_pointer + 1, downc_pointer
    CALL mul_short, downc_pointer + 1, coord_y + 1, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer

    SET_POINTER enemy_room, x, enemy_room + 1, x, upc_pointer + 1, upc_pointer
    CALL mul_short, upc_pointer + 1, coord_y + 2, #$20
    ST_RT_VAL_IN upc_pointer + 1, upc_pointer

    LDX temp + 2

    CALL check_collide_down
    MUL8 c_coord_y
    CLC
    ADC #$02
    STA temp
    LDA rt_val_1
    IS_SOLID_TILE enscdownelse
        JMP enscdownendif
    enscdownelse:
        IF_SIGNED_GT_OR_EQU enemy_gravity, x, #$00, enscdownendif
            LDA temp
            STA enemy_pos_y, x

            LDA #$FC
            STA enemy_gravity, x
            LDA #$7F
            STA enemy_gravity + 1, x
    enscdownendif:

    CALL check_collide_up
    IS_SOLID_TILE enscupelse
        JMP enscupendif
    enscupelse:
        IF_SIGNED_LT_OR_EQU enemy_gravity, x, #$00, enscupendif
            MUL8 c_coord_y
            SEC
            SBC #$01
            STA enemy_pos_y, x

            LDA #$01
            STA enemy_gravity, x
    enscupendif:

    CALL check_collide_left
    IS_SOLID_TILE enscleftelse
        JMP enscleftendif
    enscleftelse:
        IF_SIGNED_LT_OR_EQU enemy_speed_x, x, #$00, enscleftendif
            MUL8 c_coord_x, #$01, #$00, enemy_pos_x, x

            LDA #$00
            STA enemy_speed_x, x
    enscleftendif:

    CALL check_collide_right
    IS_SOLID_TILE enscrightelse
        JMP nscrightendif
    enscrightelse:
        IF_SIGNED_GT_OR_EQU enemy_speed_x, x, #$00, enscrightendif
            MUL8 c_coord_x, #$00, #$01, enemy_pos_x, x

            LDA #$00
            STA enemy_speed_x, x
    enscrightendif:

    LDX temp + 2

    CALL add_short, enemy_gravity, x, enemy_gravity + 1, x, #$40
    ST_RT_VAL_IN enemy_gravity, x, enemy_gravity + 1, x

    LDX temp + 2
    ADD enemy_pos_y, x, enemy_gravity, x
    STA enemy_pos_y, x

    ADD enemy_pos_x, x, enemy_speed_x, x
    STA enemy_pos_x, x

    RTS