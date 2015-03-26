  .inesprg 1   ;1 16KB PRG code
  .ineschr 1   ;1 8KB CHR data
  .inesmap 0   ;mapper 0 = NROM, no bank swapping
  .inesmir 1   ;background mirroring

;------------------------------------------------------------------------------------;

  .bank 3               ;uses the fourth bank, which is a 8kb ROM memory region
  .org $8000            ;places graphics tiles at the beginning of ROM (8000 - a000, offset: 0kb)
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1

;------------------------------------------------------------------------------------;

  .bank 2               ;uses the third bank, which is a 8kb ROM memory region
  .org $a000            ;places graphics tiles in the first quarter of ROM (a000 - e000, offset: 8kb)
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1

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

    .db $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3d
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

;------------------------------------------------------------------------------------;

  .bank 0             ;uses the first bank, which is a 8kb ROM memory region
  .org $c000          ;place all program code in the middle of PGR_ROM memory (c000 - e000, offset: 24kb)

;RESET is called when the NES starts up
RESET:
    SEI           ;disables external interrupt requests (BRK points)
    CLD           ;disables decimal mode (???)
    LDX #$40
    STX $4017     ;disables APU frame IRQ by writing to joystick 2 (???)
    LDX #$FF
    TXS           ;set the stack pointer to point to 256 bytes in RAM where the stack memory is located
    INX           ;add 1 to the x register and overflow it which results in 0
    STX $4010     ;disable DMC IRQs (???)

;------------------------------------------------------------------------------------;
;wait for the PPU to be ready and clear all mem from 0000 to 0800

;first wait for vertical blank to make sure the PPU is ready
vblank_wait_1:
    LDA $2002           ;loads the PPU status into register a
    BPL vblank_wait_1   ;if a is greater than 0 then continue looping until it is equal to 0 (not sure if correct)
    
;while waiting to make sure the PPU has properly stabalised, we will put the 
;zero page, stack memory and RAM into a known state by filling it with #$00
clr_mem_loop:
    LDA #$00
    STA $0000, x        ;set the zero page to 0
    STA $0100, x        ;set the stack memory to 0
    STA $0200, x        ;set sprite memory in RAM to 0
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
    LDA $2002           ;loads the PPU status into register a
    BPL vblank_wait_2   ;if a is greater than 0 then continue looping until it is equal to 0 (not sure if correct)

;------------------------------------------------------------------------------------;
  
load_palettes:
    ;write the PPU bg palette address $3F00 to the PPU memory address stored on the CPU
    LDA #$3F
    STA $2006                     ;write the high byte of $3F00 address
    LDA #$00
    STA $2006                     ;write the low byte of $3F00 address

    LDX #$00                      ;set x counter register to 0
    load_palettes_loop:
        LDA palette, x            ;load palette byte
        STA $2007                 ;write byte to the PPU
        INX                       ;add by 1 to move to next byte
        CPX #$20                  ;check if x is equal to 32
        BNE load_palettes_loop    ;keep looping if x is not equal to 32, otherwise continue

init_sprites:
    LDA #%10000000              ;enable NMI, sprites from Pattern Table 0
    STA $2000

    LDA #%00010000              ;enable sprite rendering
    STA $2001

load_sprites:
    LDX #$00                    ;start x register counter at 0

    load_sprites_loop:
        LDA sprites, x          ;load sprite attrib into a register (sprite + x)
        STA $0200, x            ;store attrib into ram (address + x)
        INX

        CPX sprite_data_len     ;compare x register to the data length of all sprites
        BNE load_sprites_loop   ;continue loop if x register is not equal to 0, otherwise move down

        JMP game_loop

game_loop:
    LDA $2002           ;loads the PPU status into register a
    BPL game_loop   ;if a is greater than 0 then continue looping until it is equal to 0 (not sure if correct)
    
    LDX #$00
    loop:
      INC $0200, x

      TXA
      CLC
      ADC #4
      TAX

      CPX sprite_data_len
      BNE loop

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