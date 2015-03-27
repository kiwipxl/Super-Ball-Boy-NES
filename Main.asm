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

  .bank 1               ;uses the second bank, which is a 8kb ROM memory region

  .org $fffa            ;places the address of NMI, reset and BRK handlers at the very end of the ROM
  .dw NMI               ;address for NMI (non maskable interrupt). when an NMI happens (once per frame if enabled) the 
                        ;processor will jump to the label NMI and return to the point where it was interrupted
  .dw RESET             ;when the processor first turns on or is reset, it will jump to the RESET label
  .dw 0                 ;BRK is not used here

  .org $e000            ;place all program code at the third quarter of ROM (e000 - fffa, offset: 16kb)

  palette:
    ;.db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
    ;.db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

    ;bg palette
    .db $22, $29, $1a, $0f,     $0f, $36, $17, $0f,     $0f, $30, $21, $0f,     $0f, $07, $17, $0f
    ;sprite palette
    .db $22, $16, $27, $18,     $0f, $1a, $30, $27,     $0f, $16, $30, $27,     $0f, $0f, $36, $17

  sprites:
    ;y, tile index, attribs (palette 4 to 7, priority, flip), x
    .db $80, $32, %00000000, $80
    .db $80, $33, %00000000, $88
    .db $88, $34, %00000000, $80
    .db $88, $35, %00000000, $88
  num_sprites:
    .db 4
  sprite_data_len:
    .db 16

  nametable:
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 1

    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky ($24 = sky)

    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2

    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

    .db $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24  ;;row 3

    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24  ;;some brick tops

    .db $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24  ;;row 4

    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24  ;;brick bottoms

  attributes:
    .db %00000000, %00010000, %0010000, %00010000, %00000000, %00000000, %00000000, %00110000

;------------------------------------------------------------------------------------;

  .bank 0             ;uses the first bank, which is a 8kb ROM memory region
  .org $c000          ;place all program code in the middle of PGR_ROM memory (c000 - e000, offset: 24kb)

;RESET is called when the NES starts up
RESET:
    SEI           ;disables external interrupt requests
    CLD           ;the NES does not use decimal mode, so disable it
    LDX #$40
    STX $4017     ;disables APU frame counter IRQ by writing 64 to the APU register (todo: better understanding)
    LDX #$FF
    TXS           ;set the stack pointer to point to 256 bytes in RAM where the stack memory is located
    INX           ;add 1 to the x register and overflow it which results in 0
    STX $4010     ;disable DMC IRQ (APU memory access and interrupts) by writing 0 to the APU DMC register

;------------------------------------------------------------------------------------;
;wait for the PPU to be ready and clear all mem from 0000 to 0800

;first wait for vertical blank to make sure the PPU is ready
vblank_wait_1:
    LDA $2002           ;loads PPU_STATUS into register a
    BPL vblank_wait_1   ;if a is greater than 0 then continue looping until it is equal to 0 (not sure if correct)
    
;while waiting to make sure the PPU has properly stabalised, we will put the 
;zero page, stack memory and RAM into a known state by filling it with #$00
clr_mem_loop:
    LDA #$00
    STA $0000, x        ;set the zero page to 0
    STA $0100, x        ;set the stack memory to 0
    STA $0200, x        ;set OAM (object attribute memory) in RAM to 0
    STA $0300, x        ;set RAM to 0
    STA $0400, x        ;set RAM to 0
    STA $0500, x        ;set RAM to 0
    STA $0600, x        ;set RAM to 0
    STA $0700, x        ;set RAM to 0
    INX                 ;increase x by 1
    CPX #$00            ;check if x has overflowed into 0
    BNE clr_mem_loop    ;continue clearing memory if x is not equal to 0

;second and last wait for vertical blank to make sure the PPU is ready
vblank_wait_2:
    LDA $2002           ;loads PPU_STATUS into register a
    BPL vblank_wait_2   ;if a is greater than 0 then continue looping until it is equal to 0 (not sure if correct)

;------------------------------------------------------------------------------------;

;writes bg and sprite palette data to the PPU
load_palettes:
    ;write the PPU bg palette address $3F00 to the PPU register
    ;so whenever we write data to $2006, it will map to $3F00 in the PPU VRAM
    LDA $2002                       ;read PPU status to reset the high/low latch (may not be needed)

    LDA #$3F
    STA $2006                       ;write the high byte of $3F00 address
    LDA #$00
    STA $2006                       ;write the low byte of $3F00 address

    LDX #$00                        ;set x counter register to 0
    load_palettes_loop:
        LDA palette, x              ;load palette byte
        STA $2007                   ;write byte to the PPU data address
        INX                         ;add by 1 to move to next byte

        CPX #$20                    ;check if x is equal to 32
        BNE load_palettes_loop      ;keep looping if x is not equal to 32, otherwise continue

load_background:
    ;write the PPU nametable address $2000 to the PPU register
    ;so whenever we write data to $2006, it will map to $2000 in the PPU VRAM
    LDA $2002                       ;read PPU status to reset the high/low latch (may not be needed)

    LDA #$20
    STA $2006                       ;write the high byte of $2000 address
    LDA #$00
    STA $2006             ; write the low byte of $2000 address

    LDX #$00              ; start out at 0

    load_background_loop:
        LDA nametable, x     ; load data from address (background + the value in x)
        STA $2007             ; write to PPU
        INX                   ; X = X + 1

        CPX #$80              ; Compare X to hex $80, decimal 128 - copying 128 bytes
        BNE load_background_loop  ; Branch to load_background_loop if compare was Not Equal to zero
                                  ; if compare was equal to 128, keep going down

load_attributes:
    ;write the PPU attributes address $23C0 to the PPU register
    ;so whenever we write data to $2006, it will map to $23C0 in the PPU VRAM
    LDA $2002             ; read PPU status to reset the high/low latch

    LDA #$23
    STA $2006             ; write the high byte of $23C0 address
    LDA #$C0
    STA $2006             ; write the low byte of $23C0 address
    LDX #$00              ; start out at 0

    load_attributes_loop:
        LDA attributes, x      ; load data from address (attribute + the value in x)
        STA $2007             ; write to PPU
        INX                   ; X = X + 1

        CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
        BNE load_attributes_loop

;------------------------------------------------------------------------------------;

;initialises PPU settings
init_PPU:
    ;setup PPU_CTRL bits
    LDA #%10010000                ;enable NMI calling and set sprite pattern table to $0000 (0)
    STA $2000

    ;setup PPU_MASK bits
    LDA #%00011110                ;enable sprite rendering
    STA $2001

;loads all sprite attribs into $0200 (OAM - object attribute memory)
load_sprites:
    LDX #$00                      ;start x register counter at 0

    LDA #$00
    STA $0300
    STA $0301
    STA $0302

    load_sprites_loop:
        LDA sprites, x            ;load sprite attrib into register a (sprite + x)
        STA $0200, x              ;store attrib in OAM on RAM(address + x)
        INX

        CPX sprite_data_len       ;check if all attribs have been stored by comparing x to the data length of all sprites
        BNE load_sprites_loop     ;continue loop if x register is not equal to 0, otherwise move down

        JMP game_loop
        
game_loop:
    LDA $0000
    vblank_wait_main:
        CMP $0000
        BEQ vblank_wait_main

    LDX #$00
    loop:
      LDA $0200, x
      CLC
      ADC $0301
      STA $0200, x

      LDA $0203, x
      CLC
      ADC $0300
      STA $0203, x

      TXA
      CLC
      ADC #$04
      TAX

      CPX sprite_data_len
      BNE loop

    JMP game_loop     ;jump back to game_loop, infinite loop

;NMI interrupts the cpu and is called once per video frame
;PPU is starting vblank time and is available for graphics updates
NMI:
    ;copies 256 bytes of OAM data in RAM ($0200 - $02FF) to the PPU internal OAM
    ;this takes 513 cpu clock cycles and the cpu is temporarily suspended during the transfer
    LDA #$00
    STA $2003                     ;sets the low byte of PPU OAM_ADDR to 0
    ;stores the #$02 high byte + #$00 sprite attribs memory address in $4014 (OAM_DMA) and then begins the transfer
    LDA #$02
    STA $4014                     ;sets the high byte of OAM_DMA to #$02

    ;INC $0302
    ;LDA $0302
    ;STA $2005
    ;LDA #$00
    ;STA $2005

    INC $0000

latch_controller:
    ;write $0100 to $4016 to tell the controllers to latch the current button positions (???)
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016

check_a_press:
    LDA $4016                     ;load input status byte into register a
    AND #$00000001                ;check if bit 0 is equal to 1
    BEQ check_b_press             ;branches if register a equals 0, therefore no button was pressed
    ;-- a was pressed --

check_b_press:
    LDA $4016                     ;load input status byte into register a
    AND #$00000001                ;check if bit 0 is equal to 1
    BEQ check_select_press        ;branches if register a equals 0, therefore no button was pressed
    ;-- b was pressed --

check_select_press:
    LDA $4016                     ;load input status byte into register a
    AND #$00000001                ;check if bit 0 is equal to 1
    BEQ check_start_press        ;branches if register a equals 0, therefore no button was pressed
    ;-- select was pressed --

check_start_press:
    LDA $4016                     ;load input status byte into register a
    AND #$00000001                ;check if bit 0 is equal to 1
    BEQ check_up_press            ;branches if register a equals 0, therefore no button was pressed
    ;-- start was pressed --

check_up_press:
    LDA $4016                     ;load input status byte into register a
    AND #$00000001                ;check if bit 0 is equal to 1
    BEQ check_down_press          ;branches if register a equals 0, therefore no button was pressed
    ;-- up was pressed --
    DEC $301

check_down_press:
    LDA $4016                     ;load input status byte into register a
    AND #$00000001                ;check if bit 0 is equal to 1
    BEQ check_left_press          ;branches if register a equals 0, therefore no button was pressed
    ;-- down was pressed --
    INC $301

check_left_press:
    LDA $4016                     ;load input status byte into register a
    AND #$00000001                ;check if bit 0 is equal to 1
    BEQ check_right_press         ;branches if register a equals 0, therefore no button was pressed
    ;-- left was pressed --
    DEC $300

check_right_press:
    LDA $4016                     ;load input status byte into register a
    AND #$00000001                ;check if bit 0 is equal to 1
    BEQ input_end                 ;branches if register a equals 0, therefore no button was pressed
    ;-- right was pressed --
    INC $300

input_end:
    RTI                           ;returns from the interrupt