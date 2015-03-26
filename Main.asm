  .inesprg 1   ;1x 16KB PRG code
  .ineschr 1   ;1x  8KB CHR data
  .inesmap 0   ;mapper 0 = NROM, no bank swapping
  .inesmir 1   ;background mirroring

  ;------------------------------------------------------------------------------------;
  
  .bank 1
  .org $E000
  palette:
    ;.db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
    ;.db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

    .db $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3c,$3D,$3E,$3d
    .db $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2d

  sprites:
    ;y, tile index, palette index, x
    .db $80, $32, $00, $80
    .db $80, $33, $00, $88
    .db $88, $34, $00, $80
    .db $88, $35, $00, $88
  num_sprites:
    .db 4
  sprite_data_len:
    .db 16

  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                 ;processor will jump to the label NMI and return to the point where it was interrupted
  .dw RESET      ;when the processor first turns on or is reset, it will jump to the RESET label
  .dw 0          ;external interrupt IRQ is not used here

;------------------------------------------------------------------------------------;

  .bank 2
  .org $0000
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1

;------------------------------------------------------------------------------------;

  .bank 0
  .org $C000

;RESET is called when the NES starts up
RESET:
    SEI           ;disables IRQ (inerrupt request)
    CLD          ; disable decimal mode
    LDX #$40
    STX $4017    ; disable APU frame IRQ
    LDX #$FF
    TXS          ; Set up stack
    INX          ; now X = 0
    STX $2000    ; disable NMI
    STX $2001    ; disable rendering
    STX $4010    ; disable DMC IRQs

vblank_wait_1:       ; First wait for vblank to make sure PPU is ready
    BIT $2002
    BPL vblank_wait_1

mem_clr:
    LDA #$00
    STA $0000, x
    STA $0100, x
    STA $0300, x
    STA $0400, x
    STA $0500, x
    STA $0600, x
    STA $0700, x
    LDA #$FE
    STA $0200, x    ;move all sprites off screen
    INX
    BNE mem_clr

vblank_wait_2:      ; Second wait for vblank, PPU is ready after this
    BIT $2002
    BPL vblank_wait_2

;------------------------------------------------------------------------------------;
  
load_palettes:
    LDA $2002       ;read PPU status to reset the high/low latch
    LDA #$3F
    STA $2006    ; write the high byte of $3F00 address
    LDA #$00
    STA $2006    ; write the low byte of $3F00 address

    LDX #$00        ;set x counter register to 0
    load_palettes_loop:
        LDA palette, x        ;load palette byte
        STA $2007             ;write to PPU
        INX                   ;set index to next byte
        CPX #$20            
        BNE load_palettes_loop  ;if x = $20, 32 bytes copied, all done

init_sprites:
    LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
    STA $2000

    LDA #%00010000   ; enable sprites
    STA $2001

load_sprites:
    LDX #$00              ; start at 0

    load_sprites_loop:
        LDA sprites, x        ;load sprite attrib into a (sprite + x)
        STA $0200, x          ;store attrib into ram (address + x)
        INX

        CPX sprite_data_len              ; Compare X to hex $10, decimal 16

        BNE load_sprites_loop   ; Branch to load_sprites_loop if compare was Not Equal to zero
                                ; if compare was equal to 16, continue down

game_loop:
    BIT $2002
    BPL game_loop

    ;INC $0207

    JMP game_loop     ;jump back to game_loop, infinite loop

;NMI interrupts the cpu and is called once per video frame
;PPU is starting vblank time and is available for graphics updates
NMI:
    LDA #$00
    STA $2003   ;sets the low byte of the sprite memory access to 0
    LDA #$02
    STA $4014   ;sets the high byte of DMA access to 2
                ;this starts a data transfer of sprite memory while the cpu is running

    RTI         ;returns from the interrupt