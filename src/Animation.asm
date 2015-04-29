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

	DEBUG_BRK
	LDY #$01
	LDA param_1
	LDA param_2
	LDA param_3
	LDA param_4
	CALL_NESTED mul_short, param_3, param_2, #$20
	CALL_NESTED add_short, rt_val_1, rt_val_2, param_1

	LDA ani_last_id
	ASL a
	TAX

	DEBUG_BRK
	LDY #$01
	LDA param_3
	STA ani_VRAM_pointer, x
	LDA param_4
	STA ani_VRAM_pointer + 1, x

	RTS

;sets animation attribs to the last created animation (this should be called after creation)
;input - (ani_label_hi, ani_label_lo, animation rate, loop (0 or > 0))
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
	TAX

	LDA param_1 + 1
	STA ani_frames, x

	LDA param_1
	STA ani_frames + 1, x

	INC ani_frames, x

	DEBUG_BRK
	LDA ani_VRAM_pointer, x
	LDA ani_VRAM_pointer + 1, x
	LDX ani_last_id
	LDA ani_rate, x
	LDA ani_loop, x
	LDA ani_num_frames, x
	LDA ani_tile_x, x
	LDA ani_tile_y, x

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
        TAX

        SET_POINTER ani_VRAM_pointer, x, ani_VRAM_pointer + 1, x, PPU_ADDR, PPU_ADDR
        SET_POINTER ani_frames, x, ani_frames + 1, x, temp, temp + 1

        LDX temp + 2
        LDY ani_current_frame, x
        LDA [temp], y
        STA PPU_DATA

        JMP arl_
    arle_:
    CONFIGURE_PPU

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