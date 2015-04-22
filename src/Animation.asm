init_animations:
	LDX ani_max
	BEQ ani_init_loop_end
	ani_init_loop:
		DEX

		LDA #$00
		STA ani_active, x
		INX
		DEX
		BEQ ani_init_loop_end
		JMP ani_init_loop
	ani_init_loop_end:

	RTS

;creates a tile animation set with specified animation parameters
;input - (ani_label_hi, ani_label_lo, animation rate, loop (0 or > 0), tile_x, tile_y)
create_tile_animation:
	;loops through all animations to find a non active animation
	LDX ani_max
	BEQ ani_active_check_loop_end
	ani_active_check_loop:
		DEX

		LDA ani_active, x
		BNE ani_is_active
			STX temp + 2
			JMP ani_active_check_loop_end
		ani_is_active:

		INX
		DEX
		BNE ani_active_check_loop
	ani_active_check_loop_end:
	
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
	
	LDA current_VRAM
	STA ani_VRAM_pointer, x

	LDA current_VRAM + 1
	STA ani_VRAM_pointer + 1, x

	CALL mul_short, current_VRAM, param_6, #$20
	CALL add_short, rt_val_1, rt_val_2, param_5

	LDA temp + 2
	ASL a
	TAX

	LDA rt_val_1
	STA ani_VRAM_pointer, x
	LDA rt_val_2
	STA ani_VRAM_pointer + 1, x

	;----------

	;debugging stuff
	;DEBUG_BRK
	;LDA ani_frames
	;LDA ani_frames + 1
	;LDA [ani_frames], y
	;LDY #$01
	;LDA current_VRAM
	;LDA current_VRAM + 1
	;LDA ani_VRAM_pointer
	;LDA ani_VRAM_pointer + 1
	;LDY #$02
	;LDA ani_rate
	;LDY #$04
	;LDA ani_frame_counter
	;LDY #$08
	;LDA ani_current_frame
	;LDY #$10
	;LDA ani_loop
	;LDY #$20
	;LDA ani_num_frames
	;LDY #$40
	;LDA temp + 2

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