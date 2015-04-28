create_state:
	IF_EQU current_state, TITLE_SCREEN_STATE, ncstss_

	ncstss_:

	IF_EQU current_state, GAME_STATE, ncsgs_
		CALL load_chamber_1
	ncsgs_:

	IF_EQU current_state, WIN_STATE, ncsws_

	ncsws_:

	CONFIGURE_PPU

	RTS

remove_state:
	RTS

update_state:
	IF_EQU current_state, TITLE_SCREEN_STATE, nustss_

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

change_state:
	RTS