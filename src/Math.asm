;function to add two bytes (16 bit) together
;(high_byte, low_byte, value)
add_short:
    TSX

    LDA param_2                     ;load low 8 bits of 16 bit value
    CLC                             ;clear carry before adding with carry
    ADC param_3                     ;add a by param 3
    STA rt_val_2                    ;store low 8 bit result back

    LDA param_1                     ;load upper 8 bits
    ADC #$00                        ;add a by #$00 + the previous carry (0 or 1)
    STA rt_val_1                    ;store upper 8 bits result back

    RTS

;function to subtract two bytes (16 bit) together
;(high_byte, low_byte, value)
sub_short:
    TSX

    LDA param_2                     ;load low 8 bits of 16 bit value (parameter 2)
    SEC                             ;set the carry to 1 before subtracting with carry
    SBC param_3                     ;subtract a by parameter 3
    STA rt_val_2                    ;store low 8 bit result back

    LDA param_1                     ;load parameter 1
    SBC #$00                        ;subtract by #$00 + the previous carry (0 or 1)
    STA rt_val_1                    ;store upper 8 bits result back

    RTS
    
mul_byte:
    LDA param_2
    STA temp

    LDY param_1
    mul_add_loop:
        DEY
        BEQ mul_end_add_loop
        LDA param_2
        CLC
        ADC temp
        STA param_2
        JMP mul_add_loop
    mul_end_add_loop:
    
    LDA param_2
    STA rt_val_1
    
    RTS

mul_short:
    LDA param_2
    STA temp

    LDY param_3
    mul16_add_loop:
        DEY
        BEQ mul16_end_add_loop

        LDA param_2                     ;load low 8 bits of 16 bit value (parameter 2)
        CLC                             ;clear carry before adding with carry
        ADC temp                        ;add a by parameter 3
        STA param_2                     ;store low 8 bit result back

        LDA param_1                     ;load upper 8 bits
        ADC #$00                        ;add a by #$00 + the previous carry (0 or 1)
        STA param_1                     ;store upper 8 bits result back

        JMP mul16_add_loop
    mul16_end_add_loop:
    
    LDA param_1
    STA rt_val_1
    LDA param_2
    STA rt_val_2

    RTS

;function to divide an 8 bit number by a specified divisor

;proc
; - if divisor is > dividend then return 0
; - if divisor is = dividend then return 1
; - keep looping and bit shifting divisor and current left by 1 until divisor is > dividend
; - keep looping while current != 0
; - if dividend >= divisor then subtract dividend by divisor and or answer by current
; - bit shift current and divisor right by 1

;input -  (dividend, divisor)
;output - (byte_result)

div_byte:
    ;current ($0102, x)
    LDA #$01
    PHA
    ;result ($0101, x)
    LDA #$00
    PHA
    
    ;check if divisor is = dividend
    IF_EQU param_2, param_1, divddequ
        LDA #$01
        STA $0101, x
        LDA #$00
        STA param_1
        JMP end_div
    divddequ:

    ;check if dividend = 0
    LDA param_1
    BEQ div_result_equ0

    ;check if divisor = 0
    LDA param_2
    BNE div_no_equ0
    div_result_equ0:
        LDA #$00
        STA param_1
        JMP end_div
    div_no_equ0:

    STACK_TO_PARAMS $0105                   ;get params from stack and store them in param variables ($0103 + 2 local variables)

    ;keep looping and bitshifting left until divisor > dividend
    div_shift_loop:
        ;check if dividend is >= divisor
        IF_UNSIGNED_LT_OR_EQU param_2, param_1, end_div_shift_loop
            ROL param_2                 ;<< roll divisor left
            BCS divisor_overflow        ;if divisor overflows, jmp to label
            ROL $0102, x                ;<< roll current left
            JMP div_shift_loop
    divisor_overflow:
        ROR param_2                     ;ror back to the previous value before overflow
    end_div_shift_loop:

    div_cur_loop:
        ;if current is equal to 0, then end loop
        LDA $0102, x
        BEQ end_div_cur_loop
        ;check if dividend is >= divisor
        IF_UNSIGNED_GT_OR_EQU param_1, param_2, div_endif
            SUB param_1, param_2        ;subtract dividend by divisor
            STA param_1                 ;store in dividend
            LDA $0101, x                ;load result
            ORA $0102, x                ;or result with current
            STA $0101, x                ;store in result
        div_endif:
        LSR $0102, x                    ;logical shift current right
        LSR param_2                     ;logical shift divisor right
        JMP div_cur_loop
    end_div_cur_loop:

    end_div:

    ;store answer in rt_val_1
    LDA $0101, x
    STA rt_val_1

    ;check if the remainder (param_1) is equal to the divisor, if they are, the remainder will be 0
    IF_EQU param_1, param_3, rdnequ
        LDA #$00
    rdnequ:
    ;store remainder (param_1 or #$00) in rt_val_2
    STA rt_val_2

    POP_2                               ;pop current and result local variables

    RTS

;function to divide a 16 bit number by a specified divisor

;proc
; - divide high byte by divisor and store remainder
; - divide low byte by divisor
; - add low byte by (256 / divisor) * high byte remainder (while adding by 1 for high byte remainder overflows)

;temps
; - temp + 0 = temp remainder
; - temp + 1 = used to add by high byte remainder and if it overflows the high byte, add 1

;input -  (high_byte, low_byte, divisor)
;output - (high_byte_result, low_byte_result)

div_short:
    ;lbresult (low byte)    ($0102, x)
    LDA #$00
    PHA
    ;hbresult (high byte)   ($0101, x)
    LDA #$00
    PHA

    ;----------------------------------------

    STACK_TO_PARAMS $0105                   ;get params from stack and store them in param variables ($0103 + 2 local variables)

    ;divide high byte by divisor (param_3)
    CALL_NESTED div_byte, param_1, param_3
    TSX
    
    ;store division result in hbresult
    LDA rt_val_1
    STA $0101, x

    ;store division remainder in temp remainder local variable
    LDA rt_val_2
    STA temp

    ;----------------------------------------

    STACK_TO_PARAMS $0105                   ;get params from stack and store them in param variables ($0103 + 2 local variables)

    ;divide low byte by divisor (param_3)
    CALL_NESTED div_byte, param_2, param_3
    TSX

    ;store division result in lbresult
    LDA rt_val_1
    STA $0102, x

    ;----------------------------------------

    ;formula to get high byte remainding values = (256 / divisor) * remainder
    ;multiply the division remainder of the high byte (temp + 0) by 256 / divisor (rt_val_1)

    ;divide 256 by divisor (param_3)
    CALL_NESTED div_byte, #$FF, param_3

    STACK_TO_PARAMS $0105                   ;get params from stack and store them in param variables ($0103 + 2 local variables)

    LDY temp
    BEQ mul_divadd_loop_end
    LDA #$00
    STA temp + 1
    mul_divadd_loop:
        LDA $0102, x
        CLC
        ADC rt_val_1
        STA $0102, x

        ADD temp + 1, rt_val_2
        STA temp + 1
        IF_UNSIGNED_GT_OR_EQU temp + 1, param_3, endif_nparover
            INC $0102, x
            SUB temp + 1, param_3
            STA temp + 1
        endif_nparover:
        
        DEY
        BEQ mul_divadd_loop_end
        JMP mul_divadd_loop
    mul_divadd_loop_end:

    ;----------------------------------------

    ;store hbresult into rt_val_1
    LDA $0101, x
    STA rt_val_1
    ;store lbresult into rt_val_2
    LDA $0102, x
    STA rt_val_2

    POP_2                            ;pop the 2 local variables from the stack

    RTS

;function that clamps an unsigned byte to min and max values
;(byte, min, max)
;example - (my_val, #$04, #$FB)
clamp_signed:
    IF_SIGNED_GT param_2, param_1, valnotgtmin
        STA param_1
    valnotgtmin:

    IF_SIGNED_LT param_3, param_1, valnotltmin
        STA param_1
    valnotltmin:

    LDA param_1
    STA rt_val_1

    RTS

rand:
    LDA rand_seed
    BEQ doeor_
        ASL a
        BEQ noeor_                  ;if the input was $80, skip the EOR
        BCC noeor_
    doeor_:
        EOR #$1D
    noeor_:
        STA rand_seed
    STA rt_val_1

    RTS