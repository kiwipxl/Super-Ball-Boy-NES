create_state:
	IF_EQU current_state, TITLE_SCREEN_STATE, ncstss_
		SET_POINTER_TO_ADDR VRAM_NT_0, PPU_ADDR, PPU_ADDR
	    SET_POINTER_TO_ADDR TITLE_SCREEN_NT, nt_pointer + 1, nt_pointer

	    CALL load_nametable
	ncstss_:

	IF_EQU current_state, GAME_STATE, ncsgs_
		CALL load_chamber_1
	ncsgs_:

	IF_EQU current_state, WIN_STATE, ncsws_

	ncsws_:

	CONFIGURE_PPU

	RTS

remove_state:
	IF_EQU current_state, GAME_STATE, nrsgs_

	nrsgs_:

	RTS

update_state:
	IF_EQU current_state, TITLE_SCREEN_STATE, nustss_
		ANY_BUTTON_DOWN usnabd_
			CALL change_state, GAME_STATE
		usnabd_:

	nustss_:

	IF_EQU current_state, GAME_STATE, nusgs_
		CALL handle_room_intersect
	    CALL handle_camera_scroll

	    CALL update_player
	    CALL update_animations
	    CALL update_enemies
	nusgs_:

	IF_EQU current_state, WIN_STATE, nusws_
		
	nusws_:

	RTS

update_render_state:
	IF_EQU current_state, GAME_STATE, nursgs_
		CALL render_animations
	nursgs_:

	RTS

change_state:
	CALL remove_state

	LDA param_1
	STA current_state

	CALL create_state

	RTS