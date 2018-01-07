themeDayTempo = $64  ; starting tempo (175 bpm)
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
  .db %10110000
  .db ve_stac2
  .dw themeDay_square1
  .db themeDayTempo
  
  .db MUSIC_SQ2
  .db $01
  .db SQUARE_2
  .db %10110000
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
  
  ; This track is in 3/4, so each bar only has 3 quarter notes.
  
themeDay_square1:

  ; intro (4 bars)
  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4
  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4
  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4
  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4

.infloop

  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4
  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4
  
  .db n_4, F3, n_16, A3, rr, rr, rr, n_4, A3
  .db n_4, F3, n_16, A3, rr, rr, rr, n_4, A3
  
  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4
  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4
  
  .db n_2, D4, n_4, C4
  .db B3, G3, F3

  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4
  .db n_4, G3, n_16, C4, rr, rr, rr, n_4, C4
  
  .db n_4, D4, n_16, A3, rr, rr, rr, n_4, A3
  .db n_4, D4, n_16, A3, rr, rr, rr, n_4, A3
  
  .db n_4, B3, G3, F3, E3, D3, B2
  .db C3, n_8, C4, rr, n_4, C4
  .db C3, n_8, C4, rr, n_4, C4

  .db inf_loopto
  .dw .infloop
  .db endsound
  
themeDay_square2:
  
  ; intro (4 bars)
  .db n_d2, rr, rr, rr, rr
  
.infloop

  ; section 1 (12 bars)
  .db n_32, C5, D5, n_d8, E5, n_4, E5, G4
  .db n_2, D5, n_4, C5
  .db n_d2, A4
  .db rr
  
  .db n_4, E4, A4, C5
  .db n_4, D5, E5, D5
  .db n_d2, C5
  .db B4
  
  .db n_2, E5, n_4, C5
  .db n_2, D5, n_4, C5
  .db n_d2, F5
  .db n_4, rr, G4, E4
  
  .db n_4, A4, C5, D5
  .db E5, D5, B4
  .db n_d2, C5, rr
  
  ; section 2 (12 bars)
  .db n_32, C5, D5, n_d8, E5, n_4, E5, G4
  .db n_2, D5, n_4, C5
  .db n_d2, A4
  .db rr
  
  .db n_4, E4, A4, C5
  .db n_4, E5, D5, C5
  .db n_d2, G5
  .db n_4, F5, E5, D5
  
  .db n_2, E5, n_4, C5
  .db n_2, D5, n_4, C5
  .db n_2, E5, n_4, D5
  .db n_4, C5, B4, A4
  
  .db n_4, G4, C5, D5
  .db E5, D5, B4
  .db n_d2, C5, rr
  
  
  .db inf_loopto
  .dw .infloop
  .db endsound
  
themeDay_tri:

  ; intro (4 bars)
  .db n_4, rr, n_8, C5, B4, C5, rr
  .db n_4, rr, n_8, C5, B4, C5, rr
  .db n_4, rr, n_8, C5, B4, C5, rr
  .db n_4, rr, n_8, C5, rr, C5, rr
  
.infloop
  ; section 1 (12 bars)
  .db n_4, rr, n_8, A5, Gs5, A5, rr
  .db n_4, rr, n_8, A5, Gs5, A5, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  
  .db n_4, rr, n_8, D6, Cs6, D6, rr
  .db n_4, rr, n_8, A5, Gs5, A5, rr
  .db n_4, rr, n_8, Fs5, rr, Fs5, rr
  .db n_4, G5, rr, rr
  
  .db n_4, rr, n_8, G5, Fs5, G5, rr
  .db n_4, rr, n_8, G5, Fs5, G5, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  
  .db n_4, rr, n_8, D6, Cs6, D6, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  .db n_8, rr, rr, E6, rr, E6, rr
  .db n_4, C6, rr, rr
  
  ; section 2 (12 bars)
  .db n_4, rr, n_8, A5, Gs5, A5, rr
  .db n_4, rr, n_8, A5, Gs5, A5, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  
  .db n_4, rr, n_8, D6, Cs6, D6, rr
  .db n_4, rr, n_8, A5, Gs5, A5, rr
  .db n_4, rr, n_8, As5, rr, As5, rr	; only change
  .db n_4, B5, rr, rr					; only change
  
  .db n_4, rr, n_8, G5, Fs5, G5, rr
  .db n_4, rr, n_8, G5, Fs5, G5, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  
  .db n_4, rr, n_8, D6, Cs6, D6, rr
  .db n_4, rr, n_8, B5, As5, B5, rr
  .db n_8, rr, rr, E6, rr, E6, rr
  .db n_4, C6, rr, rr
  
  .db inf_loopto
  .dw .infloop
  .db endsound
  
themeDay_noi:
  
  ; intro (4 bars)
  .db n_8, change_ve, ve_fallingkick1, kick2, rr, n_4, rr, rr
  .db n_8, change_ve, ve_fallingsnare2, snare2, rr, n_4, rr, rr
  .db n_8, change_ve, ve_fallingkick1, kick2, rr, n_4, rr, rr
  .db n_8, change_ve, ve_fallingsnare2, snare2, rr
  .db      change_ve, ve_fallingkick1, kick2, rr
  .db      change_ve, ve_fallingsnare2, snare2, rr
  
.infloop

  .db n_8, change_ve, ve_fallingkick1, kick2, rr, change_ve, ve_fallingsnare2, snare2, rr, snare2, rr
  .db n_8, rr, rr, snare2, rr, snare2, rr
  
  
  .db inf_loopto
  .dw .infloop
  .db endsound


