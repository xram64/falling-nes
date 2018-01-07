themeTitleTempo = $50  ; about 140bpm


;; Stream header format:
 ; 
 ; Stream number (MUSIC_SQ1, MUSIC_SQ2, MUSIC_TRI, MUSIC_NOI, SFX_1, or SFX_2)
 ; Stream status (1=enabled, 0=disabled: If stream is disabled, skip to next header)
 ; Channel number
 ; Channel settings (Squares: Duty cycle %DD110000, Triangle: $80, Noise: $30)
 ; Volume envelope (offset for pointer table)
 ; Note stream pointer (points to label with notes below)
 ; Tempo

themeTitle_header:
  .db $04	; number of streams
  
  .db MUSIC_SQ1
  .db $01
  .db SQUARE_1
  .db %01110000
  .db ve_fadeout2
  .dw themeTitle_square1
  .db themeTitleTempo
  
  .db MUSIC_SQ2
  .db $01
  .db SQUARE_2
  .db %10110000
  .db ve_stac1
  .dw themeTitle_square2
  .db themeTitleTempo
  
  .db MUSIC_TRI
  .db $01
  .db TRIANGLE
  .db $80
  .db ve_muted  ; silent for intro 
  .dw themeTitle_tri
  .db themeTitleTempo
  
  .db MUSIC_NOI
  .db $01
  .db NOISE
  .db $30
  .db ve_drumhat2
  .dw themeTitle_noi
  .db themeTitleTempo
  
themeTitle_square1:
  .db n_16, rr  ; wait before starting to play after reset
  
;;; intro, non-repeating (2 bars)
  .db n_2
  
  .db A2, A2
  .db C2, C2
  .db E2, E2
  .db F2, D2
  
  .db A2, A2
  .db C2, C2
  .db E2, E2
  .db F2, D2
  
;;; main, repeating part (18 bars)
.repeat

; build 1 (4 bars)
  .db change_ve, ve_stac1
  .db loopfor, 4
.patt1
  .db n_4
  .db A2, A2, A2, A2
  .db C2, C2, C2, C2
  .db E2, E2, E2, E2
  .db F2, F2, D2, D2
  .db loopto
  .dw .patt1

; build 2 (4 bars)
  .db change_ve, ve_fadeout2
  .db loopfor, 4
.patt2
  .db n_4
  .db A2, A2, A2, A2
  .db C2, C2, C2, C2
  .db E2, E2, E2, E2
  .db F2, F2, D2, D2
  .db loopto
  .dw .patt2

; break (2 bars)
  .db n_8
  .db A2, A2, A2, A2, A2, A2, A2, A2
  .db C2, C2, C2, C2, C2, C2, C2, C2
  .db E2, E2, E2, E2, E2, E2, E2, E2
  .db F2, F2, F2, F2, D2, D2, D2, D2
  .db A2, A2, A2, A2, A2, A2, A2, A2
  .db C2, C2, C2, C2, C2, C2, C2, C2
  .db E2, E2, E2, E2, E2, E2, E2, E2
  .db F2, F2, F2, F2, rr, rr, rr, rr

; drop (4 bars)
  .db loopfor, 4
.patt3
  .db A2, A2, rr, A2, rr, A2, A2, A2
  .db C2, C2, rr, C2, rr, C2, C2, C2
  .db E2, E2, E2, rr, rr, E2, E2, E2
  .db F2, rr, F2, E2, rr, D2, rr, D2
  .db loopto
  .dw .patt3

; outro (4 bars) - Bars 1-2
  .db loopfor, 2
.pattout1
  .db A2, A2, A2, A2, rr, A2, A2, A2
  .db C2, C2, C2, rr, C2, C2, C2, C2
  .db E2, E2, E2, rr, rr, E2, E2, E2
  .db F2, F2, F2, E2, rr, D2, rr, D2
  .db loopto
  .dw .pattout1

; outro (4 bars) - Bars 3-4
  .db loopfor, 2
.pattout2
  .db n_4
  .db A2, A2, A2, A2
  .db C2, C2, C2, C2
  .db E2, E2, E2, E2
  .db F2, F2, D2, D2
  .db loopto
  .dw .pattout2
  
  .db inf_loopto
  .dw .repeat
  .db endsound
  
  
  
themeTitle_square2:
  .db n_16, rr  ; wait before starting to play after reset
  
;;; intro, non-repeating (2 bars)
  .db n_8
  
  .db C4, rr, A3, rr, C4, rr, rr, F4
  .db C4, rr, G4, rr, C4, D4, E4, A3
  .db C4, rr, A3, rr, C4, rr, rr, F4
  .db C4, rr, G4, rr, C4, G4, E4, D4
  
  .db C4, rr, A3, rr, C4, rr, rr, F4
  .db C4, rr, G4, rr, C4, D4, G4, A3
  .db C4, rr, A3, rr, C4, rr, rr, A3
  .db C4, D4, C4, rr, G3, rr, A3, rr
  
  
;;; main, repeating (18 bars)
.repeat

; build 1
  .db loopfor, 4
.patt1
  .db C4, rr, G4, rr, C4, rr, G4, F4
  .db C4, rr, G4, rr, C4, D4, A4, B3
  .db C4, D4, G4, rr, C4, rr, F4, E4
  .db C4, D4, C4, rr, G3, rr, A3, rr
  .db loopto
  .dw .patt1
  
; build 2
  .db E4, D4, G4, E4, C4, rr, G4, E4
  .db rr, C4, G4, E4, rr, C4, D4, C5
  .db C4, D4, G4, rr, C4, rr, F4, E4
  .db C4, D4, C4, rr, G3, rr, A3, rr

  .db E4, D4, G4, E4, C4, rr, G4, E4
  .db rr, C4, G4, E4, C4, D4, G4, C5
  .db C4, D4, G4, E4, C4, rr, F4, E4
  .db rr, D4, C4, rr, C4, rr, B3, rr
  
  .db loopfor, 2
.patt2
  .db C4, D4, G4, E4, C4, D4, G4, F4
  .db C4, D4, G4, E4, C4, D4, G4, C5
  .db C4, D4, G4, E4, C4, D4, F4, E4
  .db C4, D4, E4, G4, C4, D4, A3, G3
  .db loopto
  .dw .patt2
  
; break, drop (2 + 4 bars)
  .db loopfor, 6
.patt3
  .db C4, D4, G4, E4, C4, D4, G4, F4
  .db C4, D4, G4, E4, C4, D4, G4, C5
  .db C4, D4, G4, E4, C4, D4, F4, E4
  .db C4, D4, E4, G4, C4, D4, A3, G3
  .db loopto
  .dw .patt3
  
; outro (4 bars)
  .db C4, D4, G4, E4, C4, D4, G4, C4
  .db rr, D4, G4, E4, C4, rr, G4, rr
  .db C4, D4, G4, E4, C4, D4, rr, F4
  .db rr, E4, F4, G4, B3, rr, C4, rr
  
  .db C4, D4, G4, E4, C4, D4, G4, C4
  .db rr, D4, G4, E4, C4, D4, C4, rr
  .db C4, D4, G4, E4, C4, D4, rr, F4
  .db rr, E4, F4, E4, F4, E4, C4, rr
  
  .db C4, rr, rr, C4, C4, D4, rr, G4
  .db rr, D4, rr, C4, C4, D4, G4, rr
  .db C4, rr, E4, C4, C4, D4, G4, F4
  .db rr, E4, rr, D4, E4, rr, C4, rr
  
  .db C4, rr, rr, C4, C4, D4, rr, G4
  .db rr, D4, rr, C4, C4, D4, C5, rr
  .db C4, rr, E4, C4, C4, D4, G4, D4
  .db rr, C4, rr, A3, B3, rr, C4, rr
  
  
  .db inf_loopto
  .dw .repeat
  .db endsound
  
  
  
themeTitle_tri:
  .db n_16, rr  ; wait before starting to play after reset
  
;;; intro, non-repeating (2 bars)
  .db n_1, rr, rr, rr, rr, rr, rr, rr, rr  ; silent through intro
  
;;; main, repeating (18 bars)
.repeat
  .db change_ve, ve_tri1, n_8

  
; build 1 (4 bars) - Bars 1-2
  .db loopfor, 2
.patt1
  .db rr, rr, rr, C6, rr, C6, rr, rr
  .db D6, C6, rr, rr, E6, D6, rr, rr
  .db rr, A5, rr, A5, rr, C6, rr, D6
  .db rr, G5, F5, rr, A5, rr, C6, rr
  .db loopto
  .dw .patt1
; build 1 (4 bars) - Bar 3
  .db rr, rr, C7, rr, rr, C7, rr, rr
  .db D7, C7, rr, G6, rr, rr, A6, rr
  .db rr, rr, A6, D7, E7, C7, A6, G6
  .db E6, F6, rr, F6, rr, rr, G6, rr
; build 1 (4 bars) - Bar 4
  .db rr, rr, C7, rr, rr, C7, rr, rr
  .db D7, C7, rr, G6, E6, F6, A6, rr
  .db rr, A6, rr, A6, rr, A6, rr, A6
  .db rr, G6, rr, F6, D6, E6, F6, G6
  
  
; build 2 (4 bars) - Bar 1
  .db A6, A6, E6, rr, G6, rr, E6, C7
  .db rr, A6, E6, F6, G6, F6, E6, C7
  .db rr, A6, E6, rr, G6, rr, E6, F6
  .db A6, F6, E6, rr, C6, rr, D6, rr
; build 2 (4 bars) - Bar 2
  .db C7, A6, E6, A6, G6, rr, E6, C7
  .db rr, A6, E6, F6, G6, rr, E6, rr
  .db C6, D6, E6, G6, D6, rr, F6, E6
  .db A6, F6, E6, rr, G6, rr, A6, rr
; build 2 (4 bars) - Bars 3-4
  .db loopfor, 2
.patt2
  .db A6, A6, E6, E6, G6, G6, E6, E6
  .db A6, A6, E6, E6, G6, G6, C7, C7
  .db A6, A6, E6, E6, G6, G6, E6, E6
  .db A6, A6, G6, G6, F6, F6, D6, D6
  .db loopto
  .dw .patt2
  
  
; break (2 bars)
  .db A6, A6, E6, E6, G6, G6, E6, E6
  .db A6, A6, E6, E6, G6, G6, rr, C7
  .db A6, A6, E6, E6, G6, G6, E6, E6
  .db A6, G6, A6, G6, A6, F6, E6, D6

  .db A6, A6, E6, E6, G6, G6, E6, E6
  .db A6, A6, E6, E6, G6, G6, rr, C7
  .db A6, A6, E6, E6, G6, G6, E6, E6
  .db A6, G6, A6, G6, rr, rr, rr, rr
  
; drop (4 bars)
  .db loopfor, 4
.pattdrop
  .db rr, C6, rr, C6, rr, C6, rr, C6
  .db rr, A6, rr, A6, rr, A6, rr, G6
  .db rr, E6, rr, E6, rr, E6, rr, E6
  .db rr, F6, rr, F6, rr, F6, rr, F6
  
  .db loopto
  .dw .pattdrop
  
; outro (4 bars)
  .db rr, A6, E6, rr, G6, rr, E6, C7
  .db rr, A6, E6, rr, G6, rr, E6, rr
  .db rr, A6, E6, rr, G6, rr, rr, E6
  .db A6, E6, F6, rr, E6, D6, C6, rr
  
  .db rr, A6, E6, rr, G6, rr, E6, C7
  .db rr, A6, E6, rr, G6, E6, G6, C7
  .db rr, A6, E6, rr, G6, E6, rr, F6
  .db rr, E6, F6, rr, F6, rr, rr, rr
  
  .db rr, A6, E6, rr, G6, rr, E6, C7
  .db rr, A6, E6, rr, G6, rr, E6, rr
  .db rr, A6, E6, rr, G6, rr, rr, E6
  .db A6, E6, F6, rr, E6, C6, rr, C6
  
  .db rr, A6, E6, rr, G6, rr, E6, C7
  .db rr, A6, E6, rr, G6, E6, G6, C7
  .db rr, A6, E6, rr, G6, rr, rr, E6
  .db A6, F6, rr, C6, rr, rr, rr, C6
  
  .db inf_loopto
  .dw .repeat
  .db endsound
  
  
  
themeTitle_noi:
  .db n_16, rr  ; wait before starting to play after reset
  
;;; intro, non-repeating (2 bars)
  .db n_8
  .db loopfor, 2
.intro
  .db rr, rr, hat1, rr, rr, rr, hat1, rr
  .db rr, rr, hat1, rr, rr, rr, rr, hat1
  .db rr, rr, hat1, rr, rr, rr, hat1, rr
  .db rr, rr, hat1, rr, rr, rr, hat1, hat1
  .db loopto
  .dw .intro
  
  
;;; main, repeating (18 bars)
.repeat
  
; build 1 (4 bars) (hat and kick)
  .db n_8
  .db loopfor, 4
.pattbuild1
  .db change_ve, ve_drumkick, kick2, rr, change_ve, ve_drumhat2, hat1, rr
  .db rr, change_ve, ve_drumkick, kick2, change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick2, rr, change_ve, ve_drumhat2, hat1, rr
  .db rr, rr, rr, hat1
  
  .db change_ve, ve_drumkick, kick2, rr, change_ve, ve_drumhat2, hat1, rr
  .db rr, change_ve, ve_drumkick, kick2, change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick2, rr, change_ve, ve_drumhat2, hat1, rr
  .db change_ve, ve_drumkick, kick2, rr, change_ve, ve_drumhat2, hat1, hat1
  
  .db loopto
  .dw .pattbuild1
  
; build 2 (4 bars) (hat only)
  .db change_ve, ve_drumhat2
  .db loopfor, 4
.pattbuild2
  .db rr, rr, hat1, rr
  .db rr, rr, hat1, rr
  
  .db rr, rr, hat1, rr
  .db rr, rr, rr, hat1
  
  .db rr, rr, hat1, rr
  .db rr, rr, hat1, rr
  
  .db rr, rr, hat1, rr
  .db rr, rr, hat1, hat1
  
  .db loopto
  .dw .pattbuild2
  
  
; break (2 bars) - Time division
  .db loopfor, 4  , n_4
.pattbreak1
  .db change_ve, ve_drumhat2, hat1, hat1, hat1, hat1
  .db loopto
  .dw .pattbreak1
  
  .db loopfor, 4  , n_8  
.pattbreak2
  .db change_ve, ve_drumhat2, hat1, hat1, hat1, hat1
  .db loopto
  .dw .pattbreak2
  
  .db loopfor, 4  , n_16
.pattbreak3
  .db change_ve, ve_drumhat3, hat1, hat1, hat1, hat1
  .db loopto
  .dw .pattbreak3
  
  .db loopfor, 4  , n_32 
.pattbreak4
  .db change_ve, ve_drumhat3, hat1, hat1, hat1, hat1
  .db loopto
  .dw .pattbreak4
  
  .db n_4, rr, rr
  
; drop (4 bars) - Bar 1
  .db n_8, change_ve, ve_drumhat2
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1,   n_16, change_ve, ve_drumhat2, hat1, change_ve, ve_drumsnare2, snare1
  .db n_8, rr, snare1
  
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		snare1
  
; drop (4 bars) - Bar 2
  .db n_8
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1,   n_16, change_ve, ve_drumhat2, hat1, change_ve, ve_drumsnare2, snare1
  .db n_8, rr, snare1
  
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1,		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumsnare2, snare1, 	snare1
  
; drop (4 bars) - Bars 3-4
  .db loopfor, ( 2 * 4 )
.pattdrop
  .db n_4, change_ve, ve_drumkick, kick1, 			change_ve, ve_drumcrash1, hat1
  .db n_8, rr, change_ve, ve_drumkick, kick1, n_4,	change_ve, ve_drumcrash1, hat1
  .db loopto
  .dw .pattdrop
  
; outro (4 bars) - Bar 1
  .db n_8
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, change_ve, ve_drumsnare2, snare1
  .db rr, change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, change_ve, ve_drumkick, kick1
  .db change_ve, ve_drumsnare2, snare1, rr, 	change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, change_ve, ve_drumsnare2, snare1
  .db rr, change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick1,   change_ve, ve_drumhat2, hat1,   change_ve, ve_drumsnare2, snare1,   change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1,   change_ve, ve_drumhat2, hat1,   change_ve, ve_drumsnare2, snare1,   change_ve, ve_drumhat2, hat1
  
; outro (4 bars) - Bar 2
  .db n_8
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, change_ve, ve_drumsnare2, snare1
  .db rr, change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, change_ve, ve_drumkick, kick1
  .db change_ve, ve_drumsnare2, snare1, rr, 	change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, change_ve, ve_drumsnare2, snare1
  .db rr, change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick1, rr,  		change_ve, ve_drumsnare2, snare1,   change_ve, ve_drumhat2, hat1
  .db change_ve, ve_drumkick, kick1, rr,  		change_ve, ve_drumkick, kick1,      rr
  
; outro (4 bars) - Bar 3
  .db n_8
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, change_ve, ve_drumkick, kick1
  .db change_ve, ve_drumsnare2, snare1, rr,		change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, change_ve, ve_drumsnare2, snare1
  .db rr, change_ve, ve_drumhat2, hat1,		 	change_ve, ve_drumsnare2, snare1, change_ve, ve_drumhat2, hat1
  
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, change_ve, ve_drumkick, kick1
  .db change_ve, ve_drumsnare2, snare1, rr,		change_ve, ve_drumhat2, hat1, change_ve, ve_drumsnare2, snare1
  
  .db rr, rr, 									change_ve, ve_drumhat2, hat1, change_ve, ve_drumsnare2, snare1
  .db change_ve, ve_drumkick, kick1, rr,		change_ve, ve_drumhat2, hat1, change_ve, ve_drumhat2, hat1
  
; outro (4 bars) - Bar 4
  .db n_8
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, rr
  .db rr, change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, rr
  .db rr, change_ve, ve_drumhat2, hat1, 		rr, change_ve, ve_drumhat2, hat1
  
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, rr
  .db rr, change_ve, ve_drumkick, kick1, 		change_ve, ve_drumhat2, hat1, rr
  
  .db change_ve, ve_drumkick, kick1, rr, 		change_ve, ve_drumhat2, hat1, rr
  .db change_ve, ve_drumkick, kick1, rr, 		rr, rr
  
  
  .db inf_loopto
  .dw .repeat
  .db endsound


