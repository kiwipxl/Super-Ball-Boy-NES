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

;-- Button input constants --;

;the following are a list of byte constants that will be and gated with an input byte
;to determine when a specific button is pressed

INPUT_ANY_BUTTON 	= #%11111111
INPUT_NO_BUTTON 	= #%00000000
INPUT_A_BUTTON 		= #%10000000
INPUT_B_BUTTON 		= #%01000000
INPUT_SELECT_BUTTON = #%00100000
INPUT_START_BUTTON 	= #%00010000
INPUT_LEFT_BUTTON 	= #%00001000
INPUT_UP_BUTTON 	= #%00000100
INPUT_RIGHT_BUTTON 	= #%00000010
INPUT_DOWN_BUTTON 	= #%00000001