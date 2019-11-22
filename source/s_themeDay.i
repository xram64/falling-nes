themeDayTempo = $55  ; starting tempo (150 bpm)

;; Stream header format:
 ; 
 ; Stream number (MUSIC_SQ1, MUSIC_SQ2, MUSIC_TRI, MUSIC_NOI, SFX_1, or SFX_2)
 ; Stream status (1=enabled, 0=disabled: If stream is disabled, skip to next header)
 ; Channel number
 ; Channel settings (Squares: Duty cycle %DD110000, Triangle: $80, Noise: $30)
 ; Volume envelope (offset for pointer table)
 ; Note stream pointer (points to label with notes below)
 ; Tempo

themeDay_header:
  .db $04	; number of streams
  
  .db MUSIC_SQ1
  .db $01
  .db SQUARE_1
  .db %01110000
  .db ve_drumcrash2
  .dw themeDay_square1
  .db themeDayTempo
  
  .db MUSIC_SQ2
  .db $01
  .db SQUARE_2
  .db %11110000
  .db ve_fallingfadeout
  .dw themeDay_square2
  .db themeDayTempo
  
  .db MUSIC_TRI
  .db $01
  .db TRIANGLE
  .db $80
  .db ve_constant
  .dw themeDay_tri
  .db themeDayTempo
  
  .db MUSIC_NOI
  .db $01
  .db NOISE
  .db $30
  .db ve_muted
  .dw themeDay_noi
  .db themeDayTempo
  
themeDay_square1:

.infloop
  .db n_8
  
  .db loopfor, 4
.loopA
  .db F3, E3, C3
  .db F3, E3, C3
  .db F3, E3
  .db loopto
  .dw .loopA
  
  .db loopfor, 3
.loopB
  .db F3, E3, C3
  .db F3, E3, C3
  .db F3, E3
  .db loopto
  .dw .loopB
  
  .db F3, E3, C3
  .db F3, G3, F3
  .db E3, C3
  
  .db inf_loopto
  .dw .infloop
  .db endsound
  
  
  
themeDay_square2:

.infloop
  
  .db n_8
  
  .db change_ve, ve_fallingLFO1
  
  .db rr, C4, E4, F4, rr, rr, rr, rr
  .db rr, C4, E4, F4, rr, rr, rr, rr
  .db rr, A3, C4, E4, rr, rr, rr, rr
  .db rr, A3, C4, E4, F4, E4, D4, C4
  
  .db rr, C4, E4, F4, rr, rr, rr, rr
  .db rr, C4, E4, F4, rr, rr, rr, rr
  .db rr, A3, C4, E4, rr, rr, rr, rr
  .db A3, C4, E4, F4, G4, F4, E4, C4
  
  .db rr, C4, E4, F4, rr, rr, rr, rr
  .db rr, C4, E4, F4, rr, rr, rr, rr
  .db rr, A3, C4, E4, rr, rr, rr, rr
  .db rr, A3, C4, E4, F4, E4, D4, C4
  
  .db C4, E4, F4, rr, rr, F4, rr, F4
  .db C4, E4, F4, D4, rr, C4, rr, C4
  .db rr, A3, C4, E4, rr, rr, rr, E4
  .db C4, A3, C4, E4, G4, F4, E4, C4
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  .db change_ve, ve_fallingfadeout
  
  .db C4, E4, F4, C4, E4, F4, C4, E4
  .db C4, E4, F4, C4, E4, F4, C4, E4
  .db C4, E4, F4, C4, E4, F4, C4, E4
  .db C4, E4, F4, C4, G4, F4, E4, C4
  
  .db C4, E4, F4, C4, E4, F4, C4, E4
  .db C4, E4, F4, C4, E4, F4, C4, E4
  .db C4, E4, F4, C4, E4, F4, C4, E4
  .db C4, E4, F4, C4, F4, E4, C4, rr
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  .db change_ve, ve_fallingfadeout
  
  .db G4, rr, G4, G4, rr, A4, rr, G4
  .db rr, rr, F4, rr, E4, rr, C4, rr
  .db D4, rr, D4, D4, rr, E4, rr, D4
  .db rr, rr, rr, rr, rr, rr, rr, rr
  
  .db G4, rr, G4, G4, rr, A4, rr, G4
  .db rr, rr, C5, rr, D5, rr, C5, rr
  .db E5, rr, C5, C5, rr, G4, rr, G4
  .db rr, F4, E4, F4, E4, D4, C4, rr
  
  .db change_ve, ve_fallingshortfadeout
  
  .db n_4, G4, n_8, G4, n_4, G4, A4, n_d4, G4
  .db n_4, F4, E4, C4
  .db n_4, D4, n_8, D4, n_4, D4, E4, change_ve, ve_fallingfadeout, n_1, D4
  .db n_8, rr, change_ve, ve_fallingshortfadeout
  
  .db n_4, G4, n_8, G4, n_4, G4, A4, n_d4, G4
  .db n_4, C5, D5, C5
  .db n_4, E5, n_8, C5, n_4, C5, G4, n_4, G4
  .db n_8, F4, E4, F4, E4, D4, C4, C4
  
  ; .db G4, rr, G4, G4, rr, A4, rr, G4
  ; .db rr, rr, F4, rr, E4, rr, C4, rr
  ; .db D4, rr, D4, D4, rr, E4, rr, D4
  ; .db rr, rr, rr, rr, rr, rr, rr, rr
  
  ; .db G4, rr, G4, G4, rr, A4, rr, G4
  ; .db rr, rr, C5, rr, D5, rr, C5, rr
  ; .db E5, rr, C5, C5, rr, G4, rr, G4
  ; .db rr, F4, E4, F4, E4, D4, C4, rr
  

  .db inf_loopto
  .dw .infloop
  
  .db endsound
  
  
  
themeDay_tri:

.infloop
  
  .db n_1
  .db F3, D3, C3
  .db n_2
  .db D3, E3
  
  .db n_1
  .db F3, D3, C3
  .db n_2
  .db D3, G3

  .db inf_loopto
  .dw .infloop

  .db endsound
  
  
  
themeDay_noi:

.infloop
  .db n_1, change_ve, ve_muted, rr, rr, rr, rr, rr, rr, rr, rr
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, kick2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_16, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, kick2, rr
  
  ;;;;;;;;;;;;;;;;
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, kick2, kick2, n_16, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, n_8, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_16, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, kick2, rr
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  .db loopfor, 2
.loopA
  .db n_16, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumhat4, snare3, n_8, change_ve, ve_drumcrash2, hat2
  
  .db n_16, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  
  .db n_16, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumhat4, snare3, n_8, change_ve, ve_drumcrash2, hat2
  
  .db n_16, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3, change_ve, ve_drumsnare2, kick2, change_ve, ve_drumhat4, snare3
  .db n_16, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumhat4, snare3, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumhat4, snare3
  
  .db loopto
  .dw .loopA
  
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  .db n_8, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, rr, n_16, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  .db n_8, change_ve, ve_drumsnare2, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, kick2, kick2, change_ve, ve_fallingsnare1, snare1, n_16, change_ve, ve_drumsnare2, kick2, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1
  .db n_16, rr, change_ve, ve_drumsnare2, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_16, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, kick2, rr
  
  ;;;;;;;;;;;;;;;; (above and below patterns are identical)
  
  .db n_8, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, rr, n_16, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  .db n_8, change_ve, ve_drumsnare2, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, kick2, kick2, change_ve, ve_fallingsnare1, snare1, n_16, change_ve, ve_drumsnare2, kick2, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1
  .db n_16, rr, change_ve, ve_drumsnare2, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_16, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, kick2, rr
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, kick2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_16, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, kick2, rr
  
  ;;;;;;;;;;;;;;;;
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, kick2, kick2, n_16, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, n_8, kick2
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, change_ve, ve_fallingsnare1, snare1, rr
  
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_16, change_ve, ve_drumsnare2, kick2, kick2, change_ve, ve_fallingsnare1, snare1, change_ve, ve_drumsnare2, kick2, kick2, rr
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  .db inf_loopto
  .dw .infloop
  
  .db endsound









