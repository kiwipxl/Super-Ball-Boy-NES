;------------------------------------------------------------------------------------;
;map macros

;macro to load a nametable + attributes into a specified PPU VRAM address
;input - (nametable_address (including attributes), PPU_nametable_address)
LOAD_ROOM .macro
    ;BIT PPU_STATUS                  ;read PPU_STATUS to reset high/low latch so low byte can be stored then high byte (little endian)
    SET_POINTER_TO_ADDR \2, PPU_ADDR, PPU_ADDR
    SET_POINTER_TO_ADDR \1, nt_pointer + 1, nt_pointer

    CALL load_nametable

    .endm

IS_SOLID_TILE .macro
    CMP #$02
    BEQ \1
    CMP #$05
    BEQ \1
    CMP #$06
    BEQ \1
    CMP #$15
    BEQ \1
    CMP #$16
    BEQ \1

    .endm

;-----------------------------------------------------------------------------------;

load_chamber_1:
    LOAD_ROOM CHAMBER_1_ROOM_0, VRAM_NT_0
    LOAD_ROOM CHAMBER_1_ROOM_1, VRAM_NT_1

    RTS

;writes nametable bytes pointing from nt_pointer into PPU VRAM
;before this function is called, the VRAM_NT_ID address must be written to PPU_ADDR
;so whenever we write data to PPU_DATA, it will map to the VRAM_NT_ID + write offset address in the PPU VRAM
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
                    DIV8 temp
                    STA OAM_RAM_ADDR + 3
                    STA pos_x

                    SEC
                    SBC #$7F
                    STA scroll_x

                    LDA temp + 1
                    STA player_spawn + 1
                    DIV8 temp + 1
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

handle_camera_scroll:
    IF_EQU scroll_x_type, #$00, right_scroll_map
        IF_UNSIGNED_GT_OR_EQU pos_x, #$7F, scrleftstartelse
            LDA pos_x
            SEC
            SBC #$7F
            STA scroll_x

            LDA #$7F
            STA OAM_RAM_ADDR + 3

            JMP scroll_x_endif
        scrleftstartelse:
            LDA pos_x
            STA OAM_RAM_ADDR + 3

            LDA #$00
            STA scroll_x

            JMP scroll_x_endif
    right_scroll_map:
        IF_UNSIGNED_LT_OR_EQU pos_x, #$7F, scrrightstartelse
            LDA pos_x
            SEC
            SBC #$80
            STA scroll_x

            LDA #$80
            STA OAM_RAM_ADDR + 3

            JMP scroll_x_endif
        scrrightstartelse:
            LDA pos_x
            STA OAM_RAM_ADDR + 3

            LDA #$FF
            STA scroll_x
    scroll_x_endif:

    RTS

handle_room_intersect:
    IF_NOT_EQU scroll_x_type, #$00, ntransleft
        IF_SIGNED_LT speed_x, #$00, ntransleft
            IF_UNSIGNED_GT_OR_EQU pos_x, #$FB, ntransleft
                SET_POINTER_TO_ADDR CHAMBER_1_ROOM_0, current_room, current_room + 1
                SET_POINTER_TO_ADDR VRAM_NT_0, current_VRAM, current_VRAM + 1

                LDA #$FB
                STA pos_x

                LDA #$00
                STA scroll_x_type
                JMP ntransright
    ntransleft:
        IF_SIGNED_GT speed_x, #$00, ntransright
            IF_UNSIGNED_GT_OR_EQU pos_x, #$FB, ntransright
                SET_POINTER_TO_ADDR CHAMBER_1_ROOM_1, current_room, current_room + 1
                SET_POINTER_TO_ADDR VRAM_NT_1, current_VRAM, current_VRAM + 1

                LDA #$00
                STA pos_x

                LDA #$01
                STA scroll_x_type
    ntransright:
    RTS

respawn:
    SET_POINTER_TO_ADDR CHAMBER_1_ROOM_1, current_room, current_room + 1
    SET_POINTER_TO_ADDR VRAM_NT_1, current_VRAM, current_VRAM + 1
    LDA #$01
    STA scroll_x_type

    MUL8 player_spawn
    STA OAM_RAM_ADDR + 3
    STA pos_x

    SEC
    SBC #$7F
    STA scroll_x

    MUL8 player_spawn + 1
    STA OAM_RAM_ADDR + 3
    STA pos_y

    RTS

check_collide_left:
    LDY coord_y
    STY c_coord_y

    LDY coord_x + 1
    LDA [leftc_pointer], y
    BNE ncleft
        CALL add_short, leftc_pointer + 1, leftc_pointer, #$20
        ST_RT_VAL_IN leftc_pointer + 1, leftc_pointer

        LDA [leftc_pointer], y
    ncleft:
    STY c_coord_x
    STA rt_val_1

    RTS

check_collide_right:
    LDY coord_y
    STY c_coord_y

    LDY coord_x + 2
    INY
    CPY #$20
    BNE crnoob
        LDY #$1F
    crnoob:

    LDA [rightc_pointer], y
    BNE ncright
        CALL add_short, rightc_pointer + 1, rightc_pointer, #$20
        ST_RT_VAL_IN rightc_pointer + 1, rightc_pointer

        LDA [rightc_pointer], y
    ncright:
    STY c_coord_x
    STA rt_val_1

    RTS

check_collide_down:
    CALL add_short, downc_pointer + 1, downc_pointer, #$20
    ST_RT_VAL_IN downc_pointer + 1, downc_pointer

    LDY coord_y + 1
    STY c_coord_y

    LDY coord_x
    LDA [downc_pointer], y
    BNE ncdown
        LDY coord_x + 1
        INY
        CPY #$20
        BNE cdnoob
            LDY coord_x
        cdnoob:
        LDA [downc_pointer], y
    ncdown:
    STY c_coord_x
    STA rt_val_1
    RTS

check_collide_up:
    LDY coord_y
    STY c_coord_y

    LDY coord_x
    LDA [upc_pointer], y
    BNE ncup
        LDY coord_x + 1
        INY
        CPY #$20
        BNE cunoob
            LDY #$00
        cunoob:
        LDA [upc_pointer], y
    ncup:
    STY c_coord_x
    STA rt_val_1
    RTS