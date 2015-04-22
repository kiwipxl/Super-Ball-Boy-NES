check_collide_left:
    LDY coord_x + 1
    LDA [leftc_pointer], y
    CMP #$00
    BNE ncleft
        STA rt_val_1
        LDA coord_x + 1
        STA c_coord_x
        LDA coord_y + 2
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
        LDA coord_y + 2
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