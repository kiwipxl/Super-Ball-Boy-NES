
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