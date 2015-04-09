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
    LDA $0103, x
    STA param_1

    .endm

;macro to store 2 parameters from the stack into the param_1 and param_2 variables
;used at the start of functions to load stack parameters into param variables
STORE_PAR_2 .macro
    TSX
    LDA $0103, x
    STA param_1
    LDA $0104, x
    STA param_2

    .endm

;macro to store 3 parameters from the stack into the param_1, param_2 and param_3 variables
;used at the start of functions to load stack parameters into param variables
STORE_PAR_3 .macro
    TSX
    LDA $0103, x
    STA param_1
    LDA $0104, x
    STA param_2
    LDA $0105, x
    STA param_3

    .endm

;macro that pushes 1 parameter on the stack in reverse (because the stack moves down rather than up)
;(par1)
PUSH_PAR_1 .macro
    LDA \1
    PHA
    .endm

;macro that pushes 2 parameters on the stack in reverse (because the stack moves down rather than up)
;(par1, par2)
PUSH_PAR_2 .macro
    LDA \2
    PHA
    LDA \1
    PHA
    .endm

;macro that pushes 3 parameters on the stack in reverse (because the stack moves down rather than up)
;(par1, par2, par3)
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
;(address_1)
SET_RT_VAL_1 .macro
    LDA rt_val_1
    STA \1
    .endm

;macro that stores the first and second return values into two different addresses/variables
;(address_1, address_2)
SET_RT_VAL_2 .macro
    LDA rt_val_1
    STA \1
    LDA rt_val_2
    STA \2
    .endm

;------------------------------------------------------------------------------------;
;pointer macros

;macro to set a high byte + low byte address into two bytes or 16 bit PPU register
;(pointing_to_address, high_byte_store, low_byte_store)
SET_POINTER .macro
    LDA #HIGH(\1)                   ;gets the high byte of pointing_to_address
    STA \2                          ;store in high_byte_store
    LDA #LOW(\1)                    ;gets the low byte of pointing_to_address
    STA \3                          ;store in low_byte_store

    .endm

;------------------------------------------------------------------------------------;
;if branching macros

;macro to check whether 1 value is equal to the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
IF_EQU .macro
    ;successful if val_1 = val_2
    LDA \1
    CMP \2
    BNE \3

    .endm

;macro to check whether 1 value is not equal to the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
IF_NOT_EQU .macro
    ;successful if val_1 != val_2
    LDA \1
    CMP \2
    BEQ \3

    .endm

;macro to check whether 1 signed value is greater than the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
IF_SIGNED_GT .macro
    ;successful if val_1 > val_2
    LDA \1
    CMP \2
    BNE \3              ;fail if val_1 = val_2
    BMI \3              ;fail if val_1 <= val_2

    .endm

;macro to check whether 1 signed value is greater than or equal the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
IF_SIGNED_GT_OR_EQU .macro
    ;successful if val_1 >= val_2
    LDA \1
    CMP \2
    BEQ .success\@      ;success if val_1 = val_2
    BMI \3              ;fail if val_1 <= val_2
    .success\@:

    .endm

;macro to check whether 1 unsigned value is greater than the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
IF_UNSIGNED_GT .macro
    ;successful if val_1 > val_2
    LDA \1
    CMP \2              ;sets carry flag if val_1 >= val_2
    BNE \3              ;fail if val_1 = val_2
    BCC \3              ;fail if no carry flag set

    .endm

;macro to check whether 1 unsigned value is greater than or equal the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
IF_UNSIGNED_GT_OR_EQU .macro
    ;successful if val_1 >= val_2
    LDA \1
    CMP \2              ;sets carry flag if val_1 >= val_2
    BEQ .success\@      ;success if val_1 = val_2
    BCC \3              ;fail if no carry flag set
    .success\@:

    .endm

;macro to check whether 1 signed value is less than the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
IF_SIGNED_LT .macro
    ;successful if val_1 < val_2
    LDA \1
    CMP \2
    BPL \3              ;fail if val_1 >= val_2

    .endm

;macro to check whether 1 signed value is less than or equal the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
IF_SIGNED_LT_OR_EQU .macro
    ;successful if val_1 <= val_2
    LDA \1
    CMP \2
    BEQ .success\@      ;success if val_1 = val_2
    BPL \3              ;fail if val_1 >= val_2
    .success\@:

    .endm

;macro to check whether 1 unsigned value is less than the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
IF_UNSIGNED_LT .macro
    ;successful if val_1 < val_2
    LDA \1
    CMP \2              ;sets carry flag if val_1 >= val_2
    BCS \3              ;fail if carry flag set

    .endm

;macro to check whether 1 unsigned value is less than or equal the other, if false, then jmp to the specified label
;(val_1, val_2, else_label)
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
;(val_1, val_2)
ADD .macro
    LDA \1
    CLC
    ADC \2

    .endm

;macro to subtract val_1 by val_2 (val_1 - val_2) and store the result register a
;(val_1, val_2)
SUB .macro
    LDA \1
    SEC
    SBC \2

    .endm