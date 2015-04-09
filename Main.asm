    .inesprg 1   ;1 16kb PRG code
    .ineschr 1   ;1 8kb CHR data
    .inesmap 0   ;mapper 0 = NROM, no bank swapping
    .inesmir 1   ;background mirroring

;------------------------------------------------------------------------------------;

    .bank 3                           ;uses the fourth bank, which is a 8kb ROM memory region
    .org $8000                        ;places graphics tiles at the beginning of ROM (8000 - a000, offset: 0kb)
    .incbin "assets/tileset1.chr"     ;includes 8kb graphics file from SMB1

;------------------------------------------------------------------------------------;

    .bank 2                           ;uses the third bank, which is a 8kb ROM memory region
    .org $a000                        ;places graphics tiles in the first quarter of ROM (a000 - e000, offset: 8kb)
    .incbin "assets/tileset1.chr"     ;includes 8kb graphics file from SMB1

;------------------------------------------------------------------------------------;

    .bank 1                           ;uses the second bank, which is a 8kb ROM memory region
	
    .org $fffa                        ;places the address of NMI, reset and BRK handlers at the very end of the ROM
    .dw NMI                           ;address for NMI (non maskable interrupt). when an NMI happens (once per frame if enabled) the 
                                      ;processor will jump to the label NMI and return to the point where it was interrupted
    .dw RESET                         ;when the processor first turns on or is reset, it will jump to the RESET label
    .dw IQR                           ;external interrupts are not used

    .org $e000                        ;place all program code at the third quarter of ROM (e000 - fffa, offset: 24kb)

LEVEL_1_MAP_0:
    .incbin "assets/level-1/map0.nam"
LEVEL_1_MAP_1:
    .incbin "assets/level-1/map1.nam"
LEVEL_1_MAP_2:
    .incbin "assets/level-1/map2.nam"

PALETTE:
	.incbin "assets/level-palette.pal"
    .incbin "assets/sprite-palette.pal"

SPRITES:
    ;y, tile index, attribs (palette 4 to 7, priority, flip), x
    .db $80, $07, %00000000, $80

NUM_SPRITES         = 4
SPRITES_DATA_LEN    = 16

    ;store game variables in zero page (2x faster access)
    .rsset $0000

param_1             .rs     1
param_2             .rs     1
param_3             .rs     1
rt_val_1            .rs     1
rt_val_2            .rs     1
temp                .rs     2
temp_2 				.rs 	2
dividend            .rs     2
divisor             .rs     1
current             .rs     2
answer              .rs     1

vblank_counter      .rs     1
button_bits         .rs     1
nt_pointer 			.rs 	2
pos_x               .rs     2
gravity             .rs     2
coord_x             .rs     1
coord_y             .rs     1

    .include "SystemConstants.asm"
    .include "SystemMacros.asm"

;------------------------------------------------------------------------------------;
;map loading macros

;macro to load a nametable + attributes into specified PPU addressess
;(nametable_address (including attributes), PPU_nametable_address)
LOAD_MAP .macro
    BIT PPU_STATUS                  ;read PPU_STATUS to reset high/low latch so low byte can be stored then high byte (little endian)
    SET_POINTER \2, PPU_ADDR, PPU_ADDR
    SET_POINTER \1, nt_pointer + 1, nt_pointer
    JSR load_nametable

    .endm

;------------------------------------------------------------------------------------;

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
    STORE_PAR_2

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
	
div_byte:
    STORE_PAR_2
	
    LDA #$01
    STA current ;current
    LDA #$00
    STA answer ;answer

    LDA param_2
    BEQ end_div
    CMP param_1
    ;if (divisor == dividend)
    BNE div_equ
    LDA #$01
    STA answer
    JMP end_div
    div_equ:
    ;if (divisor > dividend)
    BPL end_div

    ;while (divisor <= dividend)
    div_shift_loop:
        LDA param_2
        CMP param_1
        BPL end_div_shift_loop
        ROL param_2
        ROL current
        JMP div_shift_loop
    end_div_shift_loop:

    ;while (current != 0)
    div_cur_loop:
        LDA current
        BEQ end_div_cur_loop
        ;if (dividend >= divisor)
            LDA param_1
            CMP param_2
            BEQ skip_g_than_cmp
            BMI div_endif
            skip_g_than_cmp:
            LDA param_1
            SEC
            SBC param_2
            STA param_1
            LDA answer
            ORA current
            STA answer
        div_endif:
        LSR current
        LSR param_2
        JMP div_cur_loop
    end_div_cur_loop:

    end_div:
    IF_NOT_EQU param_1, param_3, rdnequ
    LDA #$00
    rdnequ:

    STA rt_val_1
    LDA answer
    STA rt_val_2

    RTS

;temp macro to divide two bytes (16 bit) by continuously subtracting or adding
;(high_byte, low_byte, value)
div_short:
    STORE_PAR_3

    LDA param_2
    PUSH_PAR_2 param_2, param_3
    JSR div_byte
    LDA rt_val_2
    STA temp
    CLC
    ADC rt_val_1
    STA temp
    POP_2

    STORE_PAR_3

    LDA param_1
    PUSH_PAR_2 param_1, param_3
    JSR div_byte
    LDA rt_val_2
    STA temp + 1
    POP_2

	LDY #$04
	LDA rt_val_1
	STA temp_2
	LDA temp_2

    ;todo: high byte is rounded off so have to calculate remaining values here
	;divisor = 4
	;256 / divisor = 64
	;4 / 4 = 0 remainder
	;remainder * 64 = 0
	;5 / 4 = 1 remainder
	;remainder * 64 = 64
	;6 / 4 = 2 remainder
	;remainder * 64 = 128
	;formula = remainder * (256 / divisor)
	;needs to be 188
	PUSH_PAR_2 #$7F, param_3
    JSR div_byte

    ;may have to subtract remainder
    LDA rt_val_2
	STA param_1
	;double
	CLC
	ADC param_1
	STA param_1
    POP_2
	LDA param_1
	LDA temp_2

	;store 256 / divisor (param_3) in param_1
    PUSH_PAR_2 temp_2, param_1
    JSR mul_byte
    LDA temp
    CLC
    ADC rt_val_1
    STA temp
    POP_2
	
    DEBUG_BRK
    LDY #$08
    LDA temp + 1
    STA rt_val_1
    LDA temp
    STA rt_val_2

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

;------------------------------------------------------------------------------------;

    .bank 0                         ;uses the first bank, which is a 8kb ROM memory region
    .org $c000                      ;place all program code in the middle of PGR_ROM memory (c000 - e000, offset: 16kb)

;wait for vertical blank to make sure the PPU is ready
vblank_wait:
    BIT PPU_STATUS                  ;reads PPU_STATUS and sets the negative flag if bit 7 is 1 (vblank)
    BPL vblank_wait                 ;continue waiting until the negative flag is not set which means bit 7 is positive (equal to 1)
    RTS

;RESET is called when the NES starts up
RESET:
    SEI                             ;disables external interrupt requests
    CLD                             ;the NES does not use decimal mode, so disable it
    LDX #$40
    STX $4017                       ;disables APU frame counter IRQ by writing 64 to the APU register (todo: better understanding)

    LDX #$FF
    TXS                             ;set the stack pointer to point to the end of the stack #$FF (e.g. $01FF)

    INX                             ;add 1 to the x register and overflow it which results in 0
    STX $4010                       ;disable DMC IRQ (APU memory access and interrupts) by writing 0 to the APU DMC register

    DEBUG_BRK
    IF_UNSIGNED_GT_OR_EQU #$ae, #$af, success
    LDY #$00
    JMP endif
    success:
    LDY #$01
    endif:

    LDA #$14
    STA $0022
    LDA #$5f
    STA $0023
    LDA #$03
    STA $0024
    PUSH_PAR_3 $0022, $0023, $0024
    JSR div_short
    DEBUG_BRK
    LDA rt_val_1
    LDA rt_val_2
    POP_3

    JSR vblank_wait                 ;first vblank wait to make sure the PPU is warming up

;------------------------------------------------------------------------------------;
;wait for the PPU to be ready and clear all mem from 0000 to 0800

;while waiting to make sure the PPU has properly stabalised, we will put the 
;zero page, stack memory and RAM into a known state by filling it with #$00
clr_mem_loop:
    LDA #$00
    STA $0000, x                    ;set the zero page to 0
    STA $0100, x                    ;set the stack memory to 0
    STA $0200, x                    ;set RAM to 0
    STA $0300, x                    ;set RAM to 0
    STA $0400, x                    ;set RAM to 0
    STA $0500, x                    ;set RAM to 0
    STA $0600, x                    ;set RAM to 0
    STA $0700, x                    ;set RAM to 0

    LDA #$FF
    STA OAM_RAM_ADDR, x             ;set OAM (object attribute memory) in RAM to #$FF so that sprites are off-screen

    INX                             ;increase x by 1
    CPX #$00                        ;check if x has overflowed into 0
    BNE clr_mem_loop                ;continue clearing memory if x is not equal to 0

    JSR vblank_wait                 ;second vblank wait to make sure the PPU has properly warmed up

;------------------------------------------------------------------------------------;

;> writes bg and sprite palette data to the PPU
;write the PPU bg palette address VRAM_BG_PLT to the PPU register PPU_ADDR
;so whenever we write data to PPU_DATA, it will map to VRAM_BG_PLT + write offset in the PPU VRAM
;although we start at the BG palette, we also continue writing into the sprite palette
load_palettes:
    BIT PPU_STATUS                  ;read PPU_STATUS to reset high/low latch so low byte can be stored then high byte (little endian)
    SET_POINTER VRAM_BG_PLT, PPU_ADDR, PPU_ADDR

    LDX #$00                        ;set x counter register to 0
    load_palettes_loop:
        LDA PALETTE, x              ;load palette byte (palette + x byte offset)
        STA PPU_DATA                ;write byte to the PPU palette address
        INX                         ;add by 1 to move to next byte

        CPX #$20                    ;check if x is equal to 32
        BNE load_palettes_loop      ;keep looping if x is not equal to 32, otherwise continue

load_level_1:
    LOAD_MAP LEVEL_1_MAP_0, VRAM_NT_0
    LOAD_MAP LEVEL_1_MAP_1, VRAM_NT_1

    JMP init_PPU

;> writes nametable 0 into PPU VRAM
;write the PPU nametable address VRAM_NT_0 to the PPU register PPU_ADDR
;so whenever we write data to PPU_DATA, it will map to the VRAM_NT_0 + write offset address in the PPU VRAM
load_nametable:
	LDY #$00
	LDX #$00
	nt_loop:
		nt_loop_nested:
			LDA [nt_pointer], y 		;get the value pointed to by nt_pointer_lo + nt_pointer_hi + y counter offset
			STA PPU_DATA                ;write byte to the PPU nametable address
			INY                       	;add by 1 to move to the next byte
			
			CPY #$00                    ;check if y is equal to 0 (it has overflowed)
			BNE nt_loop_nested    		;keep looping if y not equal to 0, otherwise continue

            INC nt_pointer + 1          ;increase the high byte of nt_pointer by 1 ((#$FF + 1) low bytes)
			INX 						;increase x by 1
			
			CPX #$04 					;check if x has looped and overflowed 4 times (1kb, #$04FF)
			BNE nt_loop 				;go to the start of the loop if x is not equal to 0, otherwise continue
    RTS

;------------------------------------------------------------------------------------;

;initialises PPU settings
init_PPU:
    ;setup PPU_CTRL bits
    LDA #%10000000                  ;enable NMI calling and set sprite pattern table to $0000 (0)
    STA PPU_CTRL

    ;setup PPU_MASK bits
    LDA #%00011110                  ;enable sprite rendering
    STA PPU_MASK

    LDA #$00
    STA pos_x
    STA pos_x + 1
    STA gravity

;loads all sprite attribs into OAM_RAM_ADDR
load_sprites:
    LDX #$00                        ;start x register counter at 0
	
    load_sprites_loop:
        LDA SPRITES, x              ;load sprite attrib into register a (sprite + x)
        STA OAM_RAM_ADDR, x         ;store attrib in OAM on RAM(address + x)
        INX

        CPX #SPRITES_DATA_LEN       ;check if all attribs have been stored by comparing x to the data length of all sprites
        BNE load_sprites_loop       ;continue loop if x register is not equal to 0, otherwise move down

        JMP game_loop

;------------------------------------------------------------------------------------;

game_loop:
    ;keep looping until NMI is called and changes the vblank counter
    LDA vblank_counter             ;load the vblank counter
    vblank_wait_main:
        CMP vblank_counter         ;compare register a with the vblank counter
        BEQ vblank_wait_main       ;keep looping if they are equal, otherwise continue if the vblank counter has changed

    DEBUG_BRK
    PUSH_PAR_3 OAM_RAM_ADDR + 3, OAM_RAM_ADDR + 3, #$08
    JSR div_short
    SET_RT_VAL_1 coord_x
    POP_3

    PUSH_PAR_3 OAM_RAM_ADDR, OAM_RAM_ADDR, #$08
    JSR div_short
    SET_RT_VAL_1 coord_y
    POP_3

    SET_POINTER LEVEL_1_MAP_0, nt_pointer + 1, nt_pointer
    LDY coord_y
    mul:
        CPY #$00
        BEQ end_mul
        INC nt_pointer + 1
        DEY
        JMP mul
    end_mul:

    LDA nt_pointer
    CLC
    ADC coord_x
    STA nt_pointer

    LDA nt_pointer + 1
    LDA nt_pointer
    LDA coord_x
    LDA coord_y

    LDA button_bits
    AND #%00000010
    BEQ right_not_pressed

    PUSH_PAR_3 pos_x, pos_x + 1, #$80
    JSR sub_short
    SET_RT_VAL_2 pos_x, pos_x + 1
    POP_3

    right_not_pressed:
	
	LDA button_bits
    AND #%00000001
    BEQ left_not_pressed

    PUSH_PAR_3 pos_x, pos_x + 1, #$80
    JSR add_short
    SET_RT_VAL_2 pos_x, pos_x + 1
    POP_3

    left_not_pressed:

    LDA button_bits
    AND #%00000100
    BEQ down_not_pressed
    down_not_pressed:

    LDA button_bits
    AND #%00001000
    BEQ up_not_pressed

    LDA #$FC
    STA gravity
    LDA #$00
    STA gravity + 1

    up_not_pressed:

    PUSH_PAR_3 pos_x, pos_x + 1, #$08
    JSR div_short
    SET_RT_VAL_2 pos_x, pos_x + 1
    POP_3

    PUSH_PAR_3 gravity, gravity + 1, #$40
    JSR add_short
    SET_RT_VAL_2 gravity, gravity + 1
    POP_3

    ;clamp pos_x
    PUSH_PAR_3 pos_x, #$04, #$FB
    JSR clamp
    STA pos_x
    POP_3

    ;clamp gravity
    PUSH_PAR_3 gravity, #$08, #$FB
    JSR clamp
    STA gravity
    POP_3

    LDA OAM_RAM_ADDR + 3
    CLC
    ADC pos_x
    STA OAM_RAM_ADDR + 3

    LDA OAM_RAM_ADDR
    CLC
    ADC gravity
    STA OAM_RAM_ADDR

    JMP game_loop                   ;jump back to game_loop, infinite loop

;------------------------------------------------------------------------------------;

read_controller:
    ;write $0100 to $4016 to tell the controllers to latch the current button positions (???)
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016

    ;read the button press bit of a, b, start, select, up, down, left, right and store all bits in button_bits
    LDX #$08
    read_loop:
        LDA $4016                   ;load input status byte into register a
        LSR a                       ;shift right by 1 and store what was bit 0 into the carry flag
        ROL button_bits             ;rotate left by 1 and store the previous carry flag in bit 0
        DEX                         ;decreases x by 1 and sets the zero flag if x is 0
        BNE read_loop               ;if the zero flag is not set, keep looping, otherwise end the function
        RTS

;NMI interrupts the cpu and is called once per video frame
;PPU is starting vblank time and is available for graphics updates
NMI:
    ;copies 256 bytes of OAM data in RAM (OAM_RAM_ADDR - OAM_RAM_ADDR + $FF) to the PPU internal OAM
    ;this takes 513 cpu clock cycles and the cpu is temporarily suspended during the transfer

    LDA #$00
    STA OAM_ADDR                   ;sets the low byte of OAM_ADDR to #$00 (the start of internal OAM memory on PPU)

    ;stores the #$02 high byte + #$00 sprite attribs memory address in OAM_DMA and then begins the transfer
    LDA #HIGH(OAM_RAM_ADDR)
    STA OAM_DMA                    ;stores OAM_RAM_ADDR to high byte of OAM_DMA
    ;CPU is now suspended and transfer begins

    ;BIT PPU_STATUS
    ;INC $0302
    ;LDA $0302
    ;STA $2005

    ;INC $0304
    ;LDA $0304
    ;STA $2005

    LDA #$00
    STA $2005
    STA $2005

    INC vblank_counter              ;increases the vblank counter by 1 so the game loop can check when NMI has been called

    JSR read_controller

input_end:
    RTI                             ;returns from the interrupt

IQR:
    RTI