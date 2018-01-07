  .inesprg 2   ; 2x 16KB PRG code banks (banks 0, 1, 2, 3)
  .ineschr 1   ; 1x  8KB CHR data banks (bank 4)
  .inesmap 0   ; mapper (0 = NROM), no bank swapping
  .inesmir 0   ; 0 = horizontal background mirroring (for vertical scrolling)
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Game state flowchart:
 ; 
 ;              v---------\
 ;  TITLE -> PLAYING -> PAUSED
 ; 		  		   -> GAME OVER
 ;     ^------------------/

;; RAM Layout:
 ; Page 0 ($0000-$00FF) - Main game variables
 ; Page 1 ($0100-$01FF) - Stack
 ; Page 2 ($0200-$02FF) - Sprite data
 ; Page 3 ($0300-$03FF) - Sound engine variables and data

;; PRG-ROM Layout:
 ; $8000-$9FFF (bank 0): Sound engine
 ; $A000-$BFFF (bank 1): Unused
 ; $C000-$DFFF (bank 2): Main program code
 ; $E000-$FFFA (bank 3): Palettes, sprite data, background name/attr tables
 ; $FFFA-$FFFF (bank 3): Interrupt vectors

 
;; TODO:
; - Add distinct features to Day/Sunset/Night modes: Day=normal, Sunset=slow and chill, Night=hardcore(?)
; - Test on standard emulators

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;; DECLARE VARIABLES
  ; Start variables at ram location $0000.
  ; This is within zero-page ($0000-$00FF) and so should be used only for heavy-use variables.
  .rsset $0000

; .rs 1 means reserve one byte of space
gamestate		.rs 1  ; gamestate (0=title, 1=playing, 2=pause, 3=gameover)
rng				.rs 2  ; 16-bit seed for 8-bit random number (in rng+0)
clock100		.rs 1  ; frame counter: rolls over every 100 frames
clock256		.rs 1  ; frame counter: rolls over every 256 frames
clock60			.rs 1  ; frame counter: rolls over every 60 frames (one second)
clockSecs		.rs 4  ; second counter: increments every 60 frames to track seconds (overflows after 136.2 years)
buttons			.rs 1  ; player 1 gamepad buttons, one bit per button
gamemode		.rs 1  ; game mode (0=Day, 1=Sunset, 2=Night)
difficulty		.rs 1  ; difficulty (0=Easy, 1=Medium, 2=Hard, 3=Insane)
difficultyflag	.rs 1  ; flag to indicate that difficulty should no longer change (1=max difficulty reached)

ppu_cr1			.rs 1  ; state of PPU Control Register 1 ($2000, PPUCTRL)
ppu_cr2			.rs 1  ; state of PPU Control Register 2 ($2001, PPUMASK)
ppu_scroll		.rs 1  ; current background scroll position (should only go to 240)
ppu_nametable	.rs 1  ; current nametable priority (0 or 2) for swapping while scrolling

playerx			.rs 1  ; player char, horizontal position of midpoint between feet
playery			.rs 1  ; player char, vertical position of midpoint between feet
playerfacing	.rs 1  ; direction player is facing (0=left, 1=right)
playerarm_animframe	.rs 1  ; track arm animation frame (0-5)
playerbobstate	.rs 1  ; tracks state of bobbing animation

playerlives		.rs 1  ; remaining number of player lives
playerinvnc		.rs 1  ; invincibility counter. on collision, this is set and must count down to 0 before another collision.
playerscore		.rs 2  ; player score (2 bytes to store up to a score of 65535)
highscore		.rs 2  ; high score (updated on game over)

obst1_update	.rs 1  ; flags for obstacle updates
obst2_update	.rs 1
obst3_update	.rs 1
obst1_release	.rs 1  ; timers controlling release of obstacles
obst2_release	.rs 1
obst3_release	.rs 1
obst1_x			.rs 1  ; x-pos of obstacles. obstacle sprites will be placed relative to this.
obst2_x			.rs 1
obst3_x			.rs 1
obst1_y			.rs 1  ; y-pos of obstacles. tracked for collision purposes.
obst2_y			.rs 1
obst3_y			.rs 1

pkupcollisions	.rs 1  ; pickup collision flags (one per bit)
pkuplife_flag	.rs 1  ; flag to indicate whether a life pickup has been released
pkuplife_x		.rs 1  ; x-pos of life pickup
pkuplife_y		.rs 1  ; y-pos of life pickup
pkupcoin_flag	.rs 1  ; flag to indicate whether a coin pickup has been released
pkupcoin_x		.rs 1  ; x-pos of coin pickup
pkupcoin_y		.rs 1  ; y-pos of coin pickup

startlatch		.rs 1  ; used to check if start button has been unpressed
buttonlatch		.rs 1  ; used to check if other buttons have been unpressed
cursorpos		.rs 1  ; position of the title screen cursor (0=day mode, 1=sunset mode, 2=night mode)


; High and low byte for indirect addressing. Used for long loops, i.e. loading >256 bytes.
; Note: Indirect addresses are read backwards (second addr holds high byte, first addr holds low byte).
indr_low		.rs 1  
indr_high		.rs 1

y_mod			.rs 1  ; for use in mod subroutine
tempvar1		.rs 1  ; temporary, short use variable

temp_bin		.rs 2  ; temp variables for binary to decimal conversion
temp_dec		.rs 5

; Sound related variables
sound_ptr		.rs 2  ; address pointer used by sound engine for indirect addressing (must be on zero-page)
sound_cur_song	.rs 1  ; index of currently playing song

; Masks for BIT instructions in button scripts (BIT masks use variables instead of constants due to BIT opcode issue)
MASK_A			.rs 1
MASK_B			.rs 1
MASK_SELECT		.rs 1
MASK_START		.rs 1
MASK_UP			.rs 1
MASK_DOWN		.rs 1
MASK_LEFT		.rs 1
MASK_RIGHT		.rs 1

PKUP_COLL_LIFE	.rs 1  ; masks for pkupcollisions
PKUP_COLL_COIN	.rs 1  ; *BIT masks use variables instead of constants due to BIT opcode issue

;; DECLARE CONSTANTS
STATETITLE		= $00  ; displaying title screen
STATEPLAYING	= $01  ; playing game
STATEPAUSE		= $02  ; displaying pause screen
STATEGAMEOVER	= $03  ; displaying game over screen
  
WALL_LEFT		= $0D  ; player (coordinate point) boundaries
WALL_RIGHT		= $F6
WALL_TOP		= $28
WALL_BOTTOM		= $A0

PLAYERX_INIT	= $80
PLAYERY_INIT	= $58
PLAYERBASESPEED = $02  ; initial horiz speed per frame
PLAYERINVNC		= 80   ; number of invincibility frames after collision

OBSTBASESPEED	= $01  ; initial upward speed of obstacles
OBST1_X_INIT	= $30
OBST2_X_INIT	= $60
OBST3_X_INIT	= $90
OBST_REL_INIT	= $50  ; initial release timer value. evenly spaces obstacles (80px apart)
OBST_RESETY		= $FF  ; reset y-pos for obstacles after wrap, and before initial release

PKUPBASESPEED	= $01  ; initial upward speed of pickups
;PKUPLIFECHANCE	= 32   ; set to N for a 1/N chance to spawn on each frame (should ideally be a power of 2)
PKUPLIFEX_INIT	= $20
PKUPLIFEY_INIT	= $F2
;PKUPCOINCHANCE	= 3    ; set to N for a 1/N chance to spawn on each frame (should ideally be a power of 2)
PKUPCOINX_INIT	= $A0
PKUPCOINY_INIT	= $FF

UI_CUTOFF		= $14  ; bottom pixel of UI elements. no game objects should go above this y-pos.

UI_LIVESX		= $F0  ; lives counter position
UI_LIVESY		= $0C
UI_SCOREX		= $08  ; score counter position
UI_SCOREY		= $0C
UI_HISCOREX		= $74  ; high-score display position
UI_HISCOREY		= $0C

CURSOR_DAY		= $8F  ; cursor y-positions for each mode selection
CURSOR_SUNSET	= $A7
CURSOR_NIGHT	= $BF

SPRITE_RAM_UI	= $0200  ; starting location of sprite RAM for UI elements (also starting point for all sprites)
SPRITE_RAM_OBST	= $0260  ; starting location of sprite RAM for obstacles
SPRITE_RAM_CHAR	= $0290  ; starting location of sprite RAM for character
SPRITE_RAM_PKUP	= $02C0  ; starting location of sprite RAM for pickups
SPRITE_RAM_TITL	= $02C8  ; starting location of sprite RAM for title screen elements
NUMSPRITES = (8+10+6+12+12+2+1)  ; number of active sprites. used when initially loading sprites.

PAUSED_TEXTX	= $68
PAUSED_TEXTY	= $60
;PAUSED_PPCR2	= %10000001  ; XORed with state of PPUMASK to create a pause gray-out. (grayscale + intensify reds)
GAMEOVER_TEXTX	= $5C
GAMEOVER_TEXTY	= $60

;;;;;;;;;;;;;;;;;;


  .bank 2
  .org $C000

;; Reset script ;;
vblankwait:
  BIT $2002
  BPL vblankwait
  RTS
  
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

  JSR vblankwait  ; First wait for vblank to make sure PPU is ready
  
clrmem:
  LDA #$00
  STA $0000, x  ; initializes all variables to 0
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x
  INX
  BNE clrmem
   
  JSR vblankwait  ; Second wait for vblank, PPU is ready after this

  
;; Set initial values (on RESET) ;;
  ; set default 16-bit rng seed
  LDA #$12
  STA rng		; store high 8 bits in rng address
  LDA #$34
  STA rng+1		; store low 8 bits in rng address
  
  LDA #%10010000  	; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA ppu_cr1		; port $2000
  LDA #%00011110  	; enable sprites, enable background, no clipping on left side
  STA ppu_cr2		; port $2001
  
  LDA #PLAYERX_INIT
  STA playerx
  LDA #PLAYERY_INIT
  STA playery
  LDA #$01
  STA playerfacing
  LDA #$03
  STA playerlives
  
  JSR Obst_Init		; initialize obstacle positions, variables, and timers
  
  LDA #PKUPLIFEX_INIT
  STA pkuplife_x
  LDA #PKUPLIFEY_INIT
  STA pkuplife_y
  LDA #PKUPCOINX_INIT
  STA pkupcoin_x
  LDA #PKUPCOINY_INIT
  STA pkupcoin_y
  
  ; Set mask "constants"
  LDA #%10000000
  STA PKUP_COLL_LIFE
  LDA #%01000000
  STA PKUP_COLL_COIN
  
  LDA #%10000000
  STA MASK_A
  LDA #%01000000
  STA MASK_B
  LDA #%00100000
  STA MASK_SELECT
  LDA #%00010000
  STA MASK_START
  LDA #%00001000
  STA MASK_UP
  LDA #%00000100
  STA MASK_DOWN
  LDA #%00000010
  STA MASK_LEFT
  LDA #%00000001
  STA MASK_RIGHT

;; Sprite data only needs to be fully loaded once, here.
LoadSprites:
  ; start DMA transfer of sprite data from $0200+ to SPR-RAM
  LDA #$00
  STA $2003		; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014		; set the high byte (02) of the RAM address, start the transfer
  LDX #$00
LoadSpritesLoop:
  LDA sprites, x
  STA $0200, x
  INX
  CPX #(NUMSPRITES*4)  ; load all sprites (4 data bytes each)
  BNE LoadSpritesLoop
  ;LDA ( sprites+1 ), x  ; 64*4 = 256 bytes, but loop can only run 255 times (max of X). if needed, add last data byte
  ;STA ( $0201+$01 ), x
  
  
;; Write second Playing nametable to $2800 (mirrored on $2C00)
 ; this must be done here because loading two nametables at once during the game will
 ;    result in an NMI being called halfway through the second load.
 ; since we don't scroll on the menu, we won't see this second nametable until the game starts
  LDA $2002					; read PPU status to reset the high/low latch
  LDA #$28
  STA $2006					; write the high byte of $2800 address (nametable 1)
  LDA #$00
  STA $2006					; write the low byte of $2800 address (nametable 1)
  LDX #$00
  LDY #$00
  
  LDA #LOW(background1)		; load 2-byte address of background1 into indr_low and indr_high
  STA indr_low				;   for indirect addressing
  LDA #HIGH(background1)
  STA indr_high
  
  JSR LoadNametable
  
  
; Set starting game state
  LDA #STATETITLE
  STA gamestate
; Load initial Title screen graphics and logic
  JSR EngineTitleInit

  
  LDA ppu_cr1
  STA $2000

  LDA ppu_cr2
  STA $2001
  
  
; Initialize sound engine
  JSR sound_init
  

Forever:
  JMP Forever     ; main game loop, waiting for NMI
  
 
;;; Start of VBlank ;;;
  ; VBlank is the only safe time to write to PPU.
  ; Thus, all PPU-writing code should be near the start of NMI.
  ; Code towards the end of NMI can potentially run past VBlank into next screen drawing cycle.
  ; This is fine for all code that does not write to PPU (unless it runs long enough to get to next NMI).
NMI:

;; Swap Nametables if needed, for smooth scrolling
NTSwapCheck:
  LDA ppu_scroll		; check if the scroll just wrapped from 240 to 0
  CMP #240
  BNE NTSwapCheckDone
  LDA #0
  STA ppu_scroll		; reset ppu_scroll
  
NTSwap:
  LDA ppu_nametable		; load current Nametable number (%00 or %10)
  EOR #%00000010		; exclusive OR of bit 0 will flip that bit
  STA ppu_nametable

NTSwapCheckDone:
  LDA #$00
  STA $2005		; first write: no horizontal scrolling
  LDA ppu_scroll
  STA $2005		; second write: advance vertical scroll to ppu_scroll
  ; ppu_scroll will only increment if gamestate is STATEPLAYING, if ppu_scroll is fixed at 0, scrolling will not happen.
  

;; PPU clean up section, so rendering the next frame starts properly.
  LDA ppu_cr1   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  ORA ppu_nametable	; swap Nametables 0 and 2
  STA $2000
  LDA ppu_cr2   ; enable sprites, enable background, no clipping on left side
  STA $2001

;; Initiate sprite update
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

  
  
;; Advance random number (gameplay seed will be determined by length of time spend on title screen)
  JSR prng
  
;; Get controller inputs and start game engine
  JSR ReadController	; get the current button data for player 1
  
;; Check for Start button
  LDA buttons
  BIT MASK_START			; get Start button, bit is 1 (Z=0) if start is pressed
  BNE StartCheck_StartPressed  ; branch if Z=0
  LDA #$00
  CMP startlatch			; check state of startlatch
  BEQ GameEngine			; if start is not pressed and startlatch is clear, skip all checks
  LDA #$00
  STA startlatch			; if start is not pressed and startlatch is set, clear startlatch
  JMP GameEngine			; since start is not pressed, skip all checks

StartCheck_StartPressed:
  LDA #$00
  CMP startlatch			; check state of startlatch
  BEQ StartCheck_Playing	; if start is pressed and startlatch is clear, change state
  JMP GameEngine			; if start is pressed and startlatch is set, skip all checks
  
  
StartCheck_Playing:
  LDA gamestate
  CMP #STATEPLAYING		; check if we're Playing
  BNE StartCheck_Title	; if not, see if we're on Title screen
  LDA #STATEPAUSE		; if so, set Pause state
  STA gamestate
  JSR EnginePausedInit	; run initial Pause script, loading sprites
  LDA #$01
  STA startlatch		; engage startlatch, indicating start is being held down
  JMP GameEngine		; skip remaining checks
StartCheck_Title:
  LDA gamestate
  CMP #STATETITLE			; check if we're on Title screen
  BNE StartCheck_Paused		; if not, see if we're Paused
  LDA #STATEPLAYING			; if so, set Playing state
  STA gamestate
  JSR EnginePlayingInit_T	; run initial start new game script
  LDA #$01
  STA startlatch		; engage startlatch, indicating start is being held down
  JMP GameEngine		; skip remaining checks
StartCheck_Paused:
  LDA gamestate
  CMP #STATEPAUSE			; check if we're on Pause screen
  BNE StartCheck_GameOver	; if not, check if we're on Game Over screen
  LDA #STATEPLAYING			; if so, set Playing state
  STA gamestate
  JSR EnginePlayingInit_P	; run initial unpause script
  LDA #$01
  STA startlatch		; engage startlatch, indicating start is being held down
  JMP GameEngine		; skip remaining checks
StartCheck_GameOver:
  LDA gamestate
  CMP #STATEGAMEOVER	; check if we're on Game Over screen
  BNE GameEngine		; if not, continue to GameEngine
  LDA #STATETITLE		; if so, set Title state
  STA gamestate
  JSR EngineTitleInit	; run initial new game script
  LDA #$01
  STA startlatch		; engage startlatch, indicating start is being held down
  JMP GameEngine		; skip remaining checks
  
  
GameEngine:  
  LDA gamestate
  CMP #STATETITLE
  BNE GameEngine_NotTitle	; need to use JMP here because relative addressing used by BEQ goes out of range
  JMP EngineTitle			; game is displaying title screen
GameEngine_NotTitle:
  
  LDA gamestate
  CMP #STATEPLAYING
  BNE GameEngine_NotPlaying	
  JMP EnginePlaying			; game is playing
GameEngine_NotPlaying:
  
  LDA gamestate
  CMP #STATEPAUSE
  BNE GameEngine_NotPaused
  JMP EnginePause			; game is paused
GameEngine_NotPaused:
  
  LDA gamestate
  CMP #STATEGAMEOVER
  BNE GameEngine_NotOver	
  JMP EngineGameOver		; game is displaying ending screen
GameEngine_NotOver:

GameEngineDone:  
  
  
  
SoundEngine:
  JSR sound_play_frame
SoundEngineDone:

  RTI             		; return from NMI
 
 
 
 
;;;;;;;;;;;;;;;;;;
EngineTitleInit:
; Initial script to run on game start or when gamestate switches from Game Over to Title screen

  LDA #0
  STA ppu_scroll		; reset and disable background scrolling
  
  LDA #$00
  STA ppu_nametable		; reset nametable priority to default (display nametable 0)

  LDA #$03
  STA playerlives		; reset lives
  
  LDA #$00
  STA difficulty		; reset difficulty to Easy ($00)
  LDA #$00
  STA difficultyflag	; reset difficulty flag

  
  
;; Load palettes ;;
EngineTitleInit_LoadPlts:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address (palette area)
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address (palette area)
  LDX #$00              ; start out at 0
EngineTitleInit_LoadPltsLoop:
  LDA titlepalette, x
  STA $2007             ; write to PPU
  INX
  CPX #32			    ; run 32 times for 16 bg colors and 16 sprite colors
  BNE EngineTitleInit_LoadPltsLoop
  
;; Load background ;;
  ; disable sprite and background visibility to properly unlock PPU RAM
  LDA ppu_cr2
  EOR #%00011000
  STA $2001


EngineTitleInit_LoadBG:
  ;; write Title screen nametable to $2000 (mirrored on $2400)
  LDA $2002					; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006					; write the high byte of $2000 address (nametable 0)
  LDA #$00
  STA $2006					; write the low byte of $2000 address (nametable 0)
  LDX #$00
  LDY #$00
  
  LDA #LOW(background_title)		; load 2-byte address of background_title into indr_low and indr_high
  STA indr_low						;   for indirect addressing
  LDA #HIGH(background_title)
  STA indr_high
  
  JSR LoadNametable
  
  
;; Hide game sprites ;;
  LDX #$00  
EngineTitleInit_HideSpritesLoop:
  LDA ($0200+2), x					; load attributes byte of sprite data
  EOR #%00100000					; XOR to set Priority bit to 1 (display behind BG)
  STA ($0200+2), x
  INX								; advance to next sprite
  INX
  INX
  INX
  CPX #(SPRITE_RAM_TITL - $0200)	; only hide sprites up until Title sprites are reached
  BNE EngineTitleInit_HideSpritesLoop
  
  ; Move player and all obstacles off-screen.
  ;  Without this, sprites may show up through "black" (transparent) pixels on title background.
  LDA #$F0
  STA playerx
  STA playery
  JSR CharMoveSpritesUpdate  ; shift character sprites to match (playerx, playery) position

  LDA #$FF
  STA obst1_y
  STA obst2_y
  STA obst3_y
  JSR Obst_MoveY
  
  ; clear Game Over letters
  LDX #S_LETTER1
  JSR ClearUIElement
  LDX #S_LETTER2
  JSR ClearUIElement
  LDX #S_LETTER3
  JSR ClearUIElement
  LDX #S_LETTER4
  JSR ClearUIElement
  LDX #S_LETTER5
  JSR ClearUIElement
  LDX #S_LETTER6
  JSR ClearUIElement
  LDX #S_LETTER7
  JSR ClearUIElement
  LDX #S_LETTER8
  JSR ClearUIElement
  
  ; reset cursor position to Day mode
  LDA #$00
  STA cursorpos							; update variable
  LDA #CURSOR_DAY
  STA (SPRITE_RAM_TITL+S_CURSOR+0)		; change cursor y-pos
  LDA (SPRITE_RAM_TITL+S_CURSOR+2)		
  AND #%11111100						; clear last two bits
  ORA #%00000000						; set last two bits to %00
  STA (SPRITE_RAM_TITL+S_CURSOR+2)		; change cursor palette number
  
  LDA #$00
  STA gamemode			; reset gamemode to Day mode
  
  JSR sound_unpause		; reset sound engine pause state
  
  LDA #sng_Title		; load and play Title theme
  STA sound_cur_song
  JSR sound_load
  
  RTS  ; end of EngineTitle_Init

  
EngineTitle:
  
;; Advance clocks
  JSR ClockStep
  
  ; Reset clockSecs and fix to 0 while on Title screen
  LDA #$00
  STA clockSecs+3
  STA clockSecs+2
  STA clockSecs+1
  STA clockSecs+0
  
  
EngineTitle_ButtonUp:
  LDA buttons
  BIT MASK_UP					; get Up button
  BEQ EngineTitle_ButtonDown	; skip if bit is 0 (Z=1). if we branch here, Up was not pressed
  LDA #$00
  CMP buttonlatch				; check if a button is still being held down
  BEQ EngineTitle_ButtonUpCont
  JMP EngineTitle_SkipUpdates	; if so, skip all updates
EngineTitle_ButtonUpCont:
  LDA cursorpos
  SEC
  SBC #$01
  STA cursorpos					; if not, update cursor position
  LDA #$01
  STA buttonlatch				; engage buttonlatch, indicating a button is being held down
  JMP EngineTitle_ButtonDone	; if Up is pressed, don't check Down
EngineTitle_ButtonDown:
  LDA buttons
  BIT MASK_DOWN					; get Down button
  BEQ EngineTitle_NoUpDown		; skip if bit is 0 (Z=1). if we branch here, Up/Down were not pressed
  LDA #$00
  CMP buttonlatch				; check if a button is still being held down
  BEQ EngineTitle_ButtonDownCont
  JMP EngineTitle_SkipUpdates	; if so, skip all updates
EngineTitle_ButtonDownCont:
  LDA cursorpos
  CLC
  ADC #$01
  STA cursorpos					; if not, update cursor position
  LDA #$01
  STA buttonlatch				; engage buttonlatch, indicating a button is being held down
  JMP EngineTitle_ButtonDone	; if Down is pressed, don't run NoUpDown script
EngineTitle_NoUpDown:
  LDA #$00
  STA buttonlatch				; since Up/Down were not pressed, clear button latch
  JMP EngineTitle_SkipUpdates	; since Up/Down were not pressed, skip all cursor and background updates
EngineTitle_ButtonDone:

; If cursorpos went below $00 (up from top option), set to $00
	LDA cursorpos
	CMP #$FF
	BNE EngineTitle_NoUnderflow
	LDA #$00
	STA cursorpos
	JMP EngineTitle_SkipUpdates
EngineTitle_NoUnderflow:
; If cursorpos went above $02 (down from bottom option), set to $02
	LDA cursorpos
	CMP #$03
	BNE EngineTitle_NoOverflow
	LDA #$02
	STA cursorpos
	JMP EngineTitle_SkipUpdates
EngineTitle_NoOverflow:

;; Change cursor y-position ($8F for Day mode, $A7 for Sunset mode, $BF for Night mode)
;; Change cursor palette number (%00000000 for Day mode, %00000001 for Sunset mode, %00000010 for Night mode)
;; Swap background attribute table to switch background palette (BG0 for Day mode, BG1 for Sunset mode, BG2 for Night mode).
  LDA cursorpos
  CMP #$00
  BNE EngineTitle_CursorMove1
  LDA #CURSOR_DAY						; change cursor y-pos
  STA (SPRITE_RAM_TITL+S_CURSOR+0)
  
  LDA (SPRITE_RAM_TITL+S_CURSOR+2)
  AND #%11111100						; clear last two bits
  ORA #%00000000						; set last two bits to %00
  STA (SPRITE_RAM_TITL+S_CURSOR+2)		; change cursor palette number
  
  JSR ReplaceAttTables_DayMode			; swap background attribute table
  LDA #$00
  STA gamemode							; update gamemode for Day
  
  JMP EngineTitle_CursorMoveDone
EngineTitle_CursorMove1:
  CMP #$01
  BNE EngineTitle_CursorMove2
  LDA #CURSOR_SUNSET					; change cursor pos
  STA (SPRITE_RAM_TITL+S_CURSOR+0)
  
  LDA (SPRITE_RAM_TITL+S_CURSOR+2)		; change cursor palette number
  AND #%11111100						; clear last two bits
  ORA #%00000001						; set last two bits to %01
  STA (SPRITE_RAM_TITL+S_CURSOR+2)
  
  JSR ReplaceAttTables_SunsetMode		; swap background attribute table
  LDA #$01
  STA gamemode							; update gamemode for Sunset
  
  JMP EngineTitle_CursorMoveDone
EngineTitle_CursorMove2:  ; else
  LDA #CURSOR_NIGHT						; change cursor pos
  STA (SPRITE_RAM_TITL+S_CURSOR+0)
  
  LDA (SPRITE_RAM_TITL+S_CURSOR+2)		; change cursor palette number
  AND #%11111100						; clear last two bits
  ORA #%00000010						; set last two bits to %10
  STA (SPRITE_RAM_TITL+S_CURSOR+2)
  
  JSR ReplaceAttTables_NightMode		; swap background attribute table
  LDA #$02
  STA gamemode							; update gamemode for Night

  JMP EngineTitle_CursorMoveDone
EngineTitle_CursorMoveDone:
  
  ; reset clock256 and hide cursor to force cursor blink on next frame (hides laggy cursor palette switching)
  LDA (SPRITE_RAM_TITL+S_CURSOR+2)
  ORA #%00100000		; set cursor sprite priority to 1 (hide)
  STA (SPRITE_RAM_TITL+S_CURSOR+2)
  LDA #$FF				; cursor will reappear next frame when clock hits $00
  STA clock256
  
  ; initiate sprite update here to force cursor to update before background (preventing palette overlap)
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer
  
  
EngineTitle_SkipUpdates:
  
  

;; Blink cursor
  LDA clock256	; load A and Y for mod
  LDY #16		; blink every 16 frames
  JSR mod
  CMP #0
  BNE EngineTitle_CursorBlinkDone
  LDA (SPRITE_RAM_TITL+S_CURSOR+2)
  EOR #%00100000  ; flip cursor sprite priority
  STA (SPRITE_RAM_TITL+S_CURSOR+2)
EngineTitle_CursorBlinkDone:
  

  JMP GameEngineDone

;;;;;;;;;;;;;;;;;;

EnginePausedInit:
; Initial script to run when gamestate switches from Playing to Pause
  
EnginePausedInit_LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address (palette area)
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address (palette area)
  LDX #$00              ; start out at 0
EnginePausedInit_LoadPalettesLoop:
  LDA pausepalette, x
  STA $2007             ; write to PPU
  INX
  CPX #32			    ; run 32 times for 16 bg colors and 16 sprite colors
  BNE EnginePausedInit_LoadPalettesLoop
  
;; PPU clean up (must be called, or background will skip for a frame on pause)
  LDA #$00
  STA $2005		; first write: no horizontal scrolling
  LDA ppu_scroll
  STA $2005		; second write: advance vertical scroll
  LDA ppu_cr1   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  ORA ppu_nametable	; swap Nametables 0 and 2
  STA $2000
  LDA ppu_cr2   ; enable sprites, enable background, no clipping on left side
  STA $2001

  
;; Print "Paused" on screen
  ; load letters into sprite slots
  LDY #0			; get Y ready to offset letter x-positions
  
  LDX #S_LETTER1	; load ram offset to X (which sprite to load)
  LDA #T_P			; load tile number for letter
  JSR PausedLetterLoop
  
  LDX #S_LETTER2
  LDA #T_A
  JSR PausedLetterLoop
  
  LDX #S_LETTER3
  LDA #T_U
  JSR PausedLetterLoop
  
  LDX #S_LETTER4
  LDA #T_S
  JSR PausedLetterLoop

  LDX #S_LETTER5
  LDA #T_E
  JSR PausedLetterLoop
  
  LDX #S_LETTER6
  LDA #T_D
  JSR PausedLetterLoop
  
  JMP PausedLetterDone
  
PausedLetterLoop:
  STA (SPRITE_RAM_UI+1), x	; set tile number
  TYA
  CLC
  ADC #PAUSED_TEXTX			; get x-pos, offset by Y
  STA (SPRITE_RAM_UI+3), x	; set x-pos
  LDA #PAUSED_TEXTY			; get y-pos
  STA (SPRITE_RAM_UI+0), x	; set y-pos
  INY						; increment Y by 8 pixels
  INY
  INY
  INY
  INY
  INY
  INY
  INY
  RTS
PausedLetterDone:
  
  LDA #sfx_Pause	; play Pause SFX
  JSR sound_load
  
  JSR sound_pause	; run sound engine pause script
  
  
  RTS	; end of EnginePausedInit
  
EnginePause:
  ;; Main pause loop
  JMP GameEngineDone


  
;;;;;;;;;;;;;;;;;;

EngineGameOverInit:
; Initial script to run when gamestate switches from Playing to Game Over
  
  ; disable sprite and background visibility to properly unlock PPU RAM
  LDA ppu_cr2
  EOR #%00011000
  STA $2001
  
EngineGameOverInit_LoadPlts:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address (palette area)
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address (palette area)
  LDX #$00              ; start out at 0
EngineGameOverInit_LoadPltsLoop:
  LDA gameoverpalette, x
  STA $2007             ; write to PPU
  INX
  CPX #32			    ; run 32 times for 16 bg colors and 16 sprite colors
  BNE EngineGameOverInit_LoadPltsLoop
  
;; PPU clean up (must be called, or background will skip for a frame on pause)
  LDA #$00
  STA $2005			; first write: no horizontal scrolling
  LDA ppu_scroll
  STA $2005			; second write: advance vertical scroll
  LDA ppu_cr1   	; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  ORA ppu_nametable	; swap Nametables 0 and 2
  STA $2000
  LDA ppu_cr2  		; enable sprites, enable background, no clipping on left side
  STA $2001

  
;; Print "Game Over" on screen
  ; load letters into sprite slots
  LDY #0			; get Y ready to offset letter x-positions
  
  LDX #S_LETTER1	; load ram offset to X (which sprite to load)
  LDA #T_G			; load tile number for letter
  JSR GameOverLetterLoop
  
  LDX #S_LETTER2
  LDA #T_A
  JSR GameOverLetterLoop
  
  LDX #S_LETTER3
  LDA #T_M
  JSR GameOverLetterLoop
  
  LDX #S_LETTER4
  LDA #T_E
  JSR GameOverLetterLoop

  INY  ; space - increment Y by 8 pixels
  INY
  INY
  INY
  INY
  INY
  INY
  INY
  
  LDX #S_LETTER5
  LDA #T_O
  JSR GameOverLetterLoop
  
  LDX #S_LETTER6
  LDA #T_V
  JSR GameOverLetterLoop
  
  LDX #S_LETTER7
  LDA #T_E
  JSR GameOverLetterLoop
  
  LDX #S_LETTER8
  LDA #T_R
  JSR GameOverLetterLoop
  
  JMP GameOverLetterDone
  
GameOverLetterLoop:
  STA (SPRITE_RAM_UI+1), x	; set tile number
  TYA
  CLC
  ADC #GAMEOVER_TEXTX		; get x-pos, offset by Y
  STA (SPRITE_RAM_UI+3), x	; set x-pos
  LDA #GAMEOVER_TEXTY		; get y-pos
  STA (SPRITE_RAM_UI+0), x	; set y-pos
  INY						; increment Y by 8 pixels
  INY
  INY
  INY
  INY
  INY
  INY
  INY
  RTS
GameOverLetterDone:
  
  ; Check and update highscore
  LDA highscore+0
  CMP playerscore+0
  BCC HighScoreUpdate		; if highscore MSB < playerscore MSB, update highscore
  BNE HighScoreEnd			; but, if highscore MSB > playerscore MSB, skip update
							; (past this point, we know highscore MSB <= playerscore MSB)
  LDA highscore+1
  CMP playerscore+1
  BCC HighScoreUpdate		; else if highscore LSB < playerscore LSB, update highscore
  JMP HighScoreEnd			; else, skip update
  
HighScoreUpdate:
  LDA playerscore+0
  STA highscore+0
  LDA playerscore+1
  STA highscore+1
  
HighScoreEnd:

  ; Update high score display
  JSR UpdateHighScoreDisplay
  
  
  LDA #sfx_Gameover	; play Game Over SFX
  JSR sound_load
  
  JSR sound_pause	; run sound engine pause script
  
  
  RTS  ; end of EngineGameOverInit
  
  
EngineGameOver:
  ;; Main game over loop
  JMP GameEngineDone
 
 
;;;;;;;;;;;;;;;;;;
  
EnginePlayingInit_P:
; Initial script to run when gamestate switches from Pause to Playing
EnginePlayingInit_P_LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address (palette area)
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address (palette area)
  LDX #$00              ; start out at 0
EnginePlayingInit_P_LoadPltsLoop:
  LDA playpalette, x
  STA $2007             ; write to PPU
  INX
  CPX #32			    ; run 32 times for 16 bg colors and 16 sprite colors
  BNE EnginePlayingInit_P_LoadPltsLoop

;; PPU clean up (must be called, or background will skip for a frame on unpause)
  LDA #$00
  STA $2005		; first write: no horizontal scrolling
  LDA ppu_scroll
  STA $2005		; second write: advance vertical scroll
  LDA ppu_cr1   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  ORA ppu_nametable	; swap Nametables 0 and 2
  STA $2000
  LDA ppu_cr2   ; enable sprites, enable background, no clipping on left side
  STA $2001

  
  ; clear Pause letters
  LDX #S_LETTER1
  JSR ClearUIElement
  LDX #S_LETTER2
  JSR ClearUIElement
  LDX #S_LETTER3
  JSR ClearUIElement
  LDX #S_LETTER4
  JSR ClearUIElement
  LDX #S_LETTER5
  JSR ClearUIElement
  LDX #S_LETTER6
  JSR ClearUIElement
  
  
  LDA #sfx_Unpause	; play Unpause SFX
  JSR sound_load
  
  JSR sound_unpause	; run sound engine unpause script
  
  
  RTS
  
  
  
EnginePlayingInit_T:
; Initial script to run when gamestate switches from Title Screen to Playing

  ; disable sprite and background visibility to properly unlock PPU RAM
  LDA ppu_cr2
  EOR #%00011000
  STA $2001

  LDA #0
  STA ppu_scroll		; reset background scrolling position
  LDA #$00
  STA ppu_nametable

;; Load palettes ;;
EnginePlayingInit_T_LoadPlts:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address (palette area)
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address (palette area)
  LDX #$00              ; start out at 0
EnginePlayingInit_T_LoadPltsLoop:
  LDA playpalette, x
  STA $2007             ; write to PPU
  INX
  CPX #32			    ; run 32 times for 16 bg colors and 16 sprite colors
  BNE EnginePlayingInit_T_LoadPltsLoop


;; Load background nametables ;;
EnginePlayingInit_T_LoadBG:
  ;; write first Playing nametable to $2000 (mirrored on $2400)
  LDA $2002					; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006					; write the high byte of $2000 address (nametable 0)
  LDA #$00
  STA $2006					; write the low byte of $2000 address (nametable 0)
  LDX #$00
  LDY #$00
  
  LDA #LOW(background0)		; load 2-byte address of background0 into indr_low and indr_high
  STA indr_low				;   for indirect addressing
  LDA #HIGH(background0)
  STA indr_high
  
  JSR LoadNametable
  ;; second Playing nametable has already been written in EngineTitleInit.

  LDA #$00
  STA playerinvnc					; reset invincibility frames
  STA playerscore+0
  STA playerscore+1					; reset score
  
;; Show game sprites ;;
  LDX #$00  
EngineTitleInit_ShowSpritesLoop:
  LDA ($0200+2), x					; load attributes byte of sprite data
  EOR #%00100000					; XOR to set Priority bit to 1 (display behind BG)
  STA ($0200+2), x
  INX								; advance to next sprite
  INX
  INX
  INX
  CPX #(SPRITE_RAM_TITL - $0200)	; only hide sprites up until Title sprites are reached
  BNE EngineTitleInit_ShowSpritesLoop
  
  ; Hide cursor sprite
  ;   since cursor may be already hidden when game starts, we need to force the priority to 1
  LDA (SPRITE_RAM_TITL+S_CURSOR+2)
  AND #%11011111					; clear priority bit
  ORA #%00100000
  STA (SPRITE_RAM_TITL+S_CURSOR+2)
  
  
  ; Move obstacles to starting positions
  JSR Obst_Init
  
  JSR Obst_RandomXGen	; get new random x-pos
  STA obst1_x			; set new x-pos of obstacle
  JSR prng				; advance rng to make next position different
  JSR Obst_RandomXGen	; get new random x-pos
  STA obst2_x			; set new x-pos of obstacle
  JSR prng				; advance rng to make next position different
  JSR Obst_RandomXGen	; get new random x-pos
  STA obst3_x			; set new x-pos of obstacle
  
  JSR Obst_MoveX  ; move x-positions of all sprites in each obstacle to match obstN_x's
  JSR Obst_MoveY  ; move y-positions of all sprites in each obstacle to match obstN_y's
  
  ; Move character to starting position
  LDA #PLAYERX_INIT
  STA playerx
  LDA #PLAYERY_INIT
  STA playery
  JSR CharMoveSpritesUpdate  ; shift character sprites to match (playerx, playery) position
  
  ; Move number1 sprite into position to be the lives counter
  LDA #UI_LIVESX
  STA (SPRITE_RAM_UI+S_NUMBER1+3)	; set x-pos
  LDA #UI_LIVESY
  STA (SPRITE_RAM_UI+S_NUMBER1+0)	; set y-pos
  LDA #T_3
  STA (SPRITE_RAM_UI+S_NUMBER1+1)	; set sprite tile
  
  ; Move icon1 sprite into position to be the lives icon
  LDA #(UI_LIVESX-12)
  STA (SPRITE_RAM_UI+S_ICON1+3)	; set x-pos
  LDA #UI_LIVESY
  STA (SPRITE_RAM_UI+S_ICON1+0)	; set y-pos
  LDA #T_LIVES
  STA (SPRITE_RAM_UI+S_ICON1+1)	; set sprite tile
  
  
  ; Move number2/3/4 sprites into position to be the 3-digit score counter
  ; number2
  LDA #UI_SCOREX
  STA (SPRITE_RAM_UI+S_NUMBER2+3)	; set x-pos
  LDA #UI_SCOREY
  STA (SPRITE_RAM_UI+S_NUMBER2+0)	; set y-pos
  LDA #T_0
  STA (SPRITE_RAM_UI+S_NUMBER2+1)	; set sprite tile
  ; number3
  LDA #(UI_SCOREX+8)
  STA (SPRITE_RAM_UI+S_NUMBER3+3)	; set x-pos
  LDA #UI_SCOREY
  STA (SPRITE_RAM_UI+S_NUMBER3+0)	; set y-pos
  LDA #T_0
  STA (SPRITE_RAM_UI+S_NUMBER3+1)	; set sprite tile
  ; number4
  LDA #(UI_SCOREX+16)
  STA (SPRITE_RAM_UI+S_NUMBER4+3)	; set x-pos
  LDA #UI_SCOREY
  STA (SPRITE_RAM_UI+S_NUMBER4+0)	; set y-pos
  LDA #T_0
  STA (SPRITE_RAM_UI+S_NUMBER4+1)	; set sprite tile
  
  ; Move number5/6/7 sprites into position to be the 3-digit high score display
  ; number5
  LDA #UI_HISCOREX
  STA (SPRITE_RAM_UI+S_NUMBER5+3)	; set x-pos
  LDA #UI_HISCOREY
  STA (SPRITE_RAM_UI+S_NUMBER5+0)	; set y-pos
  LDA #%00000001
  STA (SPRITE_RAM_UI+S_NUMBER5+2)	; set sprite palette
  ; number6
  LDA #(UI_HISCOREX+8)
  STA (SPRITE_RAM_UI+S_NUMBER6+3)	; set x-pos
  LDA #UI_HISCOREY
  STA (SPRITE_RAM_UI+S_NUMBER6+0)	; set y-pos
  LDA #%00000001
  STA (SPRITE_RAM_UI+S_NUMBER6+2)	; set sprite palette
  ; number7
  LDA #(UI_HISCOREX+16)
  STA (SPRITE_RAM_UI+S_NUMBER7+3)	; set x-pos
  LDA #UI_HISCOREY
  STA (SPRITE_RAM_UI+S_NUMBER7+0)	; set y-pos
  LDA #%00000001
  STA (SPRITE_RAM_UI+S_NUMBER7+2)	; set sprite palette
  
  JSR UpdateHighScoreDisplay		; call to set tiles (if a high score is set, this will re-display it)
  
  
  
;; Set background attribute table and music to match game mode ;;
EnginePlayingInit_T_Mode1Check:		; Day
  LDA gamemode
  CMP #$00
  BNE EnginePlayingInit_T_Mode2Check
  JSR ReplaceAttTables_DayMode
  LDA #sng_DayMode
  STA sound_cur_song
  JSR sound_load
EnginePlayingInit_T_Mode2Check:		; Sunset
  LDA gamemode
  CMP #$01
  BNE EnginePlayingInit_T_Mode3Check
  JSR ReplaceAttTables_SunsetMode
  LDA #sng_SunsetMode
  STA sound_cur_song
  JSR sound_load
EnginePlayingInit_T_Mode3Check:		; Night
  LDA gamemode
  CMP #$02
  BNE EnginePlayingInit_T_ModeDone
  JSR ReplaceAttTables_NightMode
  LDA #sng_NightMode
  STA sound_cur_song
  JSR sound_load
  
EnginePlayingInit_T_ModeDone:
  
  
  
  RTS  ; end of EnginePlayingInit_T

  
  
EnginePlaying:

;; Advance clocks
  JSR ClockStep
  
;; Difficulty update
  LDA difficultyflag			; check difficultyflag. if not 0, don't update
  BNE DifficultyCurveNoChange	; if flag is 0, we can't raise difficulty any more, so quit
  
  LDX clockSecs+3		; check LSB of clockSecs (max of 256 seconds = 4.27 minutes)
DifficultyCurve1:
  CPX #45				; after 45 seconds, increase difficulty to 1=Medium
  BNE DifficultyCurve2
  LDA #$01
  STA difficulty		; update difficulty variable
DifficultyCurve2:
  CPX #120				; after 2 minutes, increase difficulty to 2=Hard
  BNE DifficultyCurve3
  LDA #$02
  STA difficulty		; update difficulty variable
DifficultyCurve3:
  CPX #210				; after 3.5 minutes, increase difficulty to 3=Insane
  BNE DifficultyCurveNoChange
  LDA #$01
  STA difficultyflag	; set difficulty flag to turn off difficulty increase
  LDA #$03
  STA difficulty		; update difficulty variable
DifficultyCurveNoChange:
  
  
;; Advance background scroll slower than foreground sprites for parallax effect
  LDA difficulty
  CMP #$02
  BCC ScrollSpeedLow	; branch if difficulty < 2 (0 or 1)
  CMP #$02
  BCS ScrollSpeedHigh	; branch if difficulty >= 2 (2 or 3)
  
ScrollSpeedLow:
  LDA clock100
  LDY #2	; load A and Y for mod
  JSR mod	; increment state if clock100 % 2 == 0
  CMP #0
  BNE ScrollSpeedLowDone
  INC ppu_scroll	; scroll every two frames
ScrollSpeedLowDone:
  JMP ScrollDone
  
ScrollSpeedHigh:
  INC ppu_scroll	; scroll every frame
ScrollSpeedHighDone:

ScrollDone:
  
  
CharMove:
; Process buttons and update movement

  ; Reset obstacle update flags
  LDA #$00
  STA obst1_update
  STA obst2_update
  STA obst3_update


ButtonLeft:
  LDA buttons
  BIT MASK_LEFT		; get Left button
  BEQ ButtonRight	; skip if bit is 0 (Z=1)
  LDA playerx
  LDX difficulty	; get difficulty index
  SEC
  SBC diff_playerspeed, x	; subtract this difficulty's speed factor
  STA playerx
  LDA #$00
  STA playerfacing
ButtonRight:
  LDA buttons
  BIT MASK_RIGHT	; get Right button
  BEQ ButtonUp		; skip if bit is 0 (Z=1)
  LDA playerx
  LDX difficulty	; get difficulty index
  CLC
  ADC diff_playerspeed, x	; add this difficulty's speed factor
  STA playerx
  LDA #$01
  STA playerfacing
ButtonUp:			;; reenable to allow up/down movement
  ;LDA buttons
  ;BIT MASK_UP		; get Up button
  ;BEQ ButtonDown	; skip if bit is 0 (Z=1)
  ;LDA playery
  ;SEC
  ;SBC #PLAYERBASESPEED
  ;STA playery
ButtonDown:			;; reenable to allow up/down movement
  ;LDA buttons
  ;BIT MASK_DOWN		; get Down button
  ;BEQ ButtonDone	; skip if bit is 0 (Z=1)
  ;LDA playery
  ;CLC
  ;ADC #PLAYERBASESPEED
  ;STA playery
ButtonDone:
  
; Check collisions of player with boundary
BoundaryCheckLeft:
  ; If WALL_LEFT is exceeded, playerx is set to WALL_LEFT.
  LDA playerx
  CMP #WALL_LEFT
  BCS BCLDone
  LDA #WALL_LEFT ; set if A<WALL_LEFT (C=0)
  STA playerx
BCLDone:
BoundaryCheckRight:
  ; If WALL_RIGHT is exceeded, playerx is set to WALL_RIGHT.
  LDA playerx
  CMP #WALL_RIGHT
  BCC BCRDone
  LDA #WALL_RIGHT ; set if A>=WALL_RIGHT (C=1)
  STA playerx
BCRDone:
BoundaryCheckTop:
  ; If WALL_TOP is exceeded, playery is set to WALL_TOP.
  LDA playery
  CMP #WALL_TOP
  BCS BCTDone
  LDA #WALL_TOP ; set if A<WALL_TOP (C=0)
  STA playery
BCTDone:
BoundaryCheckBottom:
  ; If WALL_BOTTOM is exceeded, playery is set to WALL_BOTTOM.
  LDA playery
  CMP #WALL_BOTTOM
  BCC BCBDone
  LDA #WALL_BOTTOM ; set if A>=WALL_BOTTOM (C=1)
  STA playery
BCBDone:
  
  
  
  ; jump ahead to JSR into CharMoveSpritesUpdate
  JMP CharMoveSpritesJump
  
RowLoop:
  ; put y-pos in 3rd byte
  CLC			; get ready for add
  TYA			; transfer Y to A (pixel offset)
  ADC playery	; add playerx to pixel offset in A
  STA (SPRITE_RAM_CHAR+0), x  ; store final y-pos of sprite tile
  RTS

ColLoop:
  ; put x-pos in 0th byte
  CLC			; get ready for add
  TYA			; transfer Y to A (pixel offset)
  ADC playerx	; add playery to pixel offset in A
  STA (SPRITE_RAM_CHAR+3), x  ; store final y-pos of sprite tile
  RTS

CharMoveSpritesUpdate:
  ; COL1
  LDY #COL1
  LDX #S_LEFTARM
  JSR ColLoop
  LDX #S_LEFTSHLDR
  JSR ColLoop
  LDX #S_WAISTLEFT
  JSR ColLoop
  LDX #S_LEFTFOOT
  JSR ColLoop
  
  ; COL2
  LDY #COL2
  LDX #S_HEAD
  JSR ColLoop
  LDX #S_CHEST
  JSR ColLoop
  LDX #S_WAISTMID
  JSR ColLoop
  LDX #S_LEGS
  JSR ColLoop
  
  ; COL3
  LDY #COL3
  LDX #S_RIGHTARM
  JSR ColLoop
  LDX #S_RIGHTSHLDR
  JSR ColLoop
  LDX #S_WAISTRIGHT
  JSR ColLoop
  LDX #S_RIGHTFOOT
  JSR ColLoop
  
  ; ROW1
  LDY #ROW1
  LDX #S_LEFTARM
  JSR RowLoop
  LDX #S_HEAD
  JSR RowLoop
  LDX #S_RIGHTARM
  JSR RowLoop
  
  ; ROW2
  LDY #ROW2
  LDX #S_LEFTSHLDR
  JSR RowLoop
  LDX #S_CHEST
  JSR RowLoop
  LDX #S_RIGHTSHLDR
  JSR RowLoop
  
  ; ROW3
  LDY #ROW3
  LDX #S_WAISTLEFT
  JSR RowLoop
  LDX #S_WAISTMID
  JSR RowLoop
  LDX #S_WAISTRIGHT
  JSR RowLoop
  
  ; ROW4
  LDY #ROW4
  LDX #S_LEFTFOOT
  JSR RowLoop
  LDX #S_LEGS
  JSR RowLoop
  LDX #S_RIGHTFOOT
  JSR RowLoop
  
  RTS
  
  
CharMoveSpritesJump:
  
;; Shift character sprites to match (playerx, playery) position
  JSR CharMoveSpritesUpdate

Anim_Arms:
; Animate arms in the sequence [0/4 -> 1/3 -> 2/2 -> 3/1 -> 4/0 -> 3/1 -> 2/2 -> 1/3 -> ...]

;; Advance animation frame every 10 game frames
  LDA clock100
  LDY #10	; load A and Y for mod
  JSR mod
  CMP #0
  BEQ Anim_ArmsStep
  JMP Anim_ArmsDone  ; if no change is needed, move on to next task
Anim_ArmsStep:
  INC playerarm_animframe
  LDA playerarm_animframe
  CMP #$08					; check if animframe > 5, i.e. animation cycle has finished
  BNE Anim_ArmsNoReset
  LDA #$00
  STA playerarm_animframe	; if cycle is over, reset animframe to 0
Anim_ArmsNoReset:

  
;; Change sprite data to update animation

; Get animation frame and store matching tile in Y
  LDA playerarm_animframe
Anim_ArmsFrame0:
  CMP #$00
  BNE Anim_ArmsFrame1
  LDX #T_ANIM_ARM0
  LDY #T_ANIM_ARM4
  JMP Anim_ArmsFrameDone
Anim_ArmsFrame1:
  CMP #$01
  BNE Anim_ArmsFrame2
  LDX #T_ANIM_ARM1
  LDY #T_ANIM_ARM3
  JMP Anim_ArmsFrameDone
Anim_ArmsFrame2:
  CMP #$02
  BNE Anim_ArmsFrame3
  LDX #T_ANIM_ARM2
  LDY #T_ANIM_ARM2
  JMP Anim_ArmsFrameDone
Anim_ArmsFrame3:
  CMP #$03
  BNE Anim_ArmsFrame4
  LDX #T_ANIM_ARM3
  LDY #T_ANIM_ARM1
  JMP Anim_ArmsFrameDone
Anim_ArmsFrame4:
  CMP #$04
  BNE Anim_ArmsFrame5
  LDX #T_ANIM_ARM4
  LDY #T_ANIM_ARM0
  JMP Anim_ArmsFrameDone
Anim_ArmsFrame5:
  CMP #$05
  BNE Anim_ArmsFrame6
  LDX #T_ANIM_ARM3
  LDY #T_ANIM_ARM1
  JMP Anim_ArmsFrameDone
Anim_ArmsFrame6:
  CMP #$06
  BNE Anim_ArmsFrame7
  LDX #T_ANIM_ARM2
  LDY #T_ANIM_ARM2
  JMP Anim_ArmsFrameDone
Anim_ArmsFrame7:
  CMP #$07
  BNE Anim_ArmsFrameDone
  LDX #T_ANIM_ARM1
  LDY #T_ANIM_ARM3
  JMP Anim_ArmsFrameDone
  
Anim_ArmsFrameDone:

  STX (SPRITE_RAM_CHAR+S_RIGHTARM+1)	; replace left arm sprite tile with tile in Y
  STY (SPRITE_RAM_CHAR+S_LEFTARM+1)		; replace left arm sprite tile with tile in Y
  
  
Anim_ArmsDone:


Anim_Facing:
; Animate head and legs according to playerfacing direction

  LDY #$00  			; compare to 0 (facing left)
  CPY playerfacing
  
  BEQ Anim_FacingLeft	; If facing left, go to Anim_FacingLeft
  JMP Anim_FacingRight	; Otherwise, go to Anim_FacingRight
  
Anim_FacingLeft:
  LDX #S_HEAD
  LDA (SPRITE_RAM_CHAR+2), x
  ORA #%01000000		; set head hflip to 1 (face left, playerfacing=0)
  STA (SPRITE_RAM_CHAR+2), x
  
  LDX #S_LEFTFOOT
  LDA (SPRITE_RAM_CHAR+2), x
  ORA #%01000000 		; set left foot hflip to 1 (face left, playerfacing=0)
  STA (SPRITE_RAM_CHAR+2), x
  LDX #S_LEGS
  LDA (SPRITE_RAM_CHAR+2), x
  ORA #%01000000 		; set legs hflip to 1 (face left, playerfacing=0)
  STA (SPRITE_RAM_CHAR+2), x
  LDX #S_RIGHTFOOT
  LDA (SPRITE_RAM_CHAR+2), x
  ORA #%01000000 		; set right foot hflip to 1 (face left, playerfacing=0)
  STA (SPRITE_RAM_CHAR+2), x

  LDX #S_RIGHTFOOT		; swap tiles for left and right feet when facing left
  LDA #T_LEFTFOOT
  STA (SPRITE_RAM_CHAR+1), x
  LDX #S_LEFTFOOT
  LDA #T_RIGHTFOOT
  STA (SPRITE_RAM_CHAR+1), x
  
  JMP Anim_FacingDone
  
Anim_FacingRight:
  LDX #S_HEAD
  LDA (SPRITE_RAM_CHAR+2), x
  AND #%10111111		; set head hflip to 0 (face right, playerfacing=1)
  STA (SPRITE_RAM_CHAR+2), x
  
  LDX #S_LEFTFOOT
  LDA (SPRITE_RAM_CHAR+2), x
  AND #%10111111 		; set left foot hflip to 0 (face right, playerfacing=1)
  STA (SPRITE_RAM_CHAR+2), x
  LDX #S_LEGS
  LDA (SPRITE_RAM_CHAR+2), x
  AND #%10111111 		; set legs hflip to 0 (face right, playerfacing=1)
  STA (SPRITE_RAM_CHAR+2), x
  LDX #S_RIGHTFOOT
  LDA (SPRITE_RAM_CHAR+2), x
  AND #%10111111 		; set right foot hflip to 0 (face right, playerfacing=1)
  STA (SPRITE_RAM_CHAR+2), x

  LDX #S_RIGHTFOOT		; match tiles with feet sprites when facing right
  LDA #T_RIGHTFOOT
  STA (SPRITE_RAM_CHAR+1), x
  LDX #S_LEFTFOOT
  LDA #T_LEFTFOOT
  STA (SPRITE_RAM_CHAR+1), x
  
  JMP Anim_FacingDone
Anim_FacingDone:


Anim_Bobbing:
;; Bob character up and down slightly
  LDA clock256		; load A and Y for mod
  LDY #8			; run every Y frames
  JSR mod
  CMP #0
  BNE Anim_BobbingDone
  
  INC playerbobstate 	; runs from 0-15
  LDA playerbobstate
  CMP #16
  BNE Anim_Bobbing_NoReset
  LDA #0
  STA playerbobstate	; if 16 is reached, reset to 0
  
Anim_Bobbing_NoReset:
  LDA playerbobstate
  CMP #8
  BCS Anim_Bobbing_Up	; if playerbobstate >= 8, go up
  INC playery			; if playerbobstate < 8, go down
  JMP Anim_BobbingDone
Anim_Bobbing_Up
  DEC playery
Anim_BobbingDone:
  
  
  JMP Anim_Flash
Anim_FlashLoopToggle:
  LDA (SPRITE_RAM_CHAR+2), x
  EOR #%00100000		; XOR to toggle Priority bit
  STA (SPRITE_RAM_CHAR+2), x
  INX
  INX
  INX
  INX
  CPX #(12*4)			; repeat for 12 character sprites
  BNE Anim_FlashLoopToggle
  RTS
Anim_FlashLoopSet:
  LDA (SPRITE_RAM_CHAR+2), x
  AND #%11011111		; AND to set Priority bit to 0
  STA (SPRITE_RAM_CHAR+2), x
  INX
  INX
  INX
  INX
  CPX #(12*4)			; repeat for 12 character sprites
  BNE Anim_FlashLoopSet
  RTS
  
Anim_Flash:
;; Flash character sprites while invincibility frames are active (after obstacle collision)
  LDA playerinvnc		; check player's invincibility frames
  BEQ Anim_FlashDone	; if invnc is not active (at 0), end
  CMP #$01
  BEQ Anim_FlashFinal	; if player has 1 invnc frame left, force visibility just in case
  LDY #10				; otherwise, toggle player sprite visibility every Y invnc frames
  JSR mod
  CMP #0
  BNE Anim_FlashDone	; no toggle if it hasn't been Y frames
  LDX #$00
  JSR Anim_FlashLoopToggle
  JMP Anim_FlashDone
Anim_FlashFinal:
  LDX #$00
  JSR Anim_FlashLoopSet
Anim_FlashDone:


;;; Obstacles ;;;
Obst:

; Check release timers. If timer is 0, move obstacle up.
  LDY #$00			; reset loop counter
  LDX #S_OBST1_S1	; start with first sprite in obstacle
  LDA obst1_release ; check counter
  BEQ Obst1_Go		; if counter is 0, move up
  DEC obst1_release ; if not, decrease counter and hold obstacle back
  JMP Obst1_Done
Obst1_Go:
  JSR Obst_MoveUp	; move up
  STA obst1_y		; update y-pos variable to match
Obst1_Done:

  LDY #$00			; reset loop counter
  LDX #S_OBST2_S1	; start with first sprite in obstacle
  LDA obst2_release ; check counter
  BEQ Obst2_Go		; if counter is 0, move up
  DEC obst2_release ; if not, decrease counter and hold obstacle back
  JMP Obst2_Done
Obst2_Go:
  JSR Obst_MoveUp	; move up
  STA obst2_y		; update y-pos variable to match
Obst2_Done:
  
  LDY #$00			; reset loop counter
  LDX #S_OBST3_S1	; start with first sprite in obstacle
  LDA obst3_release ; check counter
  BEQ Obst3_Go		; if counter is 0, move up
  DEC obst3_release ; if not, decrease counter and hold obstacle back
  JMP Obst3_Done
Obst3_Go:
  JSR Obst_MoveUp	; move up
  STA obst3_y		; update y-pos variable to match
Obst3_Done:

  
  
;; Set update flags for each obstacle if y-pos of obstacle is >=$F8 (wrap-around)
 ; Need to check a range ($F8-$FF) to account for obstacle speed. (This means obstacle will often move multiple times.)
 ; Otherwise, y-pos may never equal a given number and obstacle will skip update.
Obst_Wrap:

  LDX #S_OBST1_S1				; set offset for next obstacle
Obst_WrapUpdate1:
  LDA (SPRITE_RAM_OBST+0), x	; check y-pos of obstacle
  CMP #UI_CUTOFF				; check if y-pos <= UI_CUTOFF (20px range)
  BCS Obst_WrapNoUpdate1 		; if not, don't set update flag
  LDA #$01
  STA obst1_update 				; if so, set update flag
Obst_WrapNoUpdate1:
  
  LDX #S_OBST2_S1				; set offset for next obstacle
Obst_WrapUpdate2:
  LDA (SPRITE_RAM_OBST+0), x	; check y-pos of obstacle
  CMP #UI_CUTOFF				; check if y-pos <= UI_CUTOFF (20px range)
  BCS Obst_WrapNoUpdate2 		; if not, don't set update flag
  LDA #$01
  STA obst2_update 				; if so, set update flag
Obst_WrapNoUpdate2:
  
  LDX #S_OBST3_S1				; set offset for next obstacle
Obst_WrapUpdate3:
  LDA (SPRITE_RAM_OBST+0), x	; check y-pos of obstacle
  CMP #UI_CUTOFF				; check if y-pos <= UI_CUTOFF (20px range)
  BCS Obst_WrapNoUpdate3 		; if not, don't set update flag
  LDA #$01
  STA obst3_update 				; if so, set update flag
Obst_WrapNoUpdate3:
  
  LDA obst1_update				; combine all update flags
  ORA obst2_update				; A=1 if any update is set
  ORA obst3_update				; A=0 if all updates are unset
  CMP #$00
  BEQ Obst_WrapSkip				; if no update flag was set, skip generation
  
  
;; For any obstacle above UI_CUTOFF, change x-pos to a random new position and reset y-pos
Obst_Random:

  LDA obst1_update		; Z=1 (equal) is set if flag is 0 (unset)
  BEQ Obst_RandomDone1	; skip if flag is unset
  JSR Obst_RandomXGen	; get new random x-pos
  STA obst1_x			; set new x-pos of obstacle
  LDA #OBST_RESETY
  STA obst1_y
Obst_RandomDone1:
  
  LDA obst2_update		; Z=1 (equal) is set if flag is 0 (unset)
  BEQ Obst_RandomDone2	; skip if flag is unset
  JSR Obst_RandomXGen	; get new random x-pos
  STA obst2_x			; set new x-pos of obstacle
  LDA #OBST_RESETY
  STA obst2_y
Obst_RandomDone2:

  LDA obst3_update		; Z=1 (equal) is set if flag is 0 (unset)
  BEQ Obst_RandomDone3	; skip if flag is unset
  JSR Obst_RandomXGen	; get new random x-pos
  STA obst3_x			; set new x-pos of obstacle
  LDA #OBST_RESETY
  STA obst3_y
Obst_RandomDone3:


;; Move x/y positions of all sprites in each obstacle to match obstN_x/obstN_y's
  JSR Obst_MoveX		; only run when updates are made above
  JSR Obst_MoveY		; only run when updates are made above
  
  
Obst_WrapSkip:

; TODO: hold obstacle back for x frames??


; decrease invincibility counter (happens on every frame)
  LDA playerinvnc		; check invincibility counter
  BEQ Obst_InvncAtZero	; if it's 0, leave it
  SEC
  SBC #1				; otherwise, decrease it
  STA playerinvnc
Obst_InvncAtZero:
  
  
  JMP Obst_Collision

  
;; If collision happened, update lives and/or gamestate
Obst_CollisionConfirmed:

  ; check invincibility counter
  LDA playerinvnc
  CMP #0								; check if invincibility has run out
  BEQ Obst_CollisionConfirmedNoInvnc	; if so, update lives/gamestate
  JMP Obst_CollisionConfirmedDone		; if not, skip updates
Obst_CollisionConfirmedNoInvnc:

  LDA playerlives
  SEC
  SBC #1					; decrease lives by 1
  STA playerlives
  
  LDA #sfx_Obst				; play SFX
  JSR sound_load
  
  LDA #PLAYERINVNC			; reset invincibility counter
  STA playerinvnc
  
  ; Update lives number sprite
  LDA (SPRITE_RAM_UI+S_NUMBER1+1)	; check currently used tile
  SEC
  SBC #1							; change to previous tile, decreasing number displayed by 1
  STA (SPRITE_RAM_UI+S_NUMBER1+1)	; store new tile number
  
  ; Go to Game Over state if lives run out
  LDA playerlives
  CMP #$00
  BNE Obst_CollisionConfirmedDone	; if player still has lives, don't gameover
  
  JSR EngineGameOverInit			; run Game Over init
  LDA #STATEGAMEOVER
  STA gamestate						; update gamestate
  
Obst_CollisionConfirmedDone:
  RTS


;; Check if any obstacle y-pos has reached character y-pos
  ; For some reason, when y-positions are equal, character still displays about 2 pixels above obstacle.
  ; Also, character moves up and down in 1px increments, but obstacle moves in >=1px increments, so y-positions may miss.
  ; Finally, we want collision to also happen if character moves into obstacle, anywhere within 8px feet sprites.
  ; Thus, we will trigger a collision check when obsty+2 < playery <= obsty+2+8
Obst_CollisionYCheck:
  CLC
  ADC #2						; add 2 to obsty
  CMP playery
  BCS Obst_CollisionYCheckDone	; if obsty+2 >= playery, no potential collision
  CLC
  ADC #8						; add another 8 to obsty to make obsty+2+8
  CMP playery
  BCC Obst_CollisionYCheckDone	; if playery > obsty+2+8, no potential collision 
  ; if no branching occured, there is a potential collision
  LDY #$01						; set Y=1 to indicate potential collision
Obst_CollisionYCheckDone:
  RTS
  

Obst_Collision:
  LDY #$00					; potential collision flag (0=no, 1=yes)
  
  LDA obst1_y				; load obsty into A for checking
  JSR Obst_CollisionYCheck
  CPY #$01
  BEQ Obst_CollisionXCheck1	; if flag is set, check x-positions
  
  LDA obst2_y				; load obsty into A for checking
  JSR Obst_CollisionYCheck
  CPY #$01
  BEQ Obst_CollisionXCheck2	; if flag is set, check x-positions
  
  LDA obst3_y				; load obsty into A for checking
  JSR Obst_CollisionYCheck
  CPY #$01
  BEQ Obst_CollisionXCheck3	; if flag is set, check x-positions
  
  
  JMP Obst_CollisionDone  ; if no obstacle is near player y-pos, skip checking
  
;; Check if obstacles (near player's y-pos) are within x-pos range
  ; Collision occurs if playerx is within the 32 pixel span of the obstacle, plus a buffer of 8 pixels on each side.
  ; i.e. if obstx-8 <= playerx <= obstx+32+8
Obst_CollisionXCheck1:  	; check collision for obst1
  LDA playerx
  CLC
  ADC #8					; add 8 to playerx
  CMP obst1_x
  BCC Obst_CollisionDone	; if obstx-8 > playerx, no collision
  LDA playerx
  SEC
  SBC #40					; subtract (32+8)=40 from playerx
  BCS Obst_CollisionXCheck1Cont		; C=1 as long as no borrow occured in subtraction (underflow)
  LDA #$00					; if subtraction resulted in an underflow (player was too close to left of screen), set comparison to 0
Obst_CollisionXCheck1Cont:
  CMP obst1_x
  BCS Obst_CollisionDone	; if playerx >= obstx+32+8, no collision
  JSR Obst_CollisionConfirmed
  JMP Obst_CollisionDone
  
Obst_CollisionXCheck2:  	; check collision for obst2
  LDA playerx
  CLC
  ADC #8					; add 8 to playerx
  CMP obst2_x
  BCC Obst_CollisionDone	; if obstx-8 > playerx, no collision
  LDA playerx
  SEC
  SBC #40					; subtract (32+8)=40 from playerx
  BCS Obst_CollisionXCheck2Cont		; C=1 as long as no borrow occured in subtraction (underflow)
  LDA #$00					; if subtraction resulted in an underflow (player was too close to left of screen), set comparison to 0
Obst_CollisionXCheck2Cont:
  CMP obst2_x
  BCS Obst_CollisionDone	; if playerx >= obstx+32+8, no collision
  JSR Obst_CollisionConfirmed
  JMP Obst_CollisionDone
  
Obst_CollisionXCheck3:  	; check collision for obst3
  LDA playerx
  CLC
  ADC #8					; add 8 to playerx
  CMP obst3_x
  BCC Obst_CollisionDone	; if obstx-8 > playerx, no collision
  LDA playerx
  SEC
  SBC #40					; subtract (32+8)=40 from playerx
  BCS Obst_CollisionXCheck3Cont		; C=1 as long as no borrow occured in subtraction (underflow)
  LDA #$00					; if subtraction resulted in an underflow (player was too close to left of screen), set comparison to 0
Obst_CollisionXCheck3Cont:
  CMP obst3_x
  BCS Obst_CollisionDone	; if playerx >= obstx+32+8, no collision
  JSR Obst_CollisionConfirmed
  JMP Obst_CollisionDone
  
Obst_CollisionDone:
  
  
  
;; Pickup activation check: Extra life
Pkup_LifeCheck:
  LDA pkuplife_flag
  CMP #$01					; check if life pickup flag is set
  BNE Pkup_LifeCheckRoll	; if not, roll to set it
  LDX #S_PKUPLIFE			; if so, load extra life offset into X
  JSR Pkup_Move				; move pickup upward
  STA pkuplife_y			; also update variable
  
  CMP #UI_CUTOFF			; compare new y-pos (set in A from Pkup_Move) to UI_CUTOFF to check for wrap
  BCS Pkup_LifeCheckDone	; if y-pos > UI_CUTOFF, pickup is still on-screen, so continue to collision check
  
  LDA #$00					; otherwise, a wrap occured. 
  STA pkuplife_flag			; reset pickup flag
  LDA #PKUPLIFEY_INIT		; reset pickup y-pos
  STA (SPRITE_RAM_PKUP+S_PKUPLIFE+0)
  STA pkuplife_y			; also update variable
  JSR Pkup_RandomXGen		; set a new random pickup x-pos
  STA (SPRITE_RAM_PKUP+S_PKUPLIFE+3)
  STA pkuplife_x			; also update variable
  JMP Pkup_LifeCheckDone	; done (skip roll)
  
Pkup_LifeCheckRoll:
  LDA clock60					; roll once per second (60 frames)
  BNE Pkup_LifeCheckDone
  LDA rng						; 256 possibilities
  LDX difficulty				; get difficulty index
  LDY diff_lifespawnrate, x		; mod by N (in lookup table)
  JSR mod						; 1/N chance of spawning every second
  CMP #0
  BNE Pkup_LifeCheckDone   		; if not 0, don't set flag
  LDA #$01						; if mod was 0 (1/N chance), set pickup flag
  STA pkuplife_flag
Pkup_LifeCheckDone:

;; Pickup activation check: Coin
Pkup_CoinCheck:
  LDA pkupcoin_flag
  CMP #$01					; check if coin pickup flag is set
  BNE Pkup_CoinCheckRoll	; if not, roll to set it
  LDX #S_PKUPCOIN			; load extra coin offset into X
  JSR Pkup_Move				; move pickup upward
  STA pkupcoin_y			; also update variable
  
  CMP #UI_CUTOFF			; compare new y-pos (set in A from Pkup_Move) to UI_CUTOFF to check for wrap
  BCS Pkup_CoinCheckDone	; if y-pos is > UI_CUTOFF, pickup is still on-screen, so continue to collision check
  
  LDA #$00					; otherwise, a wrap occured. 
  STA pkupcoin_flag			; reset pickup flag
  LDA #PKUPCOINY_INIT		; reset pickup y-pos
  STA (SPRITE_RAM_PKUP+S_PKUPCOIN+0)
  STA pkupcoin_y			; also update variable
  JSR prng					; advance prng to prevent overlap with other pickups
  JSR Pkup_RandomXGen		; set a new random pickup x-pos
  STA (SPRITE_RAM_PKUP+S_PKUPCOIN+3)
  STA pkupcoin_x			; also update variable
  JMP Pkup_CoinCheckDone	; done (skip roll)
  
Pkup_CoinCheckRoll:
  LDA clock60					; roll once per second (60 frames)
  BNE Pkup_CoinCheckDone
  JSR prng						; advance prng to prevent overlap with other pickups
  LDA rng						; 256 possibilities
  LDX difficulty				; get difficulty index
  LDY diff_coinspawnrate, x		; mod by N (in lookup table)
  JSR mod						; 1/N chance of spawning every second
  CMP #0
  BNE Pkup_CoinCheckDone   		; if not 0, don't set flag
  LDA #$01						; if mod was 0 (1/N chance), set pickup flag
  STA pkupcoin_flag
Pkup_CoinCheckDone:


  JMP Pkup_CollisionStart
  
  
;; If collision happened, check each pickup collision and act accordingly
Pkup_CollisionConfirmed:
  
;; Extra life
  ; Check for extra life pickup
  LDA pkupcollisions
  BIT PKUP_COLL_LIFE		; returns Z=0 (not equal) if flag is set
  BNE Pkup_CollisionConf_Life
  JMP Pkup_CollisionConf_LifeDone

Pkup_CollisionConf_Life:
  LDA #$00
  STA pkuplife_flag			; reset flag
  JSR Pkup_RandomXGen		; since a wrap will not happen, force x-pos randomization
  STA pkuplife_x
  STA (SPRITE_RAM_PKUP+S_PKUPLIFE+3)
  LDA #PKUPLIFEY_INIT
  STA pkuplife_y			; reset y-pos
  STA (SPRITE_RAM_PKUP+S_PKUPLIFE+0)

  LDA playerlives
  CLC
  ADC #1					; increase lives by 1
  STA playerlives
  
  LDA #sfx_Life				; play SFX
  JSR sound_load
  
  ; If lives go past 9, fix at 9
  LDA playerlives
  CMP #$0A
  BNE Pkup_CollisionConf_LifeUpdate	; if player has less than 9 lives, don't fix and update sprite
  LDA #$09
  STA playerlives
  JMP Pkup_CollisionConf_LifeDone	; end
  
Pkup_CollisionConf_LifeUpdate:
  ; Update lives number sprite
  LDA (SPRITE_RAM_UI+S_NUMBER1+1)	; check currently used tile
  CLC
  ADC #1							; change to previous tile, decreasing number displayed by 1
  STA (SPRITE_RAM_UI+S_NUMBER1+1)	; store new tile number
  JMP Pkup_CollisionConf_LifeDone	; end
Pkup_CollisionConf_LifeDone:


;; Coin
; Check for coin pickup
  LDA pkupcollisions
  BIT PKUP_COLL_COIN		; returns Z=0 (not equal) if flag is set
  BNE Pkup_CollisionConf_Coin
  JMP Pkup_CollisionConf_CoinDone

Pkup_CollisionConf_Coin:
  LDA #$00
  STA pkupcoin_flag			; reset flag
  JSR prng					; advance prng to prevent overlap with other pickups
  JSR Pkup_RandomXGen		; since a wrap will not happen, force x-pos randomization
  STA pkupcoin_x			; reset x-pos
  STA (SPRITE_RAM_PKUP+S_PKUPCOIN+3)
  LDA #PKUPCOINY_INIT
  STA pkupcoin_y			; reset y-pos
  STA (SPRITE_RAM_PKUP+S_PKUPCOIN+0)
  
  LDA #sfx_Coin				; play SFX
  JSR sound_load
  
  INC playerscore+1 		; increase score by 1
  LDA playerscore+1
  CMP #$00					; check if LSB has wrapped to 0
  BNE Pkup_ScoreMSBUpdateSkip
  INC playerscore+0			; if so, increment MSB
Pkup_ScoreMSBUpdateSkip:

  ; Increment score display
  JSR IncrementScoreDisplay
  
Pkup_CollisionConf_CoinDone:
  
Pkup_CollisionConfirmedDone:
  RTS
  
;; Check if any pickup y-pos has reached character y-pos
  ; For some reason, when y-positions are equal, character still displays about 2 pixels above pickup.
  ; Also, character moves up and down in 1px increments, but pickup moves in >=1px increments, so y-positions may miss.
  ; Finally, we want collision to also happen if any part of character moves into pickup, anywhere within 32px height.
  ; Thus, we will trigger a collision check when pkupy+2 < playery <= pkupy+2+32
Pkup_CollisionYCheck:
  CLC
  ADC #2						; add 2 to pkupy
  CMP playery
  BCS Pkup_CollisionYCheckDone	; if pkupy+2 >= playery, no potential collision
  CLC
  ADC #32						; add another 32 to pkupy to make pkupy+2+32
  CMP playery
  BCC Pkup_CollisionYCheckDone	; if playery > pkupy+2+32, no potential collision 
  ; if no branching occured, there is a potential collision
  LDY #$01						; set Y=1 to indicate potential collision
Pkup_CollisionYCheckDone:
  RTS
  
;; Check if pickups (near player's y-pos) are within x-pos range
  ; Collision occurs if playerx is within the 8 pixel span of the pickup, plus a buffer of 8 pixels on each side.
  ; i.e. if pkupx-8 <= playerx <= pkupx+8+8
Pkup_CollisionXCheck:  			; check collision for pkuplife
  SEC
  SBC #8						; subtract 8 from pkupx
  BCS Pkup_CollisionXCheckUF	; C=1 as long as no borrow occured in subtraction (underflow)
  LDA #$00						; if subtraction resulted in an underflow (pkup was too close to left of screen), set comparison to $00
Pkup_CollisionXCheckUF:
  CMP playerx
  BCS Pkup_NoCollision			; if pkupx-8 > playerx, no collision
  CLC
  ADC #24						; add 8 back to pkupx, and another (8+8) to make pkupx+8+8
  BCC Pkup_CollisionXCheckOF	; C=0 as long as no carry occured in addition (overflow)
  LDA #$FF						; if addition resulted in an overflow (pkup was too close to right of screen), set comparison to $FF
Pkup_CollisionXCheckOF:
  CMP playerx
  BCC Pkup_NoCollision			; if playerx >= pkupx+8+8, no collision
  TXA							; transfer pickup collision mask to A
  ORA pkupcollisions			; set collision bit flag for this pickup (passed through in X)
  STA pkupcollisions			; (flags for other pickups are not unset)
Pkup_NoCollision:
  RTS
  

Pkup_CollisionStart:
; Collision bits:
; pkupcollisions = %LC000000 where:
;   L = Extra life collision
;   C = Coin collision
  LDA #%00000000
  STA pkupcollisions			; clear all collision flags
  
; Collision checking for extra life pickup
Pkup_LifeCollision:
  LDY #$00						; potential collision flag (0=no, 1=yes)
  LDA pkuplife_y				; load pkupy into A for checking
  JSR Pkup_CollisionYCheck		; check if this pickup is within y-pos range of player
  CPY #$01
  BNE Pkup_LifeCollisionDone	; if flag is not set, skip check
  LDA pkuplife_x				; otherwise, prepare A and X
  LDX PKUP_COLL_LIFE
  JSR Pkup_CollisionXCheck  	; check collision
Pkup_LifeCollisionDone:

; Collision checking for coin pickup
Pkup_CoinCollision:
  LDY #$00						; potential collision flag (0=no, 1=yes)
  LDA pkupcoin_y				; load pkupy into A for checking
  JSR Pkup_CollisionYCheck		; check if this pickup is within y-pos range of player
  CPY #$01
  BNE Pkup_CoinCollisionDone	; if flag is not set, skip check
  LDA pkupcoin_x				; otherwise, prepare A and X
  LDX PKUP_COLL_COIN
  JSR Pkup_CollisionXCheck  	; check collision
Pkup_CoinCollisionDone:

  LDA pkupcollisions			; check collision flags
  BEQ Pkup_AllCollisionsDone	; if no flags are set, end
  JSR Pkup_CollisionConfirmed	; if any collision flags are set, go to collision handling
  
Pkup_AllCollisionsDone:
  
  
  
  JMP GameEngineDone

;;;;;;;;;;;;;;;;;;




;;; NMI Subroutines ;;;

;; Read 8 bits of controller 1 state and store in 'buttons'
ReadController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadControllerLoop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL buttons      ; bit0 <- Carry
  DEX
  BNE ReadControllerLoop
  RTS

;; Overwrite attribute tables for background coresponding to game mode
 ; Write attribute table to $23C0, overwriting attribute table of nametable 0
 ;   and (if needed) write to $2BC0, overwriting attribute table of nametable 2
ReplaceAttTables_DayMode:
  LDA $2002					; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006					; write the high byte of $23C0 address (nametable 0)
  LDA #$C0
  STA $2006					; write the low byte of $23C0 address (nametable 0)
  LDX #$00
  JSR ReplaceAttTables_DayModeLoop
  LDA gamestate				; if we are on Title screen, we only need to update nametable 0
  CMP #STATETITLE			; otherwise, run once more to update nametable 2
  BEQ ReplaceAttTables_DayModeDone
  LDA $2002					; read PPU status to reset the high/low latch
  LDA #$2B
  STA $2006					; write the high byte of $2BC0 address (nametable 2)
  LDA #$C0
  STA $2006					; write the low byte of $2BC0 address (nametable 2)
  LDX #$00
  JSR ReplaceAttTables_DayModeLoop
ReplaceAttTables_DayModeDone:
  LDA #$00		; writing to port $2006 overwrites scroll bits. rewriting them here to force no scrolling.
  STA $2005		; first write: no horizontal scrolling
  STA $2005		; second write: no vertical scrolling
  RTS
ReplaceAttTables_DayModeLoop:
  LDA background_att0, x			; load attr table for Day mode
  STA $2007							; write to PPU
  INX
  CPX #64
  BNE ReplaceAttTables_DayModeLoop	; stop when 64 bytes have been written
  RTS
  
ReplaceAttTables_SunsetMode:
  LDA $2002					; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006					; write the high byte of $23C0 address (nametable 0)
  LDA #$C0
  STA $2006					; write the low byte of $23C0 address (nametable 0)
  LDX #$00
  JSR ReplaceAttTables_SunsetModeLoop
  LDA gamestate				; if we are on Title screen, we only need to update nametable 0
  CMP #STATETITLE			; otherwise, run once more to update nametable 2
  BEQ ReplaceAttTables_SunsetModeDone
  LDA $2002					; read PPU status to reset the high/low latch
  LDA #$2B
  STA $2006					; write the high byte of $2BC0 address (nametable 2)
  LDA #$C0
  STA $2006					; write the low byte of $2BC0 address (nametable 2)
  LDX #$00
  JSR ReplaceAttTables_SunsetModeLoop
ReplaceAttTables_SunsetModeDone:
  LDA #$00		; writing to port $2006 overwrites scroll bits. rewriting them here to force no scrolling.
  STA $2005		; first write: no horizontal scrolling
  STA $2005		; second write: no vertical scrolling
  RTS
ReplaceAttTables_SunsetModeLoop:
  LDA background_att1, x			; load attr table for Sunset mode
  STA $2007							; write to PPU
  INX
  CPX #64
  BNE ReplaceAttTables_SunsetModeLoop	; stop when 64 bytes have been written
  RTS
  
ReplaceAttTables_NightMode:
  LDA $2002					; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006					; write the high byte of $23C0 address (nametable 0)
  LDA #$C0
  STA $2006					; write the low byte of $23C0 address (nametable 0)
  LDX #$00
  JSR ReplaceAttTables_NightModeLoop
  LDA gamestate				; if we are on Title screen, we only need to update nametable 0
  CMP #STATETITLE			; otherwise, run once more to update nametable 2
  BEQ ReplaceAttTables_NightModeDone
  LDA $2002					; read PPU status to reset the high/low latch
  LDA #$2B
  STA $2006					; write the high byte of $2BC0 address (nametable 2)
  LDA #$C0
  STA $2006					; write the low byte of $2BC0 address (nametable 2)
  LDX #$00
  JSR ReplaceAttTables_NightModeLoop
ReplaceAttTables_NightModeDone:
  LDA #$00		; writing to port $2006 overwrites scroll bits. rewriting them here to force no scrolling.
  STA $2005		; first write: no horizontal scrolling
  STA $2005		; second write: no vertical scrolling
  RTS
ReplaceAttTables_NightModeLoop:
  LDA background_att2, x			; load attr table for Day mode
  STA $2007							; write to PPU
  INX
  CPX #64
  BNE ReplaceAttTables_NightModeLoop	; stop when 64 bytes have been written
  RTS

  
  
;; Load a nametable file into PPU RAM
 ; Loop using indirect indexed addressing mode to load a large amount of data (1KB of nametable data)
LoadNametable:
  LDA [indr_low], Y					; load data using indirect indexed addressing (Y must be used in this mode)
  STA $2007							; write to PPU
  INY
  CPY #$FF
  BNE LoadNametable  ; branch when Y reaches $FF = 255 (255 bytes have been loaded).
  LDA [indr_low], Y					; since the loop ends before Y=$FF is used, run one more time to get to 256 bytes.
  STA $2007							; write to PPU
  INY								; increment Y to overflow back to $00 and prepare for next round
  INX								; increment X now that the first of four blocks of 256 bytes is done
  INC indr_high						; move offset to next 256-byte block of memory
  CPX #$04
  BNE LoadNametable	; when X=$04, 4 rounds of 256 are complete for a full 1024 bytes read.
  RTS
  
;; Clear letters and numbers from screen
 ; Load desired S_LETTERN or S_NUMBERN into X before calling
ClearUIElement:
  LDA #$FF
  STA (SPRITE_RAM_UI+0), x	; move offscreen
  STA (SPRITE_RAM_UI+3), x
  RTS
  

;; Initialize starting positions and timers for all obstacles.
 ; Sets position variables and timers for initial spacing.
Obst_Init:
  LDA #OBST1_X_INIT
  STA obst1_x
  LDA #OBST2_X_INIT
  STA obst2_x
  LDA #OBST3_X_INIT
  STA obst3_x
  
  ; Rather than starting obstacles at Y_INIT positions, they will all start at bottom of screen
  ;   and the initial values will determine their initial release time (so they will retain their initial spacing).
  LDA #OBST_RESETY
  STA obst1_y
  LDA #OBST_RESETY
  STA obst2_y
  LDA #OBST_RESETY
  STA obst3_y
  LDA #$00				; release immediately
  STA obst1_release
  LDA #OBST_REL_INIT	; release after offset
  STA obst2_release
  LDA #OBST_REL_INIT
  ASL A					; release after offset*2
  STA obst3_release
  RTS
  
;; Move y-positions of all sprites in an obstacle up by obstspeed (obstacle passed in through X)
Obst_MoveUp:
  LDY difficulty
  LDA diff_obstspeed, y
  STA tempvar1					; store obstacle speed
  LDY #0
  ; runs 4 times, once for each sprite in obstacle object
Obst_MoveUpLoop:
  LDA (SPRITE_RAM_OBST+0), x	; load current obst y-pos
  SEC
  SBC tempvar1					; decrease y-pos (up) by speed (stored in temp variable)
  STA (SPRITE_RAM_OBST+0), x	; update sprite y-pos
  INX  							; increment x 4 times to move to next sprite RAM location
  INX
  INX
  INX
  INY  							; increment loop counter
  CPY #4						; loop 4 times for 4 sprites
  BEQ Obst_MoveUpDone
  JMP Obst_MoveUpLoop
Obst_MoveUpDone:
  RTS
  
;; Move x-positions of all sprites in each obstacle to match obstN_x's
Obst_MoveX:
  LDY #$00
  LDX #S_OBST1_S1
  LDA obst1_x
  JSR Obst_MoveXLoop
  LDY #$00
  LDX #S_OBST2_S1
  LDA obst2_x
  JSR Obst_MoveXLoop
  LDY #$00
  LDX #S_OBST3_S1
  LDA obst3_x
  JSR Obst_MoveXLoop
  RTS
Obst_MoveXLoop:
  STA (SPRITE_RAM_OBST+3), x
  CLC
  ADC #$08		; move 8 pixels to place next sprite
  INX			; increment x to next sprite data position
  INX
  INX
  INX
  INY
  CPY #4		; run 4 times for 4 sprites
  BNE Obst_MoveXLoop
  RTS
  
;; Move y-positions of all sprites in each obstacle to match obstN_y's
Obst_MoveY:
  LDY #$00
  LDX #S_OBST1_S1
  LDA obst1_y
  JSR Obst_MoveYLoop
  LDY #$00
  LDX #S_OBST2_S1
  LDA obst2_y
  JSR Obst_MoveYLoop
  LDY #$00
  LDX #S_OBST3_S1
  LDA obst3_y
  JSR Obst_MoveYLoop
  RTS
Obst_MoveYLoop:
  STA (SPRITE_RAM_OBST+0), x
  INX			; increment x to next sprite data position
  INX
  INX
  INX
  INY
  CPY #4		; run 4 times for 4 sprites
  BNE Obst_MoveYLoop
  RTS
  
;; Generate a new x-pos for an obstacle
 ; Generates new rng's until one is found in allowed range. 
 ; This method is used instead of modding or snapping x-pos to range to avoid bias.
Obst_RandomXGenNext:
  JSR prng					; advance rng in case this one doesn't work
Obst_RandomXGen:
  LDA rng					; get rng (256 possibilites)
  CMP #(256-32)				; check to see if rng is within allowed range (no further than 32 pixels from right edge)
  BCS Obst_RandomXGenNext	; if rng >= 224, get next rng and try again
  RTS
  
;; Update y-position of a Pickup (pickup passed in through X, returns new y-pos in A)
Pkup_Move:
  LDA (SPRITE_RAM_PKUP+0), x	; load a pickup sprite with offset X (set before calling)
  LDY difficulty
  SEC
  SBC diff_pickupspeed, y		; decrease y-pos by pkupspeed (depends on difficulty)
  STA (SPRITE_RAM_PKUP+0), x
  RTS
  
;; Generate a new x-pos for a pickup
 ; Generates new rng's until one is found in allowed range. 
 ; This method is used instead of modding or snapping x-pos to range to avoid bias.
Pkup_RandomXGenNext:
  JSR prng					; advance rng in case this one doesn't work
Pkup_RandomXGen:
  LDA rng					; get rng (256 possibilites)
  CMP #(256-8)				; check to see if rng is within allowed range (no further than 8 pixels from right edge)
  BCS Pkup_RandomXGenNext	; if rng >= 248, get next rng and try again
  RTS
  
IncrementScoreDisplay:
  INC (SPRITE_RAM_UI+S_NUMBER4+1)		; increment 3rd digit tile number
  LDA (SPRITE_RAM_UI+S_NUMBER4+1)
  CMP #(T_9+1)							; check if 3rd digit went past 9
  BNE IncrementScoreDisplayDone			; if not, we're done
  
  LDA #T_0
  STA (SPRITE_RAM_UI+S_NUMBER4+1)		; if so, reset 3rd digit to 0...
  INC (SPRITE_RAM_UI+S_NUMBER3+1)		; and increment 2nd digit tile number
  LDA (SPRITE_RAM_UI+S_NUMBER3+1)
  CMP #(T_9+1)							; check if 2nd digit went past 9
  BNE IncrementScoreDisplayDone			; if not, we're done
  
  LDA #T_0
  STA (SPRITE_RAM_UI+S_NUMBER3+1)		; if so, reset 2nd digit to 0...
  INC (SPRITE_RAM_UI+S_NUMBER2+1)		; and increment 1st digit tile number
  LDA (SPRITE_RAM_UI+S_NUMBER2+1)
  CMP #(T_9+1)							; check if 1st digit went past 9
  BNE IncrementScoreDisplayDone			; if not, we're done
  
  LDA #T_0								; if so (unlikely), reset all digits to 0, reset playerscore, and store 999 in highscore
  STA (SPRITE_RAM_UI+S_NUMBER4+1)
  STA (SPRITE_RAM_UI+S_NUMBER3+1)
  STA (SPRITE_RAM_UI+S_NUMBER2+1)
  LDA #$00
  STA playerscore+0
  STA playerscore+1
  
  LDA #$03
  STA highscore+0
  LDA #$E7
  STA highscore+1
  
IncrementScoreDisplayDone:
  RTS
  
  
UpdateHighScoreDisplay:
; Convert high score to decimal
  LDA highscore+0
  STA temp_bin+1		; put MSB of highscore in temp variable
  LDA highscore+1
  STA temp_bin+0		; put LSB of highscore in temp variable
  JSR BinaryToDecimal	; convert highscore to decimal, returns in temp_dec

  LDA #T_0				; load first number tile index
  CLC
  ADC temp_dec+0		; offset to get matching digit
  STA (SPRITE_RAM_UI+S_NUMBER7+1)
  
  LDA #T_0				; load first number tile index
  CLC
  ADC temp_dec+1		; offset to get matching digit
  STA (SPRITE_RAM_UI+S_NUMBER6+1)
  
  LDA #T_0				; load first number tile index
  CLC
  ADC temp_dec+2		; offset to get matching digit
  STA (SPRITE_RAM_UI+S_NUMBER5+1)

UpdateHighScoreDisplayDone:
  RTS
  
  
;; Advance Clocks ;;
ClockStep:
; Update clock100
  INC clock100
  LDA clock100	; roll over to 0 when 99 is reached
  CMP #100
  BNE Clock100Skip
  LDA #0
  STA clock100
Clock100Skip:
  
; Update clock60  
  INC clock60
  LDA clock60	; roll over to 0 when 59 is reached
  CMP #60
  BNE Clock60Skip
  LDA #0
  STA clock60
Clock60Skip:
  
; Update clockSecs
; clockSecs is a 4 byte variable and will wrap after 4294967295 seconds (136.2 years)
  LDA clock60
  CMP #0
  BNE ClockSecsSkip		; if clock60 is not 0, skip all increments
  INC clockSecs+3		; otherwise, increment 4th byte (LSB) of clockSecs
  
  LDA clockSecs+3		; check if 4th byte has wrapped to $00
  BNE ClockSecsSkip		; if not, end
  INC clockSecs+2		; if so, increment 3rd byte
  
  LDA clockSecs+2		; check if 3rd byte has wrapped to $00
  BNE ClockSecsSkip		; if not, end
  INC clockSecs+1		; if so, increment 2nd byte
  
  LDA clockSecs+1		; check if 2nd byte has wrapped to $00
  BNE ClockSecsSkip		; if not, end
  INC clockSecs+0		; if so, increment 1st byte (MSB)
  
ClockSecsSkip:
  
; Update clock256
  INC clock256	; automatically rolls over on overflow
  
  RTS
  
;;; Subroutine Library ;;;

; Modulo operator.
; Load A and Y prior to calling. Returns A%Y in A.
mod:
  SEC			; set carry (C=1) to clear borrow
modloop:
  STY y_mod 	; store Y in memory address y_mod
  SBC y_mod		; subtract A - Y
  BCS modloop	; loops if subtraction DID NOT produce a borrow (C=1)
  ADC y_mod		; add Y back to A to get last positive modulus
  RTS

; prng (https://wiki.nesdev.com/w/index.php/Random_number_generator)
;
; 16-bit Galois linear feedback shift register with polynomial $002D.
; Returns a random 8-bit number in A/rng (0-255).
; Period: 65535
; Execution time: ~125 cycles
prng:
	LDX #8     ; iteration count (generates 8 bits)
	LDA rng+0
prng_step1:
	ASL A       ; shift the register
	ROL rng+1
	BCC prng_step2
	EOR #$2D   ; apply XOR feedback whenever a 1 bit is shifted out
prng_step2:
	DEX
	BNE prng_step1
	STA rng+0
	CMP #0     ; reload flags
	RTS

; Convert a 2-byte (16-bit) binary/hex number to a 5-byte decimal number (1 byte per decimal digit)
; Requires two variables: temp_dec (5 bytes), temp_bin (2 bytes).
;   temp_bin must be set before call. Result will be returned in temp_dec.
;   Note: Both variables are little endian. Pass temp_bin = LSB, MSB. Returns temp_dec = d5, d4, d3, d2, d1 (digits)
BinaryToDecimal:
   LDA #$00 
   STA temp_dec+0
   STA temp_dec+1
   STA temp_dec+2
   STA temp_dec+3
   STA temp_dec+4
   LDX #$10 
BitLoop:
   ASL temp_bin+0 
   ROL temp_bin+1
   LDY temp_dec+0
   LDA BinTable, y 
   ROL a
   STA temp_dec+0
   LDY temp_dec+1
   LDA BinTable, y 
   ROL a
   STA temp_dec+1
   LDY temp_dec+2
   LDA BinTable, y 
   ROL a
   STA temp_dec+2
   LDY temp_dec+3
   LDA BinTable, y 
   ROL a
   STA temp_dec+3
   ROL temp_dec+4
   DEX 
   BNE BitLoop 
   RTS 
BinTable:
   .db $00, $01, $02, $03, $04, $80, $81, $82, $83, $84
	

;;;; Lookup tables ;;;;
  .bank 2
  .org $DA00
  
; Values for difficulty settings
diff_playerspeed:
  .db PLAYERBASESPEED		; speed at difficulty 0
  .db PLAYERBASESPEED		; speed at difficulty 1
  .db PLAYERBASESPEED + 1	; speed at difficulty 2
  .db PLAYERBASESPEED + 2	; speed at difficulty 3

diff_obstspeed:
  .db OBSTBASESPEED			; speed at difficulty 0
  .db OBSTBASESPEED + 1
  .db OBSTBASESPEED + 2
  .db OBSTBASESPEED + 3
  
diff_pickupspeed:
  .db $01	; speed at difficulty 0
  .db $01
  .db $02
  .db $03
  
diff_coinspawnrate:
  .db 4		; 1/N chance of spawning at difficulty 0
  .db 3
  .db 2
  .db 2
  
diff_lifespawnrate:
  .db 32	; 1/N chance of spawning at difficulty 0
  .db 28
  .db 24
  .db 16
  
  
  
  
  .bank 3
  .org $E000
  ;; Load palettes
  ;; First color in each 4-color block is used as the transparency color, usually left as $0F.
  ;; Any sprite pixel assigned the transparency color will let background pass through.
playpalette:
  ; palettes to load when playing
  ;   day				sunset			  night				title screen (unused)
  .db $0F,$11,$31,$30,  $0F,$17,$28,$38,  $0F,$3F,$3D,$2D,  $0F,$27,$37,$17				; background palette
  ;   char 1			char 2/obstacles  pickups			UI (numbers and letters)
  .db $0F,$07,$01,$08,  $0F,$07,$3E,$00,  $0F,$38,$16,$06,  $0F,$27,$3F,$17				; sprite palette
  
titlepalette:
  ; palettes to load on title screen
  ; Easter egg: push B to cycle colors.
  ;   day mode	     	sunset mode 	  night mode		extra color (purple)
  .db $0F,$21,$31,$11,  $0F,$27,$37,$17,  $0F,$2D,$20,$0D,  $0F,$22,$32,$12				; background palette
  .db $0F,$21,$31,$11,  $0F,$27,$37,$17,  $0F,$2D,$20,$0D,  $0F,$22,$32,$12				; sprite palette
  
pausepalette:
  ; palettes to load when game is paused
  .db $0F,$10,$00,$20,  $0F,$10,$00,$20,  $0F,$10,$00,$20,  $0F,$10,$00,$20				; background palette
  .db $0F,$00,$2D,$20,  $0F,$00,$2D,$20,  $0F,$00,$3D,$20,  $0F,$27,$3F,$17				; sprite palette
  
gameoverpalette:
  ; palettes to load on game over screen
  .db $0F,$06,$00,$2D,  $0F,$06,$00,$2D,  $0F,$06,$00,$2D,  $0F,$06,$00,$2D				; background palette
  .db $0F,$3F,$3F,$3F,  $0F,$3F,$06,$06,  $0F,$3F,$2D,$30,  $0F,$27,$3F,$17				; sprite palette

sprites:
;;;; NOTE: Update SPRITE_RAM and NUMSPRITES constants after any changes. ;;;;

;; UI Sprite Slots: Starting at $0200 (must come first to have highest priority)
  ; Number slots (up to 8 numbers can be displayed at once).
  .db $FF, $00, %00000011, $FF   ; UI - number slot 1 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - number slot 2 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - number slot 3 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - number slot 4 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - number slot 5 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - number slot 6 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - number slot 7 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - number slot 8 [palette3]
  
  ; Letter slots (up to 10 letters can be displayed at once).
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 1 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 2 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 3 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 4 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 5 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 6 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 7 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 8 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 9 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - letter slot 10 [palette3]
  
  ; Icon slots (up to 6 icons can be displayed at once).
  .db $FF, $00, %00000011, $FF   ; UI - icon slot 1 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - icon slot 2 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - icon slot 3 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - icon slot 4 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - icon slot 5 [palette3]
  .db $FF, $00, %00000011, $FF   ; UI - icon slot 6 [palette3]

;; Obstacle Sprites: Starting at $0260 (if this changes, update constants)
  .db OBST_RESETY, $04, %00000001, (OBST1_X_INIT+0)   ;obstacle1, s1 [palette1]
  .db OBST_RESETY, $05, %00000001, (OBST1_X_INIT+8)   ;obstacle1, s2 [palette1]
  .db OBST_RESETY, $06, %00000001, (OBST1_X_INIT+16)  ;obstacle1, s3 [palette1]
  .db OBST_RESETY, $07, %00000001, (OBST1_X_INIT+24)  ;obstacle1, s4 [palette1]
  .db OBST_RESETY, $14, %00000001, (OBST2_X_INIT+0)   ;obstacle2, s1 [palette1]
  .db OBST_RESETY, $15, %00000001, (OBST2_X_INIT+8)   ;obstacle2, s2 [palette1]
  .db OBST_RESETY, $16, %00000001, (OBST2_X_INIT+16)  ;obstacle2, s3 [palette1]
  .db OBST_RESETY, $17, %00000001, (OBST2_X_INIT+24)  ;obstacle2, s4 [palette1]
  .db OBST_RESETY, $24, %00000001, (OBST3_X_INIT+0)   ;obstacle3, s1 [palette1]
  .db OBST_RESETY, $25, %00000001, (OBST3_X_INIT+8)   ;obstacle3, s2 [palette1]
  .db OBST_RESETY, $26, %00000001, (OBST3_X_INIT+16)  ;obstacle3, s3 [palette1]
  .db OBST_RESETY, $27, %00000001, (OBST3_X_INIT+24)  ;obstacle3, s4 [palette1]
  
;; Character Sprites: Starting at $0290 (if this changes, update constants)
    ; vertical (Y)		   tile attr       horizontal (X)
  .db (PLAYERY_INIT+ROW1), $00, %00000000, (PLAYERX_INIT+COL1)  ;sprites, 0 - left arm (left relative to screen)
  .db (PLAYERY_INIT+ROW1), $01, %00000001, (PLAYERX_INIT+COL2)  ;sprites, 4 - head [palette1]
  .db (PLAYERY_INIT+ROW1), $02, %01000000, (PLAYERX_INIT+COL3)  ;sprites, 8 - right arm (hflip for animation)
  .db (PLAYERY_INIT+ROW2), $10, %00000000, (PLAYERX_INIT+COL1)  ;sprites, 12 - left shoulder
  .db (PLAYERY_INIT+ROW2), $11, %00000000, (PLAYERX_INIT+COL2)  ;sprites, 16 - chest
  .db (PLAYERY_INIT+ROW2), $12, %00000000, (PLAYERX_INIT+COL3)  ;sprites, 20 - right shoulder
  .db (PLAYERY_INIT+ROW3), $20, %00000000, (PLAYERX_INIT+COL1)  ;sprites, 24 - waist left
  .db (PLAYERY_INIT+ROW3), $21, %00000000, (PLAYERX_INIT+COL2)  ;sprites, 28 - waist mid
  .db (PLAYERY_INIT+ROW3), $22, %00000000, (PLAYERX_INIT+COL3)  ;sprites, 32 - waist right
  .db (PLAYERY_INIT+ROW4), $30, %00000000, (PLAYERX_INIT+COL1)  ;sprites, 36 - left foot
  .db (PLAYERY_INIT+ROW4), $31, %00000000, (PLAYERX_INIT+COL2)  ;sprites, 40 - legs (between feet)
  .db (PLAYERY_INIT+ROW4), $32, %00000000, (PLAYERX_INIT+COL3)  ;sprites, 44 - right foot

;; Pickup Sprites: Starting at $02C0 (if this changes, update constants)
  .db PKUPLIFEY_INIT, $83, %00000010, PKUPLIFEX_INIT   ; Pickup, extralife [palette2]
  .db PKUPCOINY_INIT, $82, %00000011, PKUPCOINX_INIT   ; Pickup, coin [palette3]

;; Title Sprites: Starting at $02C8 (if this changes, update constants)
  .db CURSOR_DAY, $C1, %00000000, $5A  ; Title cursor (y-pos: $8F for Day mode, $A7 for Sunset mode, $BF for Night mode)
  
;; Sprite constants (memory offsets)
S_LEFTARM 		= 0
S_HEAD 			= 4
S_RIGHTARM 		= 8
S_LEFTSHLDR		= 12
S_CHEST			= 16
S_RIGHTSHLDR	= 20
S_WAISTLEFT		= 24
S_WAISTMID		= 28
S_WAISTRIGHT	= 32
S_LEFTFOOT		= 36
S_LEGS			= 40
S_RIGHTFOOT		= 44

;; Obstacle offsets
S_OBST1_S1	= 0  ; three sprites are reserved, so three obstacles can be on-screen at one time
S_OBST1_S2	= 4
S_OBST1_S3	= 8
S_OBST1_S4	= 12
S_OBST2_S1	= 16
S_OBST2_S2	= 20
S_OBST2_S3	= 24
S_OBST2_S4	= 28
S_OBST3_S1	= 32
S_OBST3_S2	= 36
S_OBST3_S3	= 40
S_OBST3_S4	= 44

;; Pickup offsets
S_PKUPLIFE	= 0
S_PKUPCOIN	= 4

;; UI offsets
; To display text or numbers, first load a digit or letter into one of the 8 sprite slots,
;   then render the sprite.
S_NUMBER1	= 0
S_NUMBER2	= 4
S_NUMBER3	= 8
S_NUMBER4	= 12
S_NUMBER5	= 16
S_NUMBER6	= 20
S_NUMBER7	= 24
S_NUMBER8	= 28
S_LETTER1	= 32
S_LETTER2	= 36
S_LETTER3	= 40
S_LETTER4	= 44
S_LETTER5	= 48
S_LETTER6	= 52
S_LETTER7	= 56
S_LETTER8	= 60
S_LETTER9	= 64
S_LETTER10	= 68
S_ICON1		= 72
S_ICON2		= 76
S_ICON3		= 80
S_ICON4		= 84
S_ICON5		= 88
S_ICON6		= 92

;; Title offsets
S_CURSOR  = 0

;; Character tile numbers
T_LEFTARM 		= $00
T_RIGHTARM 		= $02
T_HEAD 			= $01
T_LEFTFOOT		= $30
T_RIGHTFOOT		= $32

T_ANIM_ARM0		= $00  ; same as leftarm
T_ANIM_ARM1		= $03
T_ANIM_ARM2		= $13
T_ANIM_ARM3		= $23
T_ANIM_ARM4		= $33


;; Obstacle tile numbers
T_OBST1			= $04  ; starting address
T_OBST2			= $14
T_OBST3			= $24
T_OBST4			= $34

;; UI tile numbers
T_LIVES = $F8

;; Number and letter sprite tile numbers
T_0	= $D0
T_1	= $D1 
T_2	= $D2
T_3	= $D3
T_4	= $D4
T_5	= $D5
T_6	= $D6
T_7	= $D7
T_8	= $D8
T_9	= $D9
T_A	= $DA
T_B	= $DB
T_C	= $DC
T_D	= $DD
T_E	= $DE
T_F	= $DF
T_G	= $E0
T_H	= $E1
T_I	= $E2
T_J	= $E3
T_K	= $E4
T_L	= $E5
T_M	= $E6
T_N	= $E7
T_O	= $E8
T_P	= $E9
T_Q	= $EA
T_R	= $EB
T_S	= $EC
T_T	= $ED
T_U	= $EE
T_V	= $EF
T_W	= $F0
T_X	= $F1
T_Y	= $F2
T_Z	= $F3


;; Pixel offsets for each row (y) and col (x) in character sprite
ROW1	= -32  ;top
ROW2	= -24
ROW3	= -16
ROW4	= -8   ;bottom

COL1	= -12  ;left
COL2	= -4
COL3	= 4    ;right

; load 3x 1KB name/attribute table files (generated by YY-CHR) into PRG-ROM
background0:
  .incbin "falling_bg0.nam"
background1:
  .incbin "falling_bg1.nam"

background_title:
  .incbin "falling_bg_title.nam"

background_att0:  ; Day mode ($00 = %00000000, all tiles use palette $00)
  .incbin "falling_bg_att0_day.nam"	; attribute table (64 bytes) only, for switching BG palette
background_att1:  ; Sunset mode ($55 = %01010101, all tiles use palette $01)
  .incbin "falling_bg_att1_sunset.nam"	; attribute table (64 bytes) only, for switching BG palette
background_att2:  ; Night mode ($AA = %10101010, all tiles use palette $10)
  .incbin "falling_bg_att2_night.nam"	; attribute table (64 bytes) only, for switching BG palette
  
;; Define interrupt vectors ;;
  .org $FFFA     ; first of the three vectors starts here
  .dw NMI        ; when an NMI happens (once per frame if enabled) the processor will jump to the label NMI:
  .dw RESET      ; when the processor first turns on or is reset, it will jump to the label RESET:
  .dw 0          ; external interrupt IRQ unused
  
  
;;;;;;;;;;;;;;  

  ; Import sound engine code (starting at $8000)
  .bank 0
  .org $8000
  .include "falling_soundengine.asm"

;;;;;;;;;;;;;;
  
  ; stores sprite/bg data in bank 4 (CHR-ROM)
  .bank 4
  
  ; Pattern table 0 - Sprites ($0000-$0FFF), Pattern table 1 - Background ($1000-$1FFF)
  .org $0000
  .incbin "falling.chr"   ;include 8KB graphics file


