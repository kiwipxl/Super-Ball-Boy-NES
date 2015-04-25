init_enemies:
	LDX enemy_max
	BEQ enemy_init_loop_end
	enemy_init_loop:
		DEX

		LDA #$00
		STA enemy_active, x
		INX
		DEX
		BEQ enemy_init_loop_end
		JMP enemy_init_loop
	enemy_init_loop_end:

	RTS

;creates a tile enemy set with specified enemy parameters
;input - (enemy_label_hi, enemy_label_lo, enemy rate, loop (0 or > 0), tile_x, tile_y)
create_slime:
	;loops through all enemies to find a non active enemy
	LDX enemy_max
	BEQ enemy_active_check_loop_end
	enemy_active_check_loop:
		DEX

		LDA enemy_active, x
		BNE enemy_is_active
			STX temp + 2
			JMP enemy_active_check_loop_end
		enemy_is_active:

		INX
		DEX
		BNE enemy_active_check_loop
	enemy_active_check_loop_end:

	RTS

update_enemies:
	LDX enemy_max
	BEQ enemy_update_loop_end
	enemy_update_loop:
		DEX

		LDA enemy_active, x
		BEQ enemy_update_chk_if_zero
		
		enemy_update_chk_if_zero:
		INX
		DEX
		BEQ enemy_update_loop_end
		JMP enemy_update_loop
	enemy_update_loop_end:
	
    RTS
