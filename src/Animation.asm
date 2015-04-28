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

;creates a tile animation set with specified animation parameters
;input - (ani_label_hi, ani_label_lo, animation rate, loop (0 or > 0), tile_x, tile_y, VRAM_id_hi, VRAM_id_lo)
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
		RTS
	aaclfe_:

	STX temp + 2
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

	;----------

	LDA #$00
	STA ani_frame_counter, x
	STA ani_current_frame, x

	LDA #$01
	STA ani_active, x

	;----------

	LDA temp + 2
	ASL a
	TAX

	LDA param_1 + 1
	STA ani_frames, x

	LDA param_1
	STA ani_frames + 1, x

	INC ani_frames, x

	;----------
	
	CALL mul_short, param_7, param_6, #$20
	CALL add_short, rt_val_1, rt_val_2, param_5

	LDA temp + 2
	ASL a
	TAX

	LDA rt_val_1
	STA ani_VRAM_pointer, x
	LDA rt_val_2
	STA ani_VRAM_pointer + 1, x

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