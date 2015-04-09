;function to add two bytes (16 bit) together
;(high_byte, low_byte, value)
add_short:
    TSX

    LDA $0104, x                    ;load low 8 bits of 16 bit value (parameter 2)
    CLC                             ;clear carry before adding with carry
    ADC $0105, x                    ;add a by parameter 3
    STA rt_val_2                    ;store low 8 bit result back

    LDA $0103, x                    ;load upper 8 bits
    ADC #$00                        ;add a by #$00 + the previous carry (0 or 1)
    STA rt_val_1                    ;store upper 8 bits result back

    RTS

;function to subtract two bytes (16 bit) together
;(high_byte, low_byte, value)
sub_short:
    TSX

    LDA $0104, x                    ;load low 8 bits of 16 bit value (parameter 2)
    SEC                             ;set the carry to 1 before subtracting with carry
    SBC $0105, x                    ;subtract a by parameter 3
    STA rt_val_2                    ;store low 8 bit result back

    LDA $0103, x                    ;load parameter 1
    SBC #$00                        ;subtract by #$00 + the previous carry (0 or 1)
    STA rt_val_1                    ;store upper 8 bits result back

    RTS
	
mul_byte:
    STORE_PAR_2 $0103

	LDY $0103, x
	mul_add_loop:
		DEY
		BEQ mul_end_add_loop
		LDA param_2
		CLC
		ADC $0104, x
		STA param_2
		JMP mul_add_loop
	mul_end_add_loop:
	
	LDA param_2
	STA rt_val_1
	
    RTS

;function to divide an 8 bit number by a specified divisor

;proc
; - divide high byte by divisor and store remainder
; - divide low byte by divisor
; - add low byte by (256 / divisor) * high byte remainder

;input -  (dividend, divisor)
;output - (byte_result)

div_byte:
    ;current ($0102, x)
    LDA #$01
    PHA
    ;answer  ($0101, x)
    LDA #$00
    PHA

    STORE_PAR_2 $0105                   ;get params from stack and store them in param variables ($0103 + 2 local variables)

    ;check if divisor is > dividend
    IF_UNSIGNED_GT param_2, param_1, divddlthan
        ;set the answer to 0 and jmp to the end of the function
        LDA #$00
        STA $0101, x
        JMP end_div
    divddlthan:

    ;check if divisor is = dividend
    IF_EQU param_2, param_1, divddequ
        ;set the answer to 1 and jmp to the end of the function
        LDA #$01
        STA $0101, x
        JMP end_div
    divddequ:

    ;while (divisor <= dividend)
    div_shift_loop:
        IF_UNSIGNED_LT_OR_EQU param_2, param_1, end_div_shift_loop
            ROL param_2
            ROL $0102, x
            JMP div_shift_loop
    end_div_shift_loop:
    LSR param_2
    LSR $0102, x

    ;while (current != 0)
    div_cur_loop:
        ;if current is equal to 0, then end loop
        LDA $0102, x
        BEQ end_div_cur_loop
        ;if (dividend >= divisor)
        IF_UNSIGNED_GT_OR_EQU param_1, param_2, div_endif
            SUB param_1, param_2
            STA param_1
            LDA $0101, x
            ORA $0102, x
            STA $0101, x
        div_endif:
        LSR $0102, x
        LSR param_2
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
    ;store remainder (param_1) in rt_val_2
    STA rt_val_2

    POP_2                               ;pop current and answer local variables

    RTS

;function to divide a 16 bit number by a specified divisor

;proc
; - divide high byte by divisor and store remainder
; - divide low byte by divisor
; - add low byte by (256 / divisor) * high byte remainder

;input -  (high_byte, low_byte, divisor)
;output - (high_byte_result, low_byte_result)

div_short:
    ;temp remainder         ($0103, x)
    LDA #$00
    PHA
    ;lbresult (low byte)    ($0102, x)
    LDA #$00
    PHA
    ;hbresult (high byte)   ($0101, x)
    LDA #$00
    PHA

    ;----------------------------------------

    STORE_PAR_3 $0106                   ;get params from stack and store them in param variables ($0103 + 3 local variables)

    ;divide low byte by divisor (param_3)
    CALL_2 div_byte, param_2, param_3
    TSX

    ;store division result in lbresult
    LDA rt_val_1
    STA $0102, x
    ;add division result by the division remainder and store in lbresult
    CLC
    ADC rt_val_2
    STA $0102, x

    ;----------------------------------------

    STORE_PAR_3 $0106                   ;get params from stack and store them in param variables ($0103 + 3 local variables)

    ;divide high byte by divisor (param_3)
    CALL_2 div_byte, param_1, param_3
    TSX

    ;store division result in hbresult
    LDA rt_val_1
    STA $0101, x

    ;store division remainder in temp remainder local variable
	LDA rt_val_2
	STA $0103, x

    ;----------------------------------------

    ;divide 128 by divisor (param_3)
    CALL_2 div_byte, #$7F, param_3
    TSX

    ;store the result in the divisor (param_3)
    LDA rt_val_1
	STA param_3
    ;double the divisor (because we divide by 128 above, not 256)
	CLC
	ADC param_3
	STA param_3

    ;store division remainder from stack into param_2
    LDA $0103, x
    STA param_2

    ;----------------------------------------

    ;formula to get high byte remainding values = (256 / divisor) * remainder
    ;multiply the division remainder of the high byte (stored in param_2) by 256 / divisor (stored in param_3)
    CALL_2 mul_byte, param_2, param_3
    TSX

    ;add lbresult by the multiplication result
    LDA $0102, x
    CLC
    ADC rt_val_1
    STA $0102, x

    ;----------------------------------------

    ;store hbresult into rt_val_1
    LDA $0101, x
    STA rt_val_1
    ;store lbresult into rt_val_2
    LDA $0102, x
    STA rt_val_2

    POP_3                            ;pop the 3 local variables from the stack

    RTS

;function that clamps an unsigned byte to min and max values
;(byte, min, max)
;example - (my_val, #$04, #$FB)
clamp:
    TSX
    LDA $0103, x
    CMP $0104, x
    BMI second_compare
    LDA $0104, x
    JMP end_compares

    second_compare:
    LDA $0103, x
    CMP $0105, x
    BPL end_compares
    LDA $0105, x

    end_compares:

    RTS
