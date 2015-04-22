check_collide_left:
    LDY coord_x + 1
    LDA [leftc_pointer], y
    CMP #$00
    BNE ncleft
        ;CALL_3 add_short, leftc_pointer + 1, leftc_pointer, #$20
        ;SET_RT_VAL_2 leftc_pointer + 1, leftc_pointer

        ;LDY coord_x + 1
        ;LDA [leftc_pointer], y
        ;CMP #$00
        ;BNE ncleft
            STA rt_val_1
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
        ;CALL_3 add_short, rightc_pointer + 1, rightc_pointer, #$20
        ;SET_RT_VAL_2 rightc_pointer + 1, rightc_pointer
        
        ;LDY coord_x
        ;INY
        ;LDA [rightc_pointer], y
        ;CMP #$00
        ;BNE ncright
            STA rt_val_1
            RTS
    ncright:
    STA rt_val_1
    RTS

check_collide_down:
    CALL add_short, downc_pointer + 1, downc_pointer, #$20
    SET_RT_VAL_2 downc_pointer + 1, downc_pointer

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
            STA rt_val_1
            RTS
    ncdown:
    STA rt_val_1
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
            STA rt_val_1
            RTS
    ncup:
    STA rt_val_1
    RTS
    ncup2:
    LDA #$00
    STA rt_val_1
    RTS