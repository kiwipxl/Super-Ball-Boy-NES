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

;creates a slime enemy in a specified position
;input - (grid_x, grid_y)
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
	
	;---------------
	
	;store n in x
	STX temp + 2
	TXA
	ASL a
	;store n * 2 in x
	STA temp + 3
	ASL a
	;store n * 4 in x
	STA temp + 4
	
	;---------------
	
	LDX temp + 2
	LDA #$01
	STA enemy_active, x
	
	LDA #$00
	STA enemy_temp_1, x
	STA enemy_temp_3, x
	STA enemy_temp_4, x
	STA enemy_type, x
	
	LDA #$3F
	STA enemy_temp_2, x
	
	;---------------
	
	LDX temp + 3
	LDA #$00
	STA enemy_speed_x, x
	STA enemy_speed_x + 1, x
	STA enemy_gravity, x
	STA enemy_gravity + 1, x
	
	;---------------
	
	SET_POINTER_TO_VAL current_room, enemy_room + 1, x, enemy_room, x
	SET_POINTER_TO_VAL current_VRAM_addr, enemy_VRAM_addr + 1, x, enemy_VRAM_addr, x
	
	MUL8 param_1
	STA enemy_pos_x, x
	LDA #$00
	STA enemy_pos_x + 1, x

	MUL8 param_2
	STA enemy_pos_y, x
	LDA #$00
	STA enemy_pos_y + 1, x

	LDX temp + 4
	LDA #$0C
	STA OAM_RAM_ADDR + 5, x
	LDA #$02
	STA OAM_RAM_ADDR + 6, x
	
	RTS

update_enemies:
	LDX enemy_len
	eul_:
		;decrease x by 1 and if it is equal to #$FF then end the loop
		DEX
		CPX #$FF
		BEQ eule_
		
		;if the enemy is active (not 0), then continue, otherwise if not active, go to the start of the loop
		LDA enemy_active, x
		BEQ eul_
		
		;store n in x
		STX temp + 2
		TXA
	    ASL a
		;store n * 2 in x
	    STA temp + 3
		ASL a
		;store n * 4 in x
		STA temp + 4

		CALL handle_enemy_movement
	    CALL handle_enemy_collision
	    CALL handle_enemy_AI
		CALL handle_enemy_scroll_x
		
		JMP eul_
	eule_:

    RTS

handle_enemy_movement:
	LDX temp + 3
    CALL add_short, enemy_gravity, x, enemy_gravity + 1, x, #$40
    LDX temp + 3
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

		LDX temp + 3
	    IF_SIGNED_LT enemy_speed_x, x, #$00, hemnof_
	    	LDX temp + 4
	    	LDA #$10
			STA OAM_RAM_ADDR + 5, x
	hemnof_:

	LDX temp + 3
    ADD enemy_pos_y, x, enemy_gravity, x
    STA enemy_pos_y, x

    ADD enemy_pos_x, x, enemy_speed_x, x
    STA enemy_pos_x, x
	
    CALL add_short, enemy_pos_x, x, enemy_pos_x + 1, x, enemy_speed_x + 1, x
    LDX temp + 3
    ST_RT_VAL_IN enemy_pos_x, x, enemy_pos_x + 1, x
	
    RTS

handle_enemy_collision:
	LDX temp + 3

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
	
	LDX temp + 3
    SET_POINTER enemy_room, x, enemy_room + 1, x, downc_pointer + 1, downc_pointer
    CALL mul_short, downc_pointer + 1, coord_y + 1, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer
	
	LDX temp + 3
    SET_POINTER enemy_room, x, enemy_room + 1, x, upc_pointer + 1, upc_pointer
    CALL mul_short, upc_pointer + 1, coord_y + 2, #$20
    ST_RT_VAL_IN upc_pointer + 1, upc_pointer
	
    LDA #$00
    STA on_floor
	
    CALL check_collide_down
	LDX temp + 3
    LDA rt_val_1
    BEQ heclt0_
	    IF_SIGNED_GT_OR_EQU enemy_gravity, x, #$00, heclt0_
	    	LDA rt_val_1
	        CMP #$0A
	        BNE heclt0_
	        	LDX temp + 3
	        	MUL8 c_coord_y
	            STA enemy_pos_y, x

	            LDA #$FA
	            STA enemy_gravity, x
	            LDA #$00
	            STA enemy_gravity + 1, x
				
				;store enemy_VRAM_addr pointer in temp as CALL macro can't have too many parameters
				LDA enemy_VRAM_addr, x
				STA temp
				LDA enemy_VRAM_addr + 1, x
				STA temp + 1
				CALL create_tile_animation, #HIGH(SPRING_ANI), #LOW(SPRING_ANI), #$01, #$00, c_coord_x, c_coord_y, temp, temp + 1
	heclt0_:
		
    CALL add_short, downc_pointer + 1, downc_pointer, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer

    CALL check_collide_down
    LDA rt_val_1
    LDX temp + 3
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
    LDX temp + 3
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
    LDX temp + 3
    IS_SOLID_TILE enscleftendif
    	IF_SIGNED_LT_OR_EQU enemy_speed_x, x, #$00, enscleftendif
            MUL8 c_coord_x, #$01, #$00, enemy_pos_x, x

            LDA #$00
            STA enemy_speed_x, x
            STA enemy_speed_x + 1, x
    enscleftendif:
	
    CALL check_collide_right
    LDX temp + 3
    IS_SOLID_TILE enscrightendif
        IF_SIGNED_GT_OR_EQU enemy_speed_x, x, #$00, enscrightendif
            MUL8 c_coord_x, #$00, #$01, enemy_pos_x, x

            LDA #$00
            STA enemy_speed_x, x
            STA enemy_speed_x + 1, x
    enscrightendif:

    LDX temp + 2
    LDA enemy_temp_3, x
    BEQ hecsnj_
	    INC enemy_temp_3, x
	    IF_UNSIGNED_GT enemy_temp_3, x, #$04, hecsnj_
	    	LDA #$00
	    	STA enemy_temp_3, x

	    	LDA #$00
	    	STA enemy_temp_1, x
	    	CALL rand
	    	LSR a
	    	LSR a
			LSR a
	    	CLC
	    	ADC #$10
	    	STA enemy_temp_2, x

	    	LDX temp + 3
	    	LDA #$FD
	        STA enemy_gravity, x
	        LDA #$7F
	        STA enemy_gravity + 1, x

	        CALL check_lr_solids
			LDA temp
			BNE hecein0_
				LDA temp + 1
				BEQ hecsnj_
			hecein0_:
			
			LDX temp + 3
	        CALL rand
	        IF_SIGNED_GT rt_val_1, #$00, hecl_
	        hecr_:
	        	LDA temp
	        	BEQ hecl_

	        	LDA #$00
	    		STA enemy_speed_x, x
	        	LDA #$EB
	    		STA enemy_speed_x + 1, x

	        	JMP hecsnj_
	        hecl_:
	        	LDA temp + 1
	        	BEQ hecr_

	        	LDA #$FF
	    		STA enemy_speed_x, x
	        	LDA #12
	        	STA enemy_speed_x + 1, x
    hecsnj_:

    RTS

handle_enemy_AI:
	LDX temp + 2
	LDA enemy_type, x
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
	LDA enemy_temp_3, x
	BNE hsaiei_
	    IF_UNSIGNED_GT_OR_EQU enemy_temp_1, x, enemy_temp_2, x, hsait1ngtt2_
	    	IF_EQU on_floor, #$01, hsaiei_
	    		LDA #$01
	    		STA enemy_temp_3, x
	    		JMP hsaiei_
	    hsait1ngtt2_:
			LDX temp + 2
	    	INC enemy_temp_1, x
    hsaiei_:

    RTS

check_lr_solids:
	LDA #$00
    STA temp
    STA temp + 1

    LDY coord_x
    INY
    INY
    INY
    LDA [downc_pointer], y
	CMP #$0A
	BEQ clrsrt_
    IS_SOLID_TILE clrsnsrt_
		clrsrt_:
			STA temp
    clrsnsrt_:

    LDY coord_x
    DEY
    DEY
    DEY
    LDA [downc_pointer], y
	CMP #$0A
	BEQ clrslt_
    IS_SOLID_TILE clrsnslt_
		clrslt_:
			STA temp + 1
    clrsnslt_:
	
	CALL sub_short, downc_pointer + 1, downc_pointer, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer
	
	LDY coord_x
    INY
    INY
    INY
    LDA [downc_pointer], y
	CMP #$0A
	BEQ clrsrtl_
	IS_SOLID_TILE clrsnsrtu1_
		clrsrtl_:
			LDA #$00
			STA temp
    clrsnsrtu1_:

    LDY coord_x
    DEY
    DEY
    DEY
    LDA [downc_pointer], y
	CMP #$0A
	BEQ clrsrtr_
	IS_SOLID_TILE clrsnsltu1_
		clrsrtr_:
			LDA #$00
			STA temp + 1
    clrsnsltu1_:
	
    RTS

handle_bat_AI:
	RTS

handle_enemy_scroll_x:
	LDX temp + 3
	IF_EQU room_1, enemy_room, x, hesxei_
		IF_UNSIGNED_LT_OR_EQU scroll_x, enemy_pos_x, x, hesxhe_
		JMP hesxns_
	hesxei_:
		IF_UNSIGNED_GT_OR_EQU scroll_x, enemy_pos_x, x, hesxhe_
	hesxns_:

	LDX temp + 3
	LDA enemy_pos_y, x
	SEC
	SBC #$01
	LDX temp + 4
	STA OAM_RAM_ADDR + 4, x

	LDX temp + 3
	LDA enemy_pos_x, x
	SEC
	SBC scroll_x
	LDX temp + 4
	STA OAM_RAM_ADDR + 7, x

	LDX temp + 2
	RTS
	
	hesxhe_:
		LDX temp + 4
		LDA #$FF
		STA OAM_RAM_ADDR + 4, x
		LDA #$FF
		STA OAM_RAM_ADDR + 7, x
		LDX temp + 2
		RTS
		