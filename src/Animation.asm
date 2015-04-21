;creates a tile animation set with specified animation parameters
;input - (ani_label, frame_label, animation rate, loop (0 or > 0), tile_x, tile_y, nt_pointer_hi)
CREATE_TILE_ANIMATION .macro
	LDY ani_num_running
	INY
	STA ani_num_running
	DEY
	
	LDA \3
	STA ani_rate, y
	
	LDA \4
	STA ani_loop, y
	
	LDA \1
	STA ani_num_frames, y
	
	ASL ani_num_running
	TAY
	
	LDA \5
	STA ani_tile_pos, y
	
	LDA #HIGH(\2)
	STA ani_frames, y
	
	LDA \6
	STA ani_nt_pointer, y
	
	INY
	LDA \6
	STA ani_tile_pos + 1, y
	
	LDA #LOW(\2)
	STA ani_frames + 1, y
	
	LDA \7
	STA ani_nt_pointer + 1, y
	
	LDA #$00
	STA ani_frame_counter
	STA ani_current_frame
	
	.endm
	
update_animations:
	LDX ani_num_running
	ani_update_loop:
		INC ani_frame_counter, x
		;LDA ani_frame_counter, x
		CMP ani_rate, x              	;sets carry flag if val_1 >= val_2
		BEQ fcgtrate     				;success if val_1 = val_2
		BCC nfcgtrate              		;fail if no carry flag set
		fcgtrate:
			LDA #$00
			STA ani_frame_counter, x
			
			INC ani_current_frame, x
			CMP ani_num_frames, x       ;sets carry flag if val_1 >= val_2
			BEQ cfgtnf     				;success if val_1 = val_2
			BCC nfcgtrate              	;fail if no carry flag set
			cfgtnf:
				LDA #$00
				STA ani_current_frame, x
		nfcgtrate:
		
		;LDY ani_current_frame, x
		;LDA [ani_frames], y
		;STA temp
		
		;TXA
		;ASL a
		;TAY
		
		;LDA ani_tile_pos, y
		;STA temp + 1
		
		;SET_POINTER_HI_LO ani_nt_pointer, nt_pointer + 1, nt_pointer
		;CALL_3 mul_short, nt_pointer + 1, temp + 1, #$20
		;SET_RT_VAL_2 nt_pointer + 1, nt_pointer
		
		;LDA ani_tile_pos + 1, y
		;TAY
		;LDA temp
		;STA [nt_pointer], y
		
		DEX
		BEQ ani_update_loop_end
		JMP ani_update_loop
	ani_update_loop_end:
	
    RTS