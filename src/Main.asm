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

LEVEL_1_MAP_0:
	.incbin "assets/level-1/chamber1_room1.nam"
LEVEL_1_MAP_1:
	.incbin "assets/level-1/chamber1_room2.nam"

PALETTE:
	.incbin "assets/level-palette.pal"
	.incbin "assets/sprite-palette.pal"

SPRITES:
	;y, tile index, attribs (palette 4 to 7, priority, flip), x
	.db $2a, $07, %00000000, $80

NUM_SPRITES         = 1
SPRITES_DATA_LEN    = NUM_SPRITES * 4

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

	;store game variables in zero page with a 16 byte offset
	.rsset $0010
	
vblank_counter      	.rs     1
button_bits         	.rs     1
nt_pointer          	.rs     2
leftc_pointer       	.rs     2
rightc_pointer      	.rs     2
downc_pointer       	.rs     2
upc_pointer         	.rs     2
pos_x               	.rs     1
pos_y               	.rs     1
speed_x             	.rs     2
gravity             	.rs     2
coord_x             	.rs     3
coord_y             	.rs     3
c_coord_x               .rs     1
c_coord_y               .rs     1
current_tile        	.rs     1
scroll_x            	.rs     1
scroll_y            	.rs     1
current_room        	.rs     2
current_VRAM            .rs     2
scroll_x_type       	.rs     1
player_spawn        	.rs     2

ani_frames 				.rs 	16      ;store hi + lo byte pointer to pre-built animation, 2 bytes per animation
ani_VRAM_pointer 		.rs 	16      ;stores hi + lo byte pointers to a nametable which tile animations will use, 2 bytes per animation

	;store animation array with a 256 byte offset with a max amount of 8 running animations
	.rsset $0100
	
ani_rate 				.rs     8 	     ;frame rate byte that defines how often the animation will run per frame, 1 byte per animatio
ani_frame_counter 		.rs 	8 	     ;frame counter that increases every frame, 1 byte per animation
ani_current_frame 		.rs 	8 	     ;byte that defines the current frame of the animation, 1 byte per animation
ani_loop 				.rs 	8 	     ;defines whether the animation will loop or not, 1 byte per animation
ani_num_frames 			.rs 	8 	     ;the amount of frames in the current animation, 1 byte per animation
ani_active              .rs     8        ;defines whether the animation is currently playing or not, 1 byte per animation
ani_max:
    .db $08

SPRING_ANI:
	.db $08                                                            ;number of frames
	.db $0A, $1A, $2A, $3A, $3A, $2A, $1A, $0A                         ;tile index frame animation

	.include "src/SystemConstants.asm"
    .include "src/SystemMacros.asm"
    .include "src/Math.asm"
    .include "src/Map.asm"
	.include "src/Animation.asm"
	
;------------------------------------------------------------------------------------;
;map loading macros

;macro to load a nametable + attributes into specified PPU addressess
;(nametable_address (including attributes), PPU_nametable_address)
LOAD_MAP .macro
    BIT PPU_STATUS                  ;read PPU_STATUS to reset high/low latch so low byte can be stored then high byte (little endian)
    SET_POINTER_TO_ADDR \2, PPU_ADDR, PPU_ADDR
    SET_POINTER_TO_ADDR \1, nt_pointer + 1, nt_pointer

    DEBUG_BRK
    CALL load_nametable

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

    ;IF_SIGNED_LT #$01, #$01, t
    ;    DEBUG_BRK
    ;    LDY #$01
    ;t:
    ;    DEBUG_BRK
    ;    LDY #$02

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
    SET_POINTER #HIGH(VRAM_BG_PLT), #LOW(VRAM_BG_PLT), PPU_ADDR, PPU_ADDR

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
    LDA #$00
    STA temp
    STA temp + 1
    nt_loop:
        nt_loop_nested:
            CPY #$C0
            BCC lt960
                CPX #$03
                BNE lt960
                    LDA [nt_pointer], y     ;get the value pointed to by nt_pointer_lo + nt_pointer_hi + y counter offset
                    JMP ntcmpendif
            lt960:
                LDA [nt_pointer], y         ;get the value pointed to by nt_pointer_lo + nt_pointer_hi + y counter offset
                CMP #$07
                BNE ntcmpendif
                    LDA temp
                    STA player_spawn
                    ASL a
                    ASL a
                    ASL a
                    STA OAM_RAM_ADDR + 3
                    STA pos_x

                    SEC
                    SBC #$7F
                    STA scroll_x

                    LDA temp + 1
                    STA player_spawn + 1
                    ASL a
                    ASL a
                    ASL a
                    STA OAM_RAM_ADDR + 3
                    STA pos_y

                    LDA #$00
            ntcmpendif:

            STA PPU_DATA                ;write byte to the PPU nametable address
            INY                         ;add by 1 to move to the next byte

            ADD temp, #$01
            STA temp
            IF_UNSIGNED_GT_OR_EQU temp, #$20, nrowreset
                LDA #$00
                STA temp

                ADD temp + 1, #$01
                STA temp + 1
            nrowreset:

            CPY #$00                    ;check if y is equal to 0 (it has overflowed)
            BNE nt_loop_nested          ;keep looping if y not equal to 0, otherwise continue

            INC nt_pointer + 1          ;increase the high byte of nt_pointer by 1 ((#$FF + 1) low bytes)
            INX                         ;increase x by 1

            CPX #$04                    ;check if x has looped and overflowed 4 times (1kb, #$04FF)
            BNE nt_loop                 ;go to the start of the loop if x is not equal to 0, otherwise continue
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
    STA speed_x
    STA speed_x + 1
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

init_sprites:
    SET_POINTER_TO_ADDR LEVEL_1_MAP_1, current_room, current_room + 1
    SET_POINTER_TO_ADDR VRAM_NT_1, current_VRAM, current_VRAM + 1
    LDA #$01
    STA scroll_x_type

    CALL init_animations

    JMP game_loop

;------------------------------------------------------------------------------------;

game_loop:
    ;keep looping until NMI is called and changes the vblank counter
    LDA vblank_counter             ;load the vblank counter
    vblank_wait_main:
        CMP vblank_counter         ;compare register a with the vblank counter
        BEQ vblank_wait_main       ;keep looping if they are equal, otherwise continue if the vblank counter has changed

	;clamp speed_x
    CALL clamp_signed, speed_x, #$FE, #$02
    LDA rt_val_1
    STA speed_x

    ;clamp gravity
    CALL clamp_signed, gravity, #$FB, #$04
    LDA rt_val_1
    STA gravity
	
	;if speed_x is >= 1, then apply friction and slow it down by 64
    IF_SIGNED_GT_OR_EQU speed_x, #$01, posxgtelse
        CALL sub_short, speed_x, speed_x + 1, #$40
        ST_RT_VAL_IN speed_x, speed_x + 1
		
    posxgtelse:
	
	;if speed_x is <= 255, then apply friction and slow it down by 64
    IF_SIGNED_LT_OR_EQU speed_x, #$FF, posxltelse
        CALL add_short, speed_x, speed_x + 1, #$40
        ST_RT_VAL_IN speed_x, speed_x + 1
    posxltelse:

	CALL read_controller
	CALL update_animations

    DIV8 pos_x, #$00, #$00, coord_x
    DIV8 pos_x, #$00, #$04, coord_x + 1
    DIV8 pos_x, #$04, #$00, coord_x + 2

    DIV8 pos_y, #$00, #$00, coord_y
    DIV8 pos_y, #$04, #$00, coord_y + 1
    DIV8 pos_y, #$00, #$04, coord_y + 2

    SET_POINTER_TO_VAL current_room, leftc_pointer + 1, leftc_pointer
    CALL mul_short, leftc_pointer + 1, coord_y, #$20
    ST_RT_VAL_IN leftc_pointer + 1, leftc_pointer
    ST_RT_VAL_IN rightc_pointer + 1, rightc_pointer

    SET_POINTER_TO_VAL current_room, downc_pointer + 1, downc_pointer
    CALL mul_short, downc_pointer + 1, coord_y + 1, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer

    SET_POINTER_TO_VAL current_room, upc_pointer + 1, upc_pointer
    CALL mul_short, upc_pointer + 1, coord_y + 2, #$20
    ST_RT_VAL_IN upc_pointer + 1, upc_pointer

    CALL check_collide_down
    MUL8 c_coord_y
    CLC
    ADC #$02
    STA temp
    LDA rt_val_1
    IS_SOLID_TILE nscdownelse
        DOWN_BUTTON_DOWN dbnotdown

        dbnotdown:

        INC c_coord_y
        IF_SIGNED_GT_OR_EQU gravity, #$00, notmovingdowncollide
            LDA rt_val_1
            CMP #$0A
            BNE spring_no_collide
                LDA temp
                STA pos_y

                LDA #$FA
                STA gravity
                LDA #$00
                STA gravity + 1

                CALL play_spring_animation

                JMP nscdownendif
            spring_no_collide:
        notmovingdowncollide:

        CALL handle_respawn

        JMP nscdownendif
    nscdownelse:
        IF_SIGNED_GT_OR_EQU gravity, #$00, nscdownendif
            LDA temp
            STA pos_y

            LDA #$FC
            STA gravity
            LDA #$7F
            STA gravity + 1
    nscdownendif:

    CALL check_collide_up
    IS_SOLID_TILE nscupelse
        UP_BUTTON_DOWN ubnotdown

        ubnotdown:
        JMP nscupendif
    nscupelse:
        IF_SIGNED_LT_OR_EQU gravity, #$00, nscupendif
            MUL8 c_coord_y
            SEC
            SBC #$01
            STA pos_y

            LDA #$01
            STA gravity
    nscupendif:

    IF_UNSIGNED_GT pos_x, #$04, scleft
    CALL check_collide_left
    IS_SOLID_TILE nscleftelse
        scleft:
        LEFT_BUTTON_DOWN lbnotdown
            CALL sub_short, speed_x, speed_x + 1, #$80
            ST_RT_VAL_IN speed_x, speed_x + 1
        lbnotdown:
        JMP nscleftendif
    nscleftelse:
        IF_SIGNED_LT_OR_EQU speed_x, #$00, nscleftendif
            MUL8 c_coord_x, #$01, #$00, pos_x

            LDA #$00
            STA speed_x
    nscleftendif:

    IF_UNSIGNED_LT pos_x, #$FB, scright
    CALL check_collide_right
    IS_SOLID_TILE nscrightelse
        scright:
        RIGHT_BUTTON_DOWN rbnotdown
            CALL add_short, speed_x, speed_x + 1, #$80
            ST_RT_VAL_IN speed_x, speed_x + 1
        rbnotdown:
        JMP nscrightendif
    nscrightelse:
        IF_SIGNED_GT_OR_EQU speed_x, #$00, nscrightendif
            MUL8 c_coord_x, #$00, #$01, pos_x

            LDA #$00
            STA speed_x
    nscrightendif:

    CALL add_short, gravity, gravity + 1, #$40
    ST_RT_VAL_IN gravity, gravity + 1

    ;add gravity to pos_y and set it as the player's y sprite position
    ADD pos_y, gravity
    STA pos_y
    STA OAM_RAM_ADDR

    ADD pos_x, speed_x
    STA pos_x

    CALL handle_room_intersect
    CALL handle_camera_scroll

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

    LDX ani_max
    BEQ ani_render_loop_end
    ani_render_loop:
        DEX

        LDA ani_active, x
        BEQ ani_chk_if_zero

        TXA
        ASL a
        TAY
        LDA ani_VRAM_pointer, y                     ;gets the first byte of point_address (high byte)
        STA PPU_ADDR                                ;store in high_byte_store
        LDA ani_VRAM_pointer + 1, y                 ;gets the second byte of point_address (low byte)
        STA PPU_ADDR                                ;store in low_byte_store

        LDA ani_frames, y
        STA temp
        LDA ani_frames + 1, y
        STA temp + 1
        LDY ani_current_frame, x
        LDA [temp], y
        STA PPU_DATA

        ani_chk_if_zero:
        INX
        DEX
        BEQ ani_render_loop_end
        JMP ani_render_loop
    ani_render_loop_end:
    SET_POINTER_TO_ADDR VRAM_NT_0, PPU_ADDR, PPU_ADDR

    LDA scroll_x
    STA $2005
    LDA scroll_y
    STA $2005

    INC vblank_counter              ;increases the vblank counter by 1 so the game loop can check when NMI has been called
	
    RTI                             ;returns from the interrupt

IQR:
    RTI