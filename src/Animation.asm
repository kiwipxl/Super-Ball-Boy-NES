init_animations:
	LDX ani_max
	BEQ aile_
	ail_:
		DEX
		BEQ aile_

		LDA #$00
		STA ani_active, x

		JMP ail_
	aile_:

	RTS

;creates a tile animation set with specified tile parameters
;you should set animation attribs after calling this function
;input - (tile_x, tile_y, VRAM_id_hi, VRAM_id_lo)
create_tile_animation:
	;loops through all animations to find a non active animation
	LDX ani_max
	aacl_:
		DEX
		CPX #$FF
		BEQ aacle_

		LDA ani_active, x
		BEQ aaclfe_

		JMP aacl_
	aacle_:
		LDA #$FF
		STA ani_last_id
		RTS
	aaclfe_:

	STX ani_last_id
	LDY #$00

	LDA #$01
	STA ani_active, x

	LDA param_1
	STA ani_tile_x, x
	LDA param_2
	STA ani_tile_y, x

	CALL_NESTED mul_short, param_3, param_2, #$20
	CALL_NESTED add_short, rt_val_1, rt_val_2, param_1

	LDA ani_last_id
	ASL a
	TAX

	LDA rt_val_1
	STA ani_VRAM_pointer, x
	LDA rt_val_2
	STA ani_VRAM_pointer + 1, x

	RTS

;sets animation attribs to the last created animation (this should be called after creation)
;input - (ani_label_hi, ani_label_lo, animation rate, loop (0 or > 0), palette_index)
set_animation_attribs:
	LDX ani_last_id
	CPX #$FF
	BNE saane_
		RTS
	saane_:
	LDY #$00

	LDA param_3
	STA ani_rate, x

	LDA param_4
	STA ani_loop, x

	LDA param_5
	STA ani_palette_index, x

	;----------

	LDA param_1 + 1
	STA temp
	LDA param_1
	STA temp + 1

	LDA [temp], y
	STA ani_num_frames, x

	LDA #$00
	STA ani_frame_counter, x
	STA ani_current_frame, x

	;----------

	LDA ani_last_id
	ASL a
	STA temp + 2
	TAX

	LDA param_1 + 1
	STA ani_frames, x

	LDA param_1
	STA ani_frames + 1, x

	INC ani_frames, x

	;----------

	SET_POINTER_TO_ADDR VRAM_ATTRIB_2, temp + 3, temp + 4

	LDX ani_last_id

    LDA ani_tile_x, x
    LSR a
    LSR a
    CLC
    ADC temp + 4
    STA temp + 4
    LDA ani_tile_y, x
    LSR a
    LSR a
    STA temp
    CALL mul_byte, temp, #$08
    CLC
    ADC temp + 4
    STA temp + 4

    LDX temp + 2
    SET_POINTER_TO_VAL temp + 3, ani_palette_index, x, ani_palette_index + 1, x

	RTS

update_animations:
	LDX ani_max
	aul_:
		DEX
		CPX #$FF
		BEQ aule_

		LDA ani_active, x
		BEQ aul_

		INC ani_frame_counter, x
		IF_UNSIGNED_GT_OR_EQU ani_frame_counter, x, ani_rate, x, aulngt_
			LDA #$00
			STA ani_frame_counter, x

			INC ani_current_frame, x
			IF_UNSIGNED_GT_OR_EQU ani_current_frame, x, ani_num_frames, x, aulngt_
				LDA #$00
				STA ani_current_frame, x
				LDA ani_loop, x
				BNE aulngt_
					STA ani_active, x
		aulngt_:

		JMP aul_
	aule_:

    RTS

render_animations:
	LDX ani_max
    arl_:
        DEX
        CPX #$FF
        BEQ arle_

        LDA ani_active, x
        BEQ arl_

        STX temp + 2
        TXA
        ASL a
        STX temp + 1
        TAX

        SET_POINTER ani_VRAM_pointer, x, ani_VRAM_pointer + 1, x, PPU_ADDR, PPU_ADDR
        SET_POINTER ani_frames, x, ani_frames + 1, x, temp, temp + 1

        LDX temp + 2
        LDY ani_current_frame, x
        LDA [temp], y
        STA PPU_DATA

        CALL change_palette_value

        JMP arl_
    arle_:
    CONFIGURE_PPU

    RTS

change_palette_value:
	SET_POINTER_TO_ADDR VRAM_ATTRIB_2, PPU_ADDR, PPU_ADDR
    DEBUG_BRK
    LDA PPU_DATA
    STA temp
    AND #$80
    LDA temp
    AND #$30
    LDA temp
    AND #$0C

    DEBUG_BRK
    LDX temp + 2
    LDA ani_tile_x, x
    AND #$01
    BEQ raright_
    	LDA ani_tile_y, x
    	AND #$01
        BEQ ratopright_ 		;bottom right
        	DEBUG_BRK
        	LDY #$00

        	JMP ralrtdei_
        ratopright_: 			;top right
        	DEBUG_BRK
        	LDY #$01

        	JMP ralrtdei_
    raright_:
        LDA ani_tile_y, x
        AND #$01
        BEQ ratopleft_ 			;bottom left
        	DEBUG_BRK
        	LDY #$02

        	JMP ralrtdei_
        ratopleft_: 			;top left
        	DEBUG_BRK
        	LDY #$04

        	JMP ralrtdei_
    ralrtdei_:

    ;tile_x >> 2 = x offset
    ;tile_y >> 2 * 8 = y offset
	;tile_x rol 1, carry flag (0) = left, (1) = right
	;tile_y rol 1, carry flag (0) = top, (1) = down

	;11 >> 2 = 2
	;16 >> 2 = 4
	;right
	;top

    ;palette_index >> 6
    ;store in temp
    ;if tile topright for example, then subtract by 0c and add temp

    RTS

remove_animation_at:
	LDX ani_max
	BEQ nrale_
	nral_:
		DEX
		BEQ nrale_

		LDA ani_active, x
		BEQ nral_

		STX temp
		TXA
		ASL a
		TAX
		IF_EQU ani_tile_x, x, param_1, nraaxyne_
			IF_EQU ani_tile_y, x, param_2, nraaxyne_
				LDX temp
				LDA #$00
				STA ani_active, x
		nraaxyne_:

		LDX temp

		JMP nral_
	nrale_:

	RTS