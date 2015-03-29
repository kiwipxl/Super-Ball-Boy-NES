    .inesprg 1   ;1 16kb PRG code
    .ineschr 1   ;1 8kb CHR data
    .inesmap 0   ;mapper 0 = NROM, no bank swapping
    .inesmir 1   ;background mirroring

;------------------------------------------------------------------------------------;

    .bank 3                           ;uses the fourth bank, which is a 8kb ROM memory region
    .org $8000                        ;places graphics tiles at the beginning of ROM (8000 - a000, offset: 0kb)
    .incbin "assets/mario.chr"        ;includes 8kb graphics file from SMB1

;------------------------------------------------------------------------------------;

    .bank 2                           ;uses the third bank, which is a 8kb ROM memory region
    .org $a000                        ;places graphics tiles in the first quarter of ROM (a000 - e000, offset: 8kb)
    .incbin "assets/mario.chr"        ;includes 8kb graphics file from SMB1

;------------------------------------------------------------------------------------;

    .bank 1                           ;uses the second bank, which is a 8kb ROM memory region

    .org $fffa                        ;places the address of NMI, reset and BRK handlers at the very end of the ROM
    .dw NMI                           ;address for NMI (non maskable interrupt). when an NMI happens (once per frame if enabled) the 
                                      ;processor will jump to the label NMI and return to the point where it was interrupted
    .dw RESET                         ;when the processor first turns on or is reset, it will jump to the RESET label
    .dw IQR                           ;external inerrupts are not used

    .org $e000                        ;place all program code at the third quarter of ROM (e000 - fffa, offset: 24kb)

PALETTE:
    ;.db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
    ;.db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

    ;bg palette
    .db $22, $29, $1a, $0f,     $0f, $36, $17, $0f,     $0f, $30, $21, $0f,     $0f, $07, $17, $0f
    ;sprite palette
    .db $22, $16, $27, $18,     $0f, $1a, $30, $27,     $0f, $16, $30, $27,     $0f, $0f, $36, $17

SPRITES:
    ;y, tile index, attribs (palette 4 to 7, priority, flip), x
    .db $80, $32, %00000000, $80
    .db $80, $33, %00000000, $88
    .db $88, $34, %00000000, $80
    .db $88, $35, %00000000, $88
NUM_SPRITES         = 4
SPRITES_DATA_LEN    = 16

NAMETABLE:
    ;row1 (all sky)
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

    ;row2 (all sky)
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

    ;row3 (some brick tops)
    .db $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24

    ;row4 (some brick bottoms)
    .db $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24

ATTRIBUTES:
    .db %00000000, %00010000, %0010000, %00010000, %00000000, %00000000, %00000000, %00110000

    ;store game variables in zero page (2x faster access)
    .rsset $0000

vblank_counter      .rs     1
button_bits         .rs     1

;define PPU constants (constants are basically #defines, so they don't take up memory)

;-- PPU register address constants --;
;neither PPU or CPU has direct access to each other's memory so the CPU writes to and reads from VRAM
;through the following PPU registers

PPU_CTRL        = $2000             ;bit flags controlling PPU operations
                                    ;enable NMI (7), PPU master/slave (6), sprite height (5), bg tile select (4)
                                    ;sprite tile select (3), inc mode (2), nametable select (1 and 0)

PPU_MASK        = $2001             ;bit flags controlling the rendering of sprites, backgrounds and colour effects
                                    ;colour emphasis (7-5, BGR), enable sprites (4), enable backgrounds (3)
                                    ;enable sprite left column (2), enable background left column (1), grayscale (0)

PPU_STATUS      = $2002             ;bit flags for various functions in the PPU
                                    ;vblank (7), sprite 0 hit (6), sprite overflow (5)

PPU_SCROLL      = $2005             ;used to write the x and y scroll positions for backgrounds
PPU_ADDR        = $2006             ;a address on the PPU is stored here which PPU_DATA uses to write/read from
PPU_DATA        = $2007             ;register used to read/write from VRAM

;-- OAM (object attribute memory) register constants --;
OAM_ADDR        = $2003             ;stores the address of where to place RAM OAM in internal PPU OAM (#$00 if using OAM_DMA) 
OAM_DATA        = $2004             ;used to write data through OAM_ADDR into internal PPU OAM
                                    ;it is only useful for partial updates, but OAM_DMA transfer is faster
OAM_DMA         = $4014             ;stores the address of OAM_RAM_ADDR and starts a transfer of 256 bytes of OAM

;-- OAM RAM address constant --
OAM_RAM_ADDR    = $0200             ;address in RAM that stores all sprite attribs (low byte has to be #$00)

;-- PPU VRAM memory address constants --;
;the following are all addresses that map to different parts of the PPU's VRAM
VRAM_PT_0       = $0000     ;pattern table 0    ($0000 - $0FFF)     4096 bytes
VRAM_PT_1       = $1000     ;pattern table 1    ($1000 - $1FFF)     4096 bytes

VRAM_NT_0       = $2000     ;nametable 0        ($2000 - $23FF)     1024 bytes
VRAM_ATTRIB_0   = $23C0     ;attrib list 0      ($23C0 - $23FF)     64 bytes

VRAM_NT_1       = $2400     ;nametable 1        ($2400 - $27FF)     1024 bytes
VRAM_ATTRIB_1   = $27C0     ;attrib list 1      ($27C0 - $27FF)     64 bytes

VRAM_NT_2       = $2800     ;nametable 2        ($2800 - $2BFF)     1024 bytes
VRAM_ATTRIB_2   = $2BC0     ;attrib list 2      ($2BC0 - $2BFF)     64 bytes

VRAM_NT_3       = $2C00     ;nametable 3        ($2C00 - $2FFF)     1024 bytes
VRAM_ATTRIB_3   = $2FC0     ;attrib list 3      ($2FC0 - $2FFF)     64 bytes

VRAM_BG_PLT     = $3F00     ;background palette ($3F00 - $3FFF)     256 bytes
VRAM_SPRITE_PLT = $3F10     ;sprite palette     ($3F10 - $3F1F)     256 bytes

;------------------------------------------------------------------------------------;

    .bank 0                         ;uses the first bank, which is a 8kb ROM memory region
    .org $c000                      ;place all program code in the middle of PGR_ROM memory (c000 - e000, offset: 16kb)

;sub routine used to apply a breakpoint if the emulator has it mapped
brk:
    BIT $07FF                       ;read the end byte of RAM so an emulator can pick up on it
    RTS

;wait for vertical blank to make sure the PPU is ready
vblank_wait:
    LDA PPU_STATUS                  ;loads PPU_STATUS and sets the negative flag if bit 7 is 1 (vblank)
    BPL vblank_wait                 ;continue waiting until the negative flag is not set which means bit 7 is positive (equal to 1)
    RTS

;RESET is called when the NES starts up
RESET:
    SEI                             ;disables external interrupt requests
    CLD                             ;the NES does not use decimal mode, so disable it
    LDX #$40
    STX $4017                       ;disables APU frame counter IRQ by writing 64 to the APU register (todo: better understanding)
    LDX #$FF
    TXS                             ;set the stack pointer to point to 256 bytes in RAM where the stack memory is located
    INX                             ;add 1 to the x register and overflow it which results in 0
    STX $4010                       ;disable DMC IRQ (APU memory access and interrupts) by writing 0 to the APU DMC register

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
    LDA PPU_STATUS                  ;read PPU status to reset the high/low latch (may not be needed, but just in case)

    LDA #HIGH(VRAM_BG_PLT)
    STA PPU_ADDR                    ;write the high byte of $3F00 address
    LDA #LOW(VRAM_BG_PLT)
    STA PPU_ADDR                    ;write the low byte of $3F00 address

    LDX #$00                        ;set x counter register to 0
    load_palettes_loop:
        LDA PALETTE, x              ;load palette byte (palette + x byte offset)
        STA PPU_DATA                ;write byte to the PPU palette address
        INX                         ;add by 1 to move to next byte

        CPX #$20                    ;check if x is equal to 32
        BNE load_palettes_loop      ;keep looping if x is not equal to 32, otherwise continue

;> writes nametable 0 into PPU VRAM
;write the PPU nametable address VRAM_NT_0 to the PPU register PPU_ADDR
;so whenever we write data to PPU_DATA, it will map to the VRAM_NT_0 + write offset address in the PPU VRAM
load_background:
    LDA PPU_STATUS                  ;read PPU status to reset the high/low latch (may not be needed, but just in case)

    LDA #HIGH(VRAM_NT_1)            ;load the PPU nametable 0 address high byte
    STA PPU_ADDR                    ;write high byte to PPU_ADDR
    LDA #LOW(VRAM_NT_1)             ;load the PPU nametable 0 address low byte
    STA PPU_ADDR                    ;write low byte to PPU_ADDR

    LDX #$00
    JSR brk
    load_background_loop:
        LDA NAMETABLE, x            ;load nametable byte (nametable + x byte offset)
        STA PPU_DATA                ;write byte to the PPU nametable address
        INX                         ;add by 1 to move to the next byte

        CPX #$FF                    ;check if x is equal to 128
        BNE load_background_loop    ;keep looping if x is not equal to 128, otherwise continue

;> writes attributes 0 into PPU VRAM
;write the PPU attributes address VRAM_ATTRIB_0 to the PPU register PPU_ADDR
;so whenever we write data to PPU_DATA, it will map to VRAM_ATTRIB_0 + write offset in the PPU VRAM
load_attributes:
    LDA PPU_STATUS                  ;read PPU status to reset the high/low latch (may not be needed, but just in case)

    LDA #HIGH(VRAM_ATTRIB_1)        ;load the PPU attrib 0 address high byte
    STA PPU_ADDR                    ;write high byte to PPU_ADDR
    LDA #LOW(VRAM_ATTRIB_1)         ;load the PPU attrib 0 address low byte
    STA PPU_ADDR                    ;write low byte to PPU_ADDR

    LDX #$00
    load_attributes_loop:
        LDA ATTRIBUTES, x           ;load attributes byte (attributes + x byte offset)
        STA $2007                   ;write byte to the PPU attributes address
        INX                         ;add by 1 to move to the next byte

        CPX #$40                    ;check if x is equal to 8
        BNE load_attributes_loop    ;keep looping if x is not equal to 8, otherwise continue

;------------------------------------------------------------------------------------;

;initialises PPU settings
init_PPU:
    ;setup PPU_CTRL bits
    LDA #%10010000                  ;enable NMI calling and set sprite pattern table to $0000 (0)
    STA PPU_CTRL

    ;setup PPU_MASK bits
    LDA #%00011110                  ;enable sprite rendering
    STA PPU_MASK

;loads all sprite attribs into OAM_RAM_ADDR
load_sprites:
    LDX #$00                        ;start x register counter at 0

    LDA #$00
    STA $0300
    STA $0301
    STA $0302

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

    LDA button_bits
    AND #%00000010
    BEQ a_not_pressed
    INC $0300
    a_not_pressed:

    LDX #$00
    loop:
      LDA OAM_RAM_ADDR, x
      CLC
      ADC $0301
      STA OAM_RAM_ADDR, x

      LDA OAM_RAM_ADDR + 3, x
      CLC
      ADC $0300
      STA OAM_RAM_ADDR + 3, x

      TXA
      CLC
      ADC #$04
      TAX

      CPX #SPRITES_DATA_LEN
      BNE loop

    JMP game_loop                   ;jump back to game_loop, infinite loop

;------------------------------------------------------------------------------------;

read_controller:
    ;write $0100 to $4016 to tell the controllers to latch the current button positions (???)
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016
    STA button_bits

    LDX #$08
    read_loop:
        LDA $4016                   ;load input status byte into register a
        LSR a
        ROL button_bits
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

    INC $0302
    LDA $0302
    STA $2005
    LDA #$00
    STA $2005

    ;LDA #$00
    ;STA $2005
    ;STA $2005

    INC vblank_counter              ;increases the vblank counter by 1 so the game loop can check when NMI has been called

    JSR read_controller

input_end:
    RTI                             ;returns from the interrupt

IQR:
    RTI