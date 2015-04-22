;creates a tile animation set with specified animation parameters
;input - (ani_label_hi, ani_label_lo, animation rate, loop (0 or > 0), tile_x, tile_y)
create_tile_animation:
	LDX ani_num_running
	LDY #$00

	LDA param_3
	STA ani_rate, x

	LDA param_4
	STA ani_loop, x

	LDA ani_num_running
	ASL a
	TAX

	LDA param_1 + 1
	STA ani_frames, x

	LDA param_1
	STA ani_frames + 1, x

	LDA [ani_frames], y
	STA ani_num_frames, x

	INC ani_frames, x

	LDA current_VRAM
	STA ani_VRAM_pointer, x

	LDA current_VRAM + 1
	STA ani_VRAM_pointer + 1, x

	CALL_NESTED mul_short, ani_VRAM_pointer, param_6, #$20
	CALL_NESTED add_short, rt_val_1, rt_val_2, param_5

	LDA ani_num_running
	ASL a
	TAX

	LDA rt_val_1
	STA ani_VRAM_pointer, x
	LDA rt_val_2
	STA ani_VRAM_pointer + 1, x

	LDA #$00
	STA ani_frame_counter
	STA ani_current_frame

	INC ani_num_running

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
	;LDA ani_num_running

	RTS

update_animations:
	LDX ani_num_running
	BEQ ani_update_loop_end
	ani_update_loop:
		DEX

		INC ani_frame_counter, x
		LDA ani_frame_counter, x
		CMP ani_rate, x              	;sets carry flag if val_1 >= val_2
		BEQ fcgtrate     				;success if val_1 = val_2
		BCC nfcgtrate              		;fail if no carry flag set
		fcgtrate:
			LDA #$00
			STA ani_frame_counter, x

			INC ani_current_frame, x
			LDA ani_current_frame, x
			CMP ani_num_frames, x       ;sets carry flag if val_1 >= val_2
			BEQ cfgtnf     				;success if val_1 = val_2
			BCC nfcgtrate              	;fail if no carry flag set
			cfgtnf:
				LDA ani_loop, x
				BEQ ani_remove
					LDA #$00
					STA ani_current_frame, x
					JMP nfcgtrate
				ani_remove:
					DEC ani_num_running
		nfcgtrate:

		INX
		DEX
		BEQ ani_update_loop_end
		JMP ani_update_loop
	ani_update_loop_end:
	
    RTS