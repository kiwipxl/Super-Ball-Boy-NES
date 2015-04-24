handle_camera_scroll:
     LDA scroll_x_type
    BNE right_scroll_map
        IF_UNSIGNED_GT_OR_EQU pos_x, #$7F, scrleftstartelse
            ADD scroll_x, speed_x
            STA scroll_x
            ADD pos_x, speed_x
            STA pos_x
            LDA #$7F
            STA OAM_RAM_ADDR + 3
            IF_SIGNED_LT_OR_EQU scroll_x, #$00, scroll_x_endif
                IF_SIGNED_GT scroll_x, #$F8, scroll_x_endif
                    LDA #$00
                    STA scroll_x
                    JMP scroll_x_endif
        scrleftstartelse:
            ADD pos_x, speed_x
            STA pos_x
            STA OAM_RAM_ADDR + 3
            LDA #$00
            STA scroll_x
            JMP scroll_x_endif
    right_scroll_map:
        IF_UNSIGNED_LT_OR_EQU pos_x, #$7F, scrrightstartelse
            ADD scroll_x, speed_x
            STA scroll_x
            ADD pos_x, speed_x
            STA pos_x
            LDA #$7F
            STA OAM_RAM_ADDR + 3
            IF_SIGNED_GT_OR_EQU scroll_x, #$FF, scroll_x_endif
                IF_SIGNED_LT scroll_x, #$08, scroll_x_endif
                    LDA #$FF
                    STA scroll_x
                    JMP scroll_x_endif
        scrrightstartelse:
            ADD pos_x, speed_x
            STA pos_x
            STA OAM_RAM_ADDR + 3
            LDA #$FF
            STA scroll_x
    scroll_x_endif:

    RTS

handle_room_intersect:
    IF_NOT_EQU scroll_x_type, #$00, ntransleft
    IF_SIGNED_LT speed_x, #$00, ntransleft
        IF_SIGNED_GT speed_x, #$80, ntransleft
            IF_UNSIGNED_GT_OR_EQU pos_x, #$F8, ntransleft
                SET_POINTER_TO_ADDR LEVEL_1_MAP_0, current_room, current_room + 1
                SET_POINTER_TO_ADDR VRAM_NT_0, current_VRAM, current_VRAM + 1

                LDA #$FF
                STA pos_x

                LDA #$7F
                STA scroll_x

                LDA #$00
                STA scroll_x_type
                JMP ntransright
    ntransleft:

    IF_SIGNED_GT speed_x, #$00, ntransright
        IF_SIGNED_LT speed_x, #$7F, ntransright
            IF_UNSIGNED_GT_OR_EQU pos_x, #$FB, ntransright
                SET_POINTER_TO_ADDR LEVEL_1_MAP_1, current_room, current_room + 1
                SET_POINTER_TO_ADDR VRAM_NT_1, current_VRAM, current_VRAM + 1

                LDA #$00
                STA pos_x

                LDA #$80
                STA scroll_x

                LDA #$01
                STA scroll_x_type
    ntransright:
    RTS

respawn:
    LDA rt_val_1
    CMP #$0B
    BNE respawn_endif
        SET_POINTER_TO_ADDR LEVEL_1_MAP_1, current_room, current_room + 1
        LDA #$01
        STA scroll_x_type

        LDA player_spawn
        STA OAM_RAM_ADDR + 3
        STA pos_x

        SEC
        SBC #$7F
        STA scroll_x

        LDA player_spawn + 1
        STA OAM_RAM_ADDR + 3
        STA pos_y
    respawn_endif:

    RTS

check_collide_left:
    LDY coord_x + 1
    LDA [leftc_pointer], y
    CMP #$00
    BNE ncleft
        STA rt_val_1
        LDA coord_x + 1
        STA c_coord_x
        LDA coord_y + 1
        STA c_coord_y
        LDA rt_val_1
        RTS
    ncleft:
    STA rt_val_1
    RTS

check_collide_right:
    LDY coord_x
    INY
    LDA [rightc_pointer], y
    CMP #$00
    BNE ncright
        STA rt_val_1
        LDA coord_x
        CLC
        ADC #$01
        STA c_coord_x
        LDA coord_y + 1
        STA c_coord_y
        LDA rt_val_1
        RTS
    ncright:
    STA rt_val_1
    RTS

check_collide_down:
    CALL add_short, downc_pointer + 1, downc_pointer, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer

    LDY coord_x
    LDA [downc_pointer], y
    CMP #$00
    BNE ncdown
        IF_UNSIGNED_LT coord_x + 1, #$1F, ncdown2
        LDY coord_x + 1
        INY
        LDA [downc_pointer], y
        CMP #$00
        BNE ncdown
            ;todo: clean this stuff up!
            STA rt_val_1

            TYA
            STA c_coord_x
            LDA coord_y
            CLC
            ADC #$01
            STA c_coord_y
            LDA rt_val_1

            RTS
    ncdown:
    ;todo: clean this stuff up!
    STA rt_val_1

    TYA
    STA c_coord_x
    LDA coord_y
    CLC
    ADC #$01
    STA c_coord_y
    LDA rt_val_1
    
    RTS
    ncdown2:
    LDA #$00
    STA rt_val_1
    RTS

check_collide_up:
    LDY coord_x
    LDA [upc_pointer], y
    CMP #$00
    BNE ncup
        IF_UNSIGNED_LT coord_x + 1, #$1F, ncup2
        LDY coord_x + 1
        INY
        LDA [upc_pointer], y
        CMP #$00
        BNE ncup
            ;todo: clean this stuff up
            STA rt_val_1
            LDA coord_x + 1
            CLC
            ADC #$01
            STA c_coord_x
            LDA coord_y
            STA c_coord_y
            LDA rt_val_1
            RTS
    ncup:
    ;todo: clean this stuff up
    STA rt_val_1
    LDA coord_x
    STA c_coord_x
    LDA coord_y
    STA c_coord_y
    LDA rt_val_1
    RTS
    ncup2:
    LDA #$00
    STA rt_val_1
    RTS