check_collide_left:
    LDY coord_x + 1
    LDA [nt_pointer], y
    CMP #$00
    BNE ncleft
        SET_POINTER LEVEL_1_MAP_0, nt_pointer + 1, nt_pointer

        INC coord_y
        CALL_3 mul_short, nt_pointer + 1, coord_y, #$20
        SET_RT_VAL_2 nt_pointer + 1, nt_pointer

        LDY coord_x + 1
        LDA [nt_pointer], y
        CMP #$00
        BNE ncleft
            STA rt_val_1
            RTS
    ncleft:
    STA rt_val_1
    RTS

    ;LDA OAM_RAM_ADDR + 3
    ;CLC
    ;ADC #$07
    ;LSR a
    ;LSR a
    ;LSR a
    ;ASL a
    ;ASL a
    ;ASL a
    ;STA OAM_RAM_ADDR + 3

check_collide_right:
    SET_POINTER LEVEL_1_MAP_0, nt_pointer + 1, nt_pointer

    CALL_3 mul_short, nt_pointer + 1, coord_y + 1, #$20
    SET_RT_VAL_2 nt_pointer + 1, nt_pointer

    LDY coord_x
    INY
    LDA [nt_pointer], y
    CMP #$00
    BNE ncright
        SET_POINTER LEVEL_1_MAP_0, nt_pointer + 1, nt_pointer

        INC coord_y
        CALL_3 mul_short, nt_pointer + 1, coord_y, #$20
        SET_RT_VAL_2 nt_pointer + 1, nt_pointer

        LDY coord_x
        INY
        LDA [nt_pointer], y
        CMP #$00
        BNE ncright
            STA rt_val_1
            RTS
    ncright:
    STA rt_val_1
    RTS

check_collide_down:
    SET_POINTER LEVEL_1_MAP_0, nt_pointer + 1, nt_pointer

    INC coord_y + 1
    CALL_3 mul_short, nt_pointer + 1, coord_y + 1, #$20
    SET_RT_VAL_2 nt_pointer + 1, nt_pointer

    LDY coord_x
    LDA [nt_pointer], y
    CMP #$00
    BNE ncdown
        LDY coord_x + 1
        INY
        LDA [nt_pointer], y
        CMP #$00
        BNE ncdown
            STA rt_val_1
            RTS
    ncdown:
    STA rt_val_1
    RTS

check_collide_up:
    SET_POINTER LEVEL_1_MAP_0, nt_pointer + 1, nt_pointer

    CALL_3 mul_short, nt_pointer + 1, coord_y + 2, #$20
    SET_RT_VAL_2 nt_pointer + 1, nt_pointer

    LDY coord_x
    LDA [nt_pointer], y
    CMP #$00
    BNE ncup
        LDY coord_x + 1
        INY
        LDA [nt_pointer], y
        CMP #$00
        BNE ncup
            STA rt_val_1
            RTS
    ncup:
    STA rt_val_1
    RTS