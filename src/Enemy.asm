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
	
	MUL8 param_1
	STA enemy_pos_x, x

	LDA #$0C
	STA OAM_RAM_ADDR + 5

	LDA #$03
	STA OAM_RAM_ADDR + 6

	MUL8 param_2
	STA enemy_pos_y, x

	LDA #$01
	STA enemy_active, x

	RTS

update_enemies:
	LDX enemy_len
	BEQ eule_
	eul_:
		DEX
		BEQ eule_

		LDA enemy_active, x
		BEQ eul_

		LDA enemy_pos_x, x
		STA OAM_RAM_ADDR + 4
		LDA enemy_pos_y, x
		STA OAM_RAM_ADDR + 7

		JMP eul_
	eule_:

    RTS