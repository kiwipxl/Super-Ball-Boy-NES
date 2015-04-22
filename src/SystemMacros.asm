;------------------------------------------------------------------------------------;
;debug macros

;macro to apply a breakpoint if the emulator has it mapped
DEBUG_BRK .macro
    BIT $07FF                       ;read the end byte of RAM so an emulator can pick up on it
    .endm

;------------------------------------------------------------------------------------;
;stack and function macros

;macro to store 1 parameter from the stack into the param_1 variable
;used at the start of functions to load stack parameters into param variables
STORE_PAR_1 .macro
    TSX
    LDA \1, x
    STA param_1

    .endm

;macro to store 2 parameters from the stack into the param_1 and param_2 variables
;used at the start of functions to load stack parameters into param variables
STORE_PAR_2 .macro
    TSX
    LDA \1, x
    STA param_1
    LDA \1 + 1, x
    STA param_2

    .endm

;macro to store 3 parameters from the stack into the param_1, param_2 and param_3 variables
;used at the start of functions to load stack parameters into param variables
STORE_PAR_3 .macro
    TSX
    LDA \1, x
    STA param_1
    LDA \1 + 1, x
    STA param_2
    LDA \1 + 2, x
    STA param_3

    .endm

;macro to store 4 parameters from the stack into the param_1, param_2, param_3 and param_4 variables
;used at the start of functions to load stack parameters into param variables
STORE_PAR_4 .macro
    TSX
    LDA \1, x
    STA param_1
    LDA \1 + 1, x
    STA param_2
    LDA \1 + 2, x
    STA param_3
	LDA \1 + 3, x
    STA param_4
	
    .endm

;macro to store 5 parameters from the stack into the param_1, param_2, param_3, param_4 and param_5 variables
;used at the start of functions to load stack parameters into param variables
STORE_PAR_5 .macro
    TSX
    LDA \1, x
    STA param_1
    LDA \1 + 1, x
    STA param_2
    LDA \1 + 2, x
    STA param_3
    LDA \1 + 3, x
    STA param_4
    LDA \1 + 4, x
    STA param_5

    .endm

;macro to store 6 parameters from the stack into the param_1, param_2, param_3, param_4, param_5 and param_6 variables
;used at the start of functions to load stack parameters into param variables
STORE_PAR_6 .macro
    TSX
    LDA \1, x
    STA param_1
    LDA \1 + 1, x
    STA param_2
    LDA \1 + 2, x
    STA param_3
    LDA \1 + 3, x
    STA param_4
    LDA \1 + 4, x
    STA param_5
    LDA \1 + 5, x
    STA param_6

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

;macro that that stores the first return value into one address/variable
;input - (address_1)
SET_RT_VAL_1 .macro
    LDA rt_val_1
    STA \1
    .endm

;macro that stores the first and second return values into two different addresses/variables
;input - (address_1, address_2)
SET_RT_VAL_2 .macro
    LDA rt_val_1
    STA \1
    LDA rt_val_2
    STA \2
    .endm

;macro to push the specified amount of parameters to the stack, call the specified function and then pop the parameters
;from the stack
;this macro is used to call functions from within other functions
;input - (param1, [param2], [param3], [param4], [param5], [param6]) [] = optional
CALL_NESTED .macro
    .IF \?6
        LDA \6
        PHA
        STORE_PAR_5 $0103   ;temp
    .ENDIF
    .IF \?5
        LDA \5
        PHA
        STORE_PAR_4 $0103   ;temp
    .ENDIF
    .IF \?4
        LDA \4
        PHA
        STORE_PAR_3 $0103   ;temp
    .ENDIF
    .IF \?3
        LDA \3
        PHA
        STORE_PAR_2 $0103   ;temp
    .ENDIF
    .IF \?2
        LDA \2
        PHA
        STORE_PAR_1 $0103   ;temp
    .ENDIF

    JSR \1

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
;input - (param1, [param2], [param3], [param4], [param5], [param6]) [] = optional
CALL .macro
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

;macro to set a 16 bit LABel or PPU register into two separate bytes
;input - (point_address = PPU register or LABel, high_byte_store, low_byte_store)
SET_POINTER_TO_LABEL .macro
    LDA #HIGH(\1)                   ;gets the high byte of point_address
    STA \2                          ;store in high_byte_store
    LDA #LOW(\1)                    ;gets the low byte of point_address
    STA \3                          ;store in low_byte_store

    .endm

;macro to set a pointer to the specified high byte start plus the following low byte (+1)
;in memory and then store into two separate bytes
;input - (point_address = hi_byte_start, high_byte_store, low_byte_store)
SET_POINTER_HI_LO .macro
    LDA \1                          ;gets the first byte of point_address (high byte)
    STA \2                          ;store in high_byte_store
    LDA \1 + 1                      ;gets the second byte of point_address (low byte)
    STA \3                          ;store in low_byte_store

    .endm

;------------------------------------------------------------------------------------;
;if branching macros

;macro to check whether 1 value is equal to the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_EQU .macro
    ;successful if val_1 = val_2
    LDA \1
    CMP \2
    BNE \3

    .endm

;macro to check whether 1 value is not equal to the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_NOT_EQU .macro
    ;successful if val_1 != val_2
    LDA \1
    CMP \2
    BEQ \3

    .endm

;macro to check whether 1 signed value is greater than the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_SIGNED_GT .macro
    ;successful if val_1 > val_2
    LDA \1
    CMP \2
    BEQ \3              ;fail if val_1 = val_2
    BMI \3              ;fail if val_1 < val_2

    .endm

;macro to check whether 1 signed value is greater than or equal the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_SIGNED_GT_OR_EQU .macro
    ;successful if val_1 >= val_2
    LDA \1
    CMP \2
    BEQ .success\@      ;success if val_1 = val_2
    BMI \3              ;fail if val_1 <= val_2
    .success\@:

    .endm

;macro to check whether 1 unsigned value is greater than the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_UNSIGNED_GT .macro
    ;successful if val_1 > val_2
    LDA \1
    CMP \2              ;sets carry flag if val_1 >= val_2
    BEQ \3              ;fail if val_1 = val_2
    BCC \3              ;fail if no carry flag set

    .endm

;macro to check whether 1 unsigned value is greater than or equal the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_UNSIGNED_GT_OR_EQU .macro
    ;successful if val_1 >= val_2
    LDA \1
    CMP \2              ;sets carry flag if val_1 >= val_2
    BEQ .success\@      ;success if val_1 = val_2
    BCC \3              ;fail if no carry flag set
    .success\@:

    .endm

;macro to check whether 1 signed value is less than the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_SIGNED_LT .macro
    ;successful if val_1 < val_2
    LDA \1
    CMP \2
    BPL \3              ;fail if val_1 >= val_2

    .endm

;macro to check whether 1 signed value is less than or equal the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_SIGNED_LT_OR_EQU .macro
    ;successful if val_1 <= val_2
    LDA \1
    CMP \2
    BEQ .success\@      ;success if val_1 = val_2
    BPL \3              ;fail if val_1 >= val_2
    .success\@:

    .endm

;macro to check whether 1 unsigned value is less than the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_UNSIGNED_LT .macro
    ;successful if val_1 < val_2
    LDA \1
    CMP \2              ;sets carry flag if val_1 >= val_2
    BCS \3              ;fail if carry flag set

    .endm

;macro to check whether 1 unsigned value is less than or equal the other, if false, then jmp to the specified label
;input - (val_1, val_2, else_label)
IF_UNSIGNED_LT_OR_EQU .macro
    ;successful if val_1 <= val_2
    LDA \1
    CMP \2              ;sets carry flag if val_1 >= val_2
    BEQ .success\@      ;success if val_1 = val_2
    BCS \3              ;fail if carry flag set
    .success\@:

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

;------------------------------------------------------------------------------------;
;input macros

;macro that checks whether any key is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
ANY_KEY_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_ANY_KEY_BUTTON
    BEQ \1

    .endm

;macro that checks whether no key is down, if it is not, go to specified label, otherwise continue
;input - (else_label)
NO_KEY_BUTTON_DOWN .macro
    LDA button_bits
    AND INPUT_NO_KEY_BUTTON
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
