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
		CALL load_chamber_1

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
		ANY_BUTTON_DOWN usnabd_
			CALL change_state, GAME_STATE
		usnabd_:
		RTS
	nustss_:

	IF_EQU current_state, GAME_STATE, nusgs_
		CALL handle_room_intersect
	    CALL handle_camera_scroll

	    CALL update_player
	    CALL update_animations
	    CALL update_enemies

	    RTS
	nusgs_:

	IF_EQU current_state, WIN_STATE, nusws_
		RTS
	nusws_:

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
			LDA next_state
        	STA current_state

			CALL load_next_room

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