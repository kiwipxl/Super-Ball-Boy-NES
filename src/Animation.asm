init_animations:
	LDX ani_max
	BEQ aacle_
	ail_:
		DEX
		BEQ aile_

		LDA #$00
		STA ani_active, x

		JMP ail_
	aile_:

	RTS

;creates a tile animation set with specified animation parameters
;input - (ani_label_hi, ani_label_lo, animation rate, loop (0 or > 0), tile_x, tile_y)
create_tile_animation:
	;loops through all animations to find a non active animation
	LDX ani_max
	BEQ aacle_
	aacl_:
		DEX
		BEQ aacle_

		LDA ani_active, x
		BNE aia_
			STX temp + 2
			JMP aacle_
		aia_:

		JMP aacl_
	aacle_:

	LDX temp + 2
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
	
	LDA current_VRAM_room
	STA ani_VRAM_pointer, x

	LDA current_VRAM_room + 1
	STA ani_VRAM_pointer + 1, x

	CALL mul_short, current_VRAM_room, param_6, #$20
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
	BEQ ani_update_loop_end
	ani_update_loop:
		DEX

		LDA ani_active, x
		BEQ ani_update_chk_if_zero

		INC ani_frame_counter, x
		LDA ani_frame_counter, x
		CMP ani_rate, x              		;sets carry flag if val_1 >= val_2
		BEQ fcgtrate     					;success if val_1 = val_2
		BCC nfcgtrate              			;fail if no carry flag set
		fcgtrate:
			LDA #$00
			STA ani_frame_counter, x

			INC ani_current_frame, x
			LDA ani_current_frame, x
			CMP ani_num_frames, x       	;sets carry flag if val_1 >= val_2
			BEQ cfgtnf     					;success if val_1 = val_2
			BCC nfcgtrate              		;fail if no carry flag set
			cfgtnf:
				LDA ani_loop, x
				LDA #$00
				STA ani_current_frame, x
				BNE nfcgtrate
					STA ani_active, x
		nfcgtrate:

		ani_update_chk_if_zero:
		INX
		DEX
		BEQ ani_update_loop_end
		JMP ani_update_loop
	ani_update_loop_end:
	
    RTS

play_spring_animation:
	CALL create_tile_animation, #HIGH(SPRING_ANI), #LOW(SPRING_ANI), #$01, #$00, c_coord_x, c_coord_y
	RTS