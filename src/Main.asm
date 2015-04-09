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

    .include "src/SystemConstants.asm"
    .include "src/SystemMacros.asm"
    .include "src/Math.asm"
    
param_1             .rs     1
param_2             .rs     1
param_3             .rs     1
rt_val_1            .rs     1
rt_val_2            .rs     1

vblank_counter      .rs     1
button_bits         .rs     1
nt_pointer 			.rs 	2
pos_x               .rs     2
gravity             .rs     2
coord_x             .rs     1
coord_y             .rs     1

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
    IF_SIGNED_LT #$68, #$70, else
    LDY #$01
    JMP endif
    else:
    LDY #$00
    endif:

    PUSH_PAR_3 #$01, #$ff, #$81
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

    CALL_3 div_short, OAM_RAM_ADDR + 3, OAM_RAM_ADDR + 3, #$08
    SET_RT_VAL_1 coord_x

    CALL_3 div_short, OAM_RAM_ADDR, OAM_RAM_ADDR, #$08
    SET_RT_VAL_1 coord_y

    SET_POINTER LEVEL_1_MAP_0, nt_pointer + 1, nt_pointer

    LDA button_bits
    AND #%00000010
    BEQ right_not_pressed

    CALL_3 sub_short, pos_x, pos_x + 1, #$80
    SET_RT_VAL_2 pos_x, pos_x + 1

    right_not_pressed:
	
	LDA button_bits
    AND #%00000001
    BEQ left_not_pressed

    CALL_3 add_short, pos_x, pos_x + 1, #$80
    SET_RT_VAL_2 pos_x, pos_x + 1

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

    CALL_3 div_short, pos_x, pos_x + 1, #$08
    SET_RT_VAL_2 pos_x, pos_x + 1

    CALL_3 add_short, gravity, gravity + 1, #$40
    SET_RT_VAL_2 gravity, gravity + 1

    ;clamp pos_x
    CALL_3 clamp, pos_x, #$04, #$FB
    STA pos_x

    ;clamp gravity
    CALL_3 clamp, gravity, #$08, #$FB
    STA gravity

    ADD OAM_RAM_ADDR + 3, pos_x
    STA OAM_RAM_ADDR + 3

    ADD OAM_RAM_ADDR, gravity
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