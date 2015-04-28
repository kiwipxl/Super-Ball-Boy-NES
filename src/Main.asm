    .inesprg 1   ;1 16kb PRG code
    .ineschr 1   ;1 8kb CHR data
    .inesmap 0   ;mapper 0 = NROM, no bank swapping
    .inesmir 1   ;background mirroring

;------------------------------------------------------------------------------------;

    .bank 3                           ;uses the fourth bank, which is a 8kb ROM memory region
    .org $8000                        ;places graphics tiles at the beginning of ROM (8000 - a000, offset: 0kb)
	
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

CHAMBER_1:
    CHAMBER_1_ROOM_0:
    	.incbin "assets/level-1/chamber1_room1.nam"
    CHAMBER_1_ROOM_1:
    	.incbin "assets/level-1/chamber1_room2.nam"

TITLE_SCREEN_NT:
    .incbin "assets/titlescreen.nam"

PALETTE:
	.incbin "assets/level-palette.pal"
	.incbin "assets/sprite-palette.pal"

;------------------------------------------------------------------------------------;

	;store function params, return values and temporary values in the first 16 bytes of zero page
    .rsset $0000
	
;local params used to store inputs from functions - note that these params may be modified when a function with a input is called
param_1                 .rs     1
param_2                 .rs     1
param_3                 .rs     1
param_4                 .rs     1
param_5                 .rs     1
param_6                 .rs     1
param_7                 .rs     1
param_8                 .rs     1

;return values used for functions that have an output / multiple outputs
rt_val_1                .rs     1
rt_val_2                .rs     1
rt_val_3                .rs     1
rt_val_4                .rs     1

;temporary value that can be modified at any time
temp                    .rs     6

;------------------------------------------------------------------------------------;

	;store game variables in zero page with a 18 byte offset
	.rsset $0012

;PPU variables
vblank_counter      	.rs     1

;input variables
button_bits         	.rs     1

;random variables
rand_seed               .rs     1

;player movement variables
pos_x               	.rs     1
pos_y               	.rs     1
speed_x             	.rs     2
gravity             	.rs     2

;player collision variables
leftc_pointer           .rs     2
rightc_pointer          .rs     2
downc_pointer           .rs     2
upc_pointer             .rs     2
coord_x             	.rs     3
coord_y             	.rs     3
c_coord_x               .rs     1
c_coord_y               .rs     1
on_floor                .rs     1

;chamber scroll variables
scroll_x            	.rs     1
scroll_y            	.rs     1
scroll_x_type       	.rs     1

;nametable row loading
nt_pointer              .rs     2
VRAM_pointer            .rs     2
row_index               .rs     2
NT_MAX_LOAD_TILES       .db     $20
nt_row_x                .rs     1
nt_row_y                .rs     1

;room variables
current_room            .rs     2
current_VRAM_addr      	.rs     2
room_1                  .rs     2
VRAM_room_addr_1	   	.rs     2
room_2                  .rs     2
VRAM_room_addr_2       	.rs     2
room_load_id 			.rs 	1

;respawn variables
player_spawn            .rs     2
respawn_room            .rs     2
respawn_VRAM_addr       .rs     2
respawn_scroll_x_type 	.rs 	1

;animation pointer variables
ani_frames 				.rs 	16      ;stores hi + lo byte pointers to pre-built animation frames, 2 bytes per animation
ani_VRAM_pointer 		.rs 	16      ;stores hi + lo byte pointers to a nametable which tile animations will use, 2 bytes per animation

;enemy pointer variables
enemy_room              .rs     16      ;stores hi + lo byte pointers to the room in ROM where the enemy is, 2 bytes per enemy
enemy_VRAM_addr 	 	.rs 	16      ;stores hi + lo byte pointers to the VRAM nametable address where the enemy is, 2 bytes per enemy

;------------------------------------------------------------------------------------;

    ;the following variables are stored in main RAM and not zero page (256 byte offset)
	.rsset $0100

;animation struct variables
ani_rate 				.rs     8 	    ;frame rate byte that defines how often the animation will run per frame, 1 byte per animation
ani_frame_counter 		.rs 	8 	    ;frame counter that increases every frame, 1 byte per animation
ani_current_frame 		.rs 	8 	    ;byte that defines the current frame of the animation, 1 byte per animation
ani_loop 				.rs 	8 	    ;defines whether the animation will loop or not, 1 byte per animation
ani_num_frames 			.rs 	8 	    ;the amount of frames in the current animation, 1 byte per animation
ani_active              .rs     8       ;defines whether the animation is currently playing or not, 1 byte per animation
ani_max                 .db     $08

;------------------------------------------------------------------------------------;

;enemy struct variables
enemy_type              .rs     8       ;defines the type of the enemy, 1 byte per enemy
                                        ;0 = slime, 1 = bat
enemy_pos_x             .rs     16      ;defines the pos_x of the enemy, 2 bytes per enemy
enemy_pos_y             .rs     16      ;defines the pos_y of the enemy, 2 bytes per enemy
enemy_speed_x           .rs     16      ;defines the speed_x of the enemy, 2 bytes per enemy
enemy_gravity           .rs     16      ;defines the gravity of the enemy, 2 bytes per enemy
enemy_active            .rs     8       ;whether the enemy has been created or not (0 = false, 1 = true), 2 bytes per enemy
enemy_temp_1            .rs     8       ;temp1 variable used to save memory on enemy logic variables, 1 byte per enemy
                                        ;slime = waiting to jump counter
                                        ;bat = not used
enemy_temp_2            .rs     8       ;temp2 variable used to save memory on enemy logic variables, 1 byte per enemy
                                        ;slime = jump rate value
                                        ;bat = not used
enemy_temp_3            .rs     8       ;temp3 variable used to save memory on enemy logic variables, 1 byte per enemy
                                        ;slime = used as a timer when jumping is activated to allow slimes to readjust
                                        ;bat = not used
enemy_temp_4            .rs     8       ;temp4 variable used to save memory on enemy logic variables, 1 byte per enemy
                                        ;slime = not used
                                        ;bat = not used
enemy_len               .rs     1       ;the amount of currently running enemies
enemy_max               .db     $08

reg_a                   .db     $00
reg_x                   .db     $00
reg_y                   .db     $00
temp_cmp                .rs     1

;------------------------------------------------------------------------------------;

current_state           .rs     1       ;the current state of the game
next_state              .rs     1       ;used to store the next state while nametables are loading

TITLE_SCREEN_STATE          .db     $01
GAME_STATE                  .db     $02
WIN_STATE                   .db     $03
HALT_STATE                  .db     $04
NT_LOADING_STATE            .db     $05
NT_CHAMBER_LOADING_STATE    .db     $06

;------------------------------------------------------------------------------------;

SPRING_ANI:
    ;number of frames
	.db $0B
    ;tile index frame animation
	.db $0A, $1A, $2A, $3A, $3A, $3A, $3A, $3A, $2A, $1A, $0A

;------------------------------------------------------------------------------------;

PPU_CTRL_CONFIG         .db     %10000000     ;enable NMI calling and set sprite pattern table to $0000 (0)

PPU_MASK_CONFIG         .db     %00011110     ;enable sprite rendering

;------------------------------------------------------------------------------------;

	.include "src/SystemConstants.asm"
    .include "src/SystemMacros.asm"
    .include "src/Math.asm"
    .include "src/Map.asm"
	.include "src/Animation.asm"
    .include "src/Enemy.asm"
    .include "src/Player.asm"
    .include "src/State.asm"

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

    CALL vblank_wait                 ;first vblank wait to make sure the PPU is warming up

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

    CALL vblank_wait                 ;second vblank wait to make sure the PPU has properly warmed up

;------------------------------------------------------------------------------------;

;> writes bg and sprite palette data to the PPU
;write the PPU bg palette address VRAM_BG_PLT to the PPU register PPU_ADDR
;so whenever we write data to PPU_DATA, it will map to VRAM_BG_PLT + write offset in the PPU VRAM
;although we start at the BG palette, we also continue writing into the sprite palette
load_palettes:
    BIT PPU_STATUS                  ;read PPU_STATUS to reset high/low latch so low byte can be stored then high byte (little endian)
    SET_POINTER_TO_ADDR VRAM_BG_PLT, PPU_ADDR, PPU_ADDR

    LDX #$00                        ;set x counter register to 0
    load_palettes_loop:
        LDA PALETTE, x              ;load palette byte (palette + x byte offset)
        STA PPU_DATA                ;write byte to the PPU palette address
        INX                         ;add by 1 to move to next byte

        CPX #$20                    ;check if x is equal to 32
        BNE load_palettes_loop      ;keep looping if x is not equal to 32, otherwise continue

init:
    CALL change_state, TITLE_SCREEN_STATE

;------------------------------------------------------------------------------------;

game_loop:
    ;keep looping until NMI is called and changes the vblank counter
    LDA vblank_counter             ;load the vblank counter
    vblank_wait_main:
        CMP vblank_counter         ;compare register a with the vblank counter
        BEQ vblank_wait_main       ;keep looping if they are equal, otherwise continue if the vblank counter has changed

    CALL read_controller
    CALL update_state

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
    ;push a, x and y onto the stack to save previous registers
    PHA
    TXA
    PHA
    TYA
    PHA

    IF_NOT_EQU current_state, NT_LOADING_STATE, nminlnt_
        ;copies 256 bytes of OAM data in RAM (OAM_RAM_ADDR - OAM_RAM_ADDR + $FF) to the PPU internal OAM
        ;this takes 513 cpu clock cycles and the cpu is temporarily suspended during the transfer

        LDA #$00
        STA OAM_ADDR                   ;sets the low byte of OAM_ADDR to #$00 (the start of internal OAM memory on PPU)

        ;stores the #$02 high byte + #$00 sprite attribs memory address in OAM_DMA and then begins the transfer
        LDA #HIGH(OAM_RAM_ADDR)
        STA OAM_DMA                    ;stores OAM_RAM_ADDR to high byte of OAM_DMA
        ;CPU is now suspended and transfer begins
    nminlnt_:

    CALL update_render_state

    LDA scroll_x
    STA $2005
    LDA scroll_y
    STA $2005

    INC vblank_counter              ;increases the vblank counter by 1 so the game loop can check when NMI has been called

    ;pull a, x, y from the stack and put them back in their respective registers
    PLA
    TAY
    PLA
    TAX
    PLA

    RTI                             ;returns from the interrupt

IQR:
    RTI                             ;returns from the interrupt