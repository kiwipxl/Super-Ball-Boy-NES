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

	LDA #$01
	STA enemy_active, x

	LDA #$00
	STA enemy_speed_x, x
	STA enemy_gravity, x
	STA enemy_type, x

	LDA #$00
	STA enemy_temp_1, x
	STA enemy_temp_3, x
	STA enemy_temp_4, x

	LDA #$7F
	STA enemy_temp_2, x

	SET_POINTER_TO_VAL current_room, enemy_room + 1, x, enemy_room, x

	LDA temp + 2
	ASL a
	ASL a
	TAX

	MUL8 param_1
	STA enemy_pos_x, x
	LDA #$00
	STA enemy_pos_x + 1, x

	MUL8 param_2
	STA enemy_pos_y, x
	LDA #$00
	STA enemy_pos_y + 1, x

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
	    CALL handle_enemy_AI

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
		SEC
		SBC #$01
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
    CALL add_short, enemy_gravity, x, enemy_gravity + 1, x, #$40
    LDX temp + 2
    ST_RT_VAL_IN enemy_gravity, x, enemy_gravity + 1, x

	;clamp enemy_speed_x
    CALL clamp_signed, enemy_speed_x, x, #$FE, #$02
    LDA rt_val_1
    STA enemy_speed_x, x

    ;clamp enemy_gravity
    CALL clamp_signed, enemy_gravity, x, #$FB, #$04
    LDA rt_val_1
    STA enemy_gravity, x

    LDA on_floor
    BNE hemnof_
		LDX temp + 4
		LDA #$0C
		STA OAM_RAM_ADDR + 5, x

	    LDX temp + 2
	    IF_SIGNED_LT enemy_speed_x, x, #$00, hemnof_
	    	LDX temp + 4
	    	LDA #$10
			STA OAM_RAM_ADDR + 5, x
	hemnof_:

    LDX temp + 2
    ADD enemy_pos_y, x, enemy_gravity, x
    STA enemy_pos_y, x

    ADD enemy_pos_x, x, enemy_speed_x, x
    STA enemy_pos_x, x

    LDX temp + 3
    CALL add_short, enemy_pos_x, x, enemy_pos_x + 1, x, enemy_speed_x + 1, x
    LDX temp + 3
    ST_RT_VAL_IN enemy_pos_x, x, enemy_pos_x + 1, x

    RTS

handle_enemy_collision:
	LDX temp + 2

	DIV8 enemy_pos_x, x, #$00, #$00, coord_x
    DIV8 enemy_pos_x, x, #$00, #$01, coord_x + 1
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

    LDA #$00
    STA on_floor

    CALL check_collide_down
    LDA rt_val_1
    BEQ heclt0_
        STA current_tile
	    IF_SIGNED_GT_OR_EQU enemy_gravity, x, #$00, heclt0_
	    	LDA current_tile
	        CMP #$0A
	        BNE heclt0_
	        	LDX temp + 2
	        	MUL8 c_coord_y
	            STA enemy_pos_y, x

	            LDA #$FA
	            STA enemy_gravity, x
	            LDA #$00
	            STA enemy_gravity + 1, x

	            LDA #$01
            	STA on_floor
            	
	            CALL play_spring_animation
	    heclt0_:

    CALL add_short, downc_pointer + 1, downc_pointer, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer

    CALL check_collide_down
    LDA rt_val_1
    LDX temp + 2
    IS_SOLID_TILE enscdownendif
    	IF_SIGNED_GT_OR_EQU enemy_gravity, x, #$00, enscdownendif
    		MUL8 c_coord_y
            STA enemy_pos_y, x

            LDA #$00
            STA enemy_gravity, x
            STA enemy_speed_x, x
            LDA #$00
            STA enemy_gravity + 1, x
            STA enemy_speed_x + 1, x

            LDA #$01
            STA on_floor
    enscdownendif:

    CALL check_collide_up
    LDX temp + 2
    IS_SOLID_TILE enscupendif
    	IF_SIGNED_LT_OR_EQU enemy_gravity, x, #$00, enscupendif
            MUL8 c_coord_y
            SEC
            SBC #$01
            STA enemy_pos_y, x

            LDA #$01
            STA enemy_gravity, x
    enscupendif:

    CALL check_collide_left
    LDX temp + 2
    IS_SOLID_TILE enscleftendif
    	IF_SIGNED_LT_OR_EQU enemy_speed_x, x, #$00, enscleftendif
            MUL8 c_coord_x, #$01, #$00, enemy_pos_x, x

            LDA #$00
            STA enemy_speed_x, x
            STA enemy_speed_x + 1, x
    enscleftendif:

    CALL check_collide_right
    LDX temp + 2
    IS_SOLID_TILE enscrightendif
        IF_SIGNED_GT_OR_EQU enemy_speed_x, x, #$00, enscrightendif
            MUL8 c_coord_x, #$00, #$01, enemy_pos_x, x

            LDA #$00
            STA enemy_speed_x, x
            STA enemy_speed_x + 1, x
    enscrightendif:

    RTS

handle_enemy_AI:
	LDA enemy_type
    CMP #$00
    BNE heainequ0_
	    CALL handle_slime_AI
	    JMP heaieet_
    heainequ0_:
    CMP #$01
    BNE heainequ1_
    	CALL handle_bat_AI
	    JMP heaieet_
	heainequ1_:
    heaieet_:

    RTS

handle_slime_AI:
	LDX temp + 2
    IF_UNSIGNED_GT_OR_EQU enemy_temp_1, x, enemy_temp_2, x, hsait1ngtt2_
    	IF_EQU on_floor, #$01, hsaiei_
	    	LDA #$00
	    	STA enemy_temp_1, x
	    	CALL rand
	    	LSR a
	    	CLC
	    	ADC #$10
	    	STA enemy_temp_2, x

	    	LDA #$FD
	        STA enemy_gravity, x
	        LDA #$7F
	        STA enemy_gravity + 1, x

	        CALL check_lr_solids
	        LDA rt_val_1
	        BEQ hsaiei_
	        LDX temp + 2

	        CALL rand
	        IF_SIGNED_GT rt_val_1, #$00, hsair_
	        hsail_:
	        	LDA temp
	        	BEQ hsair_

	        	LDA #$00
	    		STA enemy_speed_x, x
	        	LDA #$BE
	    		STA enemy_speed_x + 1, x

	        	JMP hsaiei_
	        hsair_:
	        	LDA temp + 1
	        	BEQ hsail_

	        	LDA #$FF
	    		STA enemy_speed_x, x
	        	LDA #$3F
	        	STA enemy_speed_x + 1, x

	    	JMP hsaiei_
    hsait1ngtt2_:
    	INC enemy_temp_1, x
    hsaiei_:

    RTS

check_lr_solids:
	LDA #$00
	STA rt_val_1
    STA temp
    STA temp + 1

    LDY coord_x
    INY
    INY
    LDA [downc_pointer], y
    IS_SOLID_TILE clrsnsrt_
    	STA temp
    	STA rt_val_1
    clrsnsrt_:

    LDY coord_x
    DEX
    DEX
    LDA [downc_pointer], y
    IS_SOLID_TILE clrsnslt_
   		STA temp + 1
   		STA rt_val_1
    clrsnslt_:

    RTS

handle_bat_AI:
	RTS