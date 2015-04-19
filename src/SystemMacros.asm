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

;macro that pushes 1 parameter on the stack in reverse (because the stack moves down rather than up)
;input - (par1)
PUSH_PAR_1 .macro
    LDA \1
    PHA
    .endm

;macro that pushes 2 parameters on the stack in reverse (because the stack moves down rather than up)
;input - (par1, par2)
PUSH_PAR_2 .macro
    LDA \2
    PHA
    LDA \1
    PHA
    .endm

;macro that pushes 3 parameters on the stack in reverse (because the stack moves down rather than up)
;input - (par1, par2, par3)
PUSH_PAR_3 .macro
    LDA \3
    PHA
    LDA \2
    PHA
    LDA \1
    PHA
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

;macro that pops 3 values from the stack
POP_3 .macro
    PLA
    PLA
    PLA
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

;macro to push 1 parameter, call the specified function and then pop the parameter
CALL_1 .macro
    PUSH_PAR_1 \2
    JSR \1
    POP_1

    .endm

;macro to push 2 parameters, call the specified function and then pop the parameters
CALL_2 .macro
    PUSH_PAR_2 \2, \3
    JSR \1
    POP_2

    .endm

;macro to push 3 parameters, call the specified function and then pop the parameters
CALL_3 .macro
    PUSH_PAR_3 \2, \3, \4
    JSR \1
    POP_3

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
    BMI \3              ;fail if val_1 <= val_2

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
