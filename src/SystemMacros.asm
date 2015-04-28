;------------------------------------------------------------------------------------;
;debug macros

;macro to apply a breakpoint if the emulator has it mapped
DEBUG_BRK .macro
    BIT $07FF                       ;read the end byte of RAM so an emulator can pick up on it
    .endm

;------------------------------------------------------------------------------------;
;PPU macros

CONFIGURE_PPU .macro
    ;load PPU_CTRL and PPU_MASK config and store
    LDA PPU_CTRL_CONFIG
    STA PPU_CTRL
    LDA PPU_MASK_CONFIG
    STA PPU_MASK
    LDA PPU_STATUS

    .endm

;------------------------------------------------------------------------------------;
;stack and function macros

;macro to store parameters from the stack into the zero page param variables
;used to transfer stack values into params
;input - (stack_starting_address (usually $0103 + num local variables))
STACK_TO_PARAMS .macro
    TSX
    .IF \?9
        LDA \1 + 7, x
        STA param_8
    .ENDIF
    .IF \?8
        LDA \1 + 6, x
        STA param_7
    .ENDIF
    .IF \?7
        LDA \1 + 5, x
        STA param_6
    .ENDIF
    .IF \?6
        LDA \1 + 4, x
        STA param_5
    .ENDIF
    .IF \?5
        LDA \1 + 3, x
        STA param_4
    .ENDIF
    .IF \?4
        LDA \1 + 2, x
        STA param_3
    .ENDIF
    .IF \?3
        LDA \1 + 1, x
        STA param_2
    .ENDIF
    .IF \?2
        LDA \1, x
        STA param_1
    .ENDIF

    .endm

;macro that pops 1 value from the stack
POP_1 .macro
    PLA
    .endm

;macro that pops 2 values from the stack
POP_2 .macro
    PLA
    PLA
    .endm

;macro that moves the stack pointer up by 3 bytes in 10 cycles compared to 12
POP_3 .macro
	TSX
	INX
	INX
	INX
	TXS
    .endm

;macro that moves the stack pointer up by 4 bytes in 12 cycles compared to 16
POP_4 .macro
	TSX
	TXA
	CLC
	ADC #$04
	TAX
	TXS
    .endm

;macro that moves the stack pointer up by 5 bytes in 12 cycles compared to 20
POP_5 .macro
    TSX
    TXA
    CLC
    ADC #$05
    TAX
    TXS
    .endm

;macro that moves the stack pointer up by 6 bytes in 12 cycles compared to 24
POP_6 .macro
    TSX
    TXA
    CLC
    ADC #$06
    TAX
    TXS
    .endm

;macro that that stores return values into addresses/variables
;input - ([val_1], [val_2]) [] = optional
ST_RT_VAL_IN .macro
    .IF \?1
        LDA rt_val_1
        STA \1
    .ENDIF
    .IF \?2
        LDA rt_val_2
        STA \2
    .ENDIF

    .endm

;macro to push the specified amount of parameters to the stack, call the specified function and then pop the parameters
;from the stack
;this macro is used to call functions from within other functions
;input - ([param1], [param2], [param3], [param4], [param5], [param6]) [] = optional
CALL_NESTED .macro
    .IF \?9
        LDA \9
        PHA
        STA param_8
    .ENDIF
    .IF \?8
        LDA \8
        PHA
        STA param_7
    .ENDIF
    .IF \?7
        LDA \7
        PHA
        STA param_6
    .ENDIF
    .IF \?6
        LDA \6
        PHA
        STA param_5
    .ENDIF
    .IF \?5
        LDA \5
        PHA
        STA param_4
    .ENDIF
    .IF \?4
        LDA \4
        PHA
        STA param_3
    .ENDIF
    .IF \?3
        LDA \3
        PHA
        STA param_2
    .ENDIF
    .IF \?2
        LDA \2
        PHA
        STA param_1
    .ENDIF

    JSR \1

    .IF \?9
        PLA
    .ENDIF
    .IF \?8
        PLA
    .ENDIF
    .IF \?7
        PLA
    .ENDIF
    .IF \?6
        PLA
    .ENDIF
    .IF \?5
        PLA
    .ENDIF
    .IF \?4
        PLA
    .ENDIF
    .IF \?3
        PLA
    .ENDIF
    .IF \?2
        PLA
    .ENDIF

    .endm

;macro to store all specified parameters in zero page rather than in stack and call a specified function
;note - this macro should not be called within other functions as parameters may be overwritten, therefore
;this macro is used to call functions that are not nested
;input - ([param1], [param2], [param3], [param4], [param5], [param6]) [] = optional
CALL .macro
    .IF \?9
        LDA \9
        STA param_8
    .ENDIF
    .IF \?8
        LDA \8
        STA param_7
    .ENDIF
    .IF \?7
        LDA \7
        STA param_6
    .ENDIF
    .IF \?6
        LDA \6
        STA param_5
    .ENDIF
    .IF \?5
        LDA \5
        STA param_4
    .ENDIF
    .IF \?4
        LDA \4
        STA param_3
    .ENDIF
    .IF \?3
        LDA \3
        STA param_2
    .ENDIF
    .IF \?2
        LDA \2
        STA param_1
    .ENDIF

    JSR \1

    .endm

;------------------------------------------------------------------------------------;
;pointer macros

;macro to set a hi and lo byte address into two specified separate bytes
;input - (hi_address, lo_address, high_byte_store, low_byte_store)
SET_POINTER .macro
    LDA \1                          ;gets the first byte of point_address (high byte)
    STA \3                          ;store in high_byte_store
    LDA \2                          ;gets the second byte of point_address (low byte)
    STA \4                          ;store in low_byte_store

    .endm

;macro to set a pointer to a 16 bit address stored into two separate bytes
;input - (address, store_hi, store_lo)
SET_POINTER_TO_ADDR .macro
    LDA #HIGH(\1)                   ;gets the high byte of the specified address
    STA \2                          ;store in store_hi
    LDA #LOW(\1)                    ;gets the low byte of the specified address
    STA \3                          ;store in store_lo

    .endm

;macro to set a pointer to a specified high byte plus the following low byte (+1)
;in memory and then store into two separate bytes
;input - (point_hi, store_hi, store_lo)
SET_POINTER_TO_VAL .macro
    LDA \1                          ;gets the high byte
    STA \2                          ;store in store_hi
    LDA \1 + 1                      ;gets the low byte following the high byte in memory
    STA \3                          ;store in store_lo
    
    .endm
;------------------------------------------------------------------------------------;
;if branching macros

;macro to check whether 1 value is equal to the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_EQU .macro
    ;successful if val_1 = val_2
    LOAD_AND_COMPARE_IF \1, \2
    BNE \3

    .endm

;macro to check whether 1 value is not equal to the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_NOT_EQU .macro
    ;successful if val_1 != val_2
    LOAD_AND_COMPARE_IF \1, \2
    BEQ \3

    .endm

;macro to check whether 1 signed value is greater than the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_SIGNED_GT .macro
    ;successful if val_1 > val_2
    LOAD_AND_COMPARE_IF \1, \2
    BEQ \3              ;fail if val_1 = val_2
    BMI \3              ;fail if val_1 < val_2

    .endm

;macro to check whether 1 signed value is greater than or equal the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_SIGNED_GT_OR_EQU .macro
    ;successful if val_1 >= val_2
    LOAD_AND_COMPARE_IF \1, \2
    BEQ .success\@      ;success if val_1 = val_2
    BMI \3              ;fail if val_1 <= val_2
    .success\@:

    .endm

;macro to check whether 1 unsigned value is greater than the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_UNSIGNED_GT .macro
    ;successful if val_1 > val_2
    LOAD_AND_COMPARE_IF \1, \2
    BEQ \3              ;fail if val_1 = val_2
    BCC \3              ;fail if no carry flag set

    .endm

;macro to check whether 1 unsigned value is greater than or equal the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_UNSIGNED_GT_OR_EQU .macro
    ;successful if val_1 >= val_2
    LOAD_AND_COMPARE_IF \1, \2
    BEQ .success\@      ;success if val_1 = val_2
    BCC \3              ;fail if no carry flag set
    .success\@:

    .endm

;macro to check whether 1 signed value is less than the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_SIGNED_LT .macro
    ;successful if val_1 < val_2
    LOAD_AND_COMPARE_IF \1, \2
    BPL \3              ;fail if val_1 >= val_2

    .endm

;macro to check whether 1 signed value is less than or equal the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_SIGNED_LT_OR_EQU .macro
    ;successful if val_1 <= val_2
    LOAD_AND_COMPARE_IF \1, \2
    BEQ .success\@      ;success if val_1 = val_2
    BPL \3              ;fail if val_1 >= val_2
    .success\@:

    .endm

;macro to check whether 1 unsigned value is less than the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_UNSIGNED_LT .macro
    ;successful if val_1 < val_2
    LOAD_AND_COMPARE_IF \1, \2
    CMP \2              ;sets carry flag if val_1 >= val_2
    BCS \3              ;fail if carry flag set

    .endm

;macro to check whether 1 unsigned value is less than or equal the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_UNSIGNED_LT_OR_EQU .macro
    ;successful if val_1 <= val_2
    LOAD_AND_COMPARE_IF \1, \2
    BEQ .success\@      ;success if val_1 = val_2
    BCS \3              ;fail if carry flag set
    .success\@:

    .endm

LOAD_AND_COMPARE_IF .macro
    .IF \?1 = 6
        .IF \1 = reg_x
            TXA
        .ENDIF
        .IF \1 = reg_y
            TYA
        .ENDIF

        .IF \1 != reg_x
            .IF \1 != reg_y
                LDA \1
            .ENDIF
        .ENDIF
    .ELSE
        LDA \1
    .ENDIF

    .IF \?2 = 6
        .IF \2 = reg_a
            CMP a
        .ENDIF
        .IF \2 = reg_x
            CMP x
        .ENDIF
        .IF \2 = reg_y
            CMP y
        .ENDIF

        .IF \2 != reg_a
            .IF \2 != reg_x
                .IF \2 != reg_y
                    CMP \2
                .ENDIF
            .ENDIF
        .ENDIF
    .ELSE
        CMP \2
    .ENDIF

    .endm

;------------------------------------------------------------------------------------;
;math macros

;macro to add val_1 by val_2 (val_1 + val_2) and store the result register a
;input - (val_1, val_2)
ADD .macro
    LDA \1
    CLC
    ADC \2

    .endm

;macro to subtract val_1 by val_2 (val_1 - val_2) and store the result register a
;input - (val_1, val_2)
SUB .macro
    LDA \1
    SEC
    SBC \2

    .endm

;macro to shift a specified value to the right by 3 (or divide by 8) as well as adding and/or
;subtracting an offset before shifting
;input - (val_to_shift, [add_offset], [sub_offset], [store_result_in]) [] = optional
DIV8 .macro
    LDA \1
    .IF \?2
        .IF \2 != 0
            CLC
            ADC \2
        .ENDIF
    .ENDIF
    .IF \?3
        .IF \3 != 0
            SEC
            SBC \3
        .ENDIF
    .ENDIF
    LSR a
    LSR a
    LSR a
    .IF \?4
        STA \4
    .ENDIF

    .endm

;macro to shift a specified value to the left by 3 (or multiply by 8) as well as adding and/or
;subtracting an offset before shifting
;input - (val_to_shift, [add_offset], [sub_offset], [store_result_in]) [] = optional
MUL8 .macro
    LDA \1
    .IF \?2
        .IF \2 != 0
            CLC
            ADC \2
        .ENDIF
    .ENDIF
    .IF \?3
        .IF \3 != 0
            SEC
            SBC \3
        .ENDIF
    .ENDIF
    ASL a
    ASL a
    ASL a
    .IF \?4
        STA \4
    .ENDIF

    .endm

;------------------------------------------------------------------------------------;
;input macros

;macro that checks whether any key is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
ANY_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_ANY_BUTTON
    BEQ \1

    .endm

;macro that checks whether no key is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
NO_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_NO_BUTTON
    BNE \1

    .endm

;macro that checks whether a is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
A_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_A_BUTTON
    BEQ \1

    .endm

;macro that checks whether b is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
B_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_B_BUTTON
    BEQ \1

    .endm

;macro that checks whether select is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
SELECT_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_SELECT_BUTTON
    BEQ \1

    .endm

;macro that checks whether start is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
START_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_START_BUTTON
    BEQ \1

    .endm

;macro that checks whether up is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
UP_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_UP_BUTTON
    BEQ \1

    .endm

;macro that checks whether down is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
DOWN_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_DOWN_BUTTON
    BEQ \1

    .endm

;macro that checks whether left is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
LEFT_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_LEFT_BUTTON
    BEQ \1

    .endm
    
;macro that checks whether right is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
RIGHT_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_RIGHT_BUTTON
    BEQ \1

    .endm
