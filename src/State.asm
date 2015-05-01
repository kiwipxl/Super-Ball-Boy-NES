create_state:
	IF_EQU current_state, TITLE_SCREEN_STATE, ncstss_
		SET_POINTER_TO_ADDR VRAM_NT_0, VRAM_pointer, VRAM_pointer + 1
		SET_POINTER_TO_ADDR VRAM_NT_0, PPU_ADDR, PPU_ADDR
	    SET_POINTER_TO_ADDR TITLE_SCREEN_NT, nt_pointer + 1, nt_pointer

	    LDA #$00
	    STA row_index
	    STA row_index + 1

	    LDA NT_LOADING_STATE
	    STA current_state

	    RTS
	ncstss_:

	IF_EQU current_state, GAME_STATE, ncsgs_
		LDX #$00
	    coaml_:
	        LDA #$FF
	        STA OAM_RAM_ADDR, x             ;set OAM (object attribute memory) in RAM to #$FF so that sprites are off-screen

	        INX                             ;increase x by 1
	        CPX #$00                        ;check if x has overflowed into 0
	        BNE coaml_                      ;continue clearing memory if x is not equal to 0

		IF_EQU current_chamber, #$00, cscc0_
			CALL load_chamber_1
		cscc0_:
		IF_EQU current_chamber, #$01, cscc1_
			CALL load_chamber_2
		cscc1_:
		IF_EQU current_chamber, #$02, cscc2_
			CALL load_chamber_3
		cscc2_:
		IF_EQU current_chamber, #$03, cscc3_
			CALL change_state, TITLE_SCREEN_STATE
			LDA #$FF
			STA current_chamber
		cscc3_:

		INC current_chamber

		RTS
	ncsgs_:

	IF_EQU current_state, WIN_STATE, ncsws_
		RTS
	ncsws_:

	RTS

remove_state:
	IF_EQU current_state, GAME_STATE, nrsgs_
		RTS
	nrsgs_:

	RTS

update_state:
	IF_EQU current_state, TITLE_SCREEN_STATE, nustss_
		INC rand_seed
		ANY_BUTTON_DOWN usnabd_
			CALL change_state, GAME_STATE
		usnabd_:

		RTS
	nustss_:

	IF_EQU current_state, GAME_STATE, nusgs_
	    CALL update_player

	    CALL handle_room_intersect
	    CALL handle_camera_scroll

	    CALL update_animations
	    CALL update_enemies

	    SELECT_BUTTON_DOWN usnsbd_
			CALL change_state, GAME_STATE
		usnsbd_:
		
	    RTS
	nusgs_:

	IF_EQU current_state, WIN_STATE, nusws_
		RTS
	nusws_:

	IF_EQU current_state, NT_CHAMBER_SCAN_STATE, nusntcss_
		CALL scan_room

		LDA next_state
    	STA current_state

		CALL load_next_room

		RTS
	nusntcss_:

	RTS

update_render_state:
	IF_EQU current_state, NT_LOADING_STATE, nursnls_
		IF_EQU row_index, #$04, ursrin0_
			LDA next_state
			STA current_state
			RTS
		ursrin0_:

		SET_POINTER_TO_VAL VRAM_pointer, PPU_ADDR, PPU_ADDR
		CALL load_nametable
		CONFIGURE_PPU

		RTS
	nursnls_:

	IF_EQU current_state, NT_CHAMBER_LOADING_STATE, nursntcls_
		IF_EQU row_index, #$04, ursrinl0_
			LDA NT_CHAMBER_SCAN_STATE
			STA current_state
			RTS
		ursrinl0_:

		SET_POINTER_TO_VAL VRAM_pointer, PPU_ADDR, PPU_ADDR
		CALL load_room
		CONFIGURE_PPU

		RTS
	nursntcls_:

	IF_EQU current_state, GAME_STATE, nursgs_
	    CALL render_animations

		RTS
	nursgs_:

	RTS

change_state:
	CALL remove_state

	LDA param_1
	STA next_state
	STA current_state

	CALL create_state

	CONFIGURE_PPU

	RTS