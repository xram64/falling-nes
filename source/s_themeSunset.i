themeSunsetTempo = $4D

;; Stream header format:
 ; 
 ; Stream number (MUSIC_SQ1, MUSIC_SQ2, MUSIC_TRI, MUSIC_NOI, SFX_1, or SFX_2)
 ; Stream status (1=enabled, 0=disabled: If stream is disabled, skip to next header)
 ; Channel number
 ; Channel settings (Squares: Duty cycle %DD110000, Triangle: $80, Noise: $30)
 ; Volume envelope (offset for pointer table)
 ; Note stream pointer (points to label with notes below)
 ; Tempo

themeSunset_header:
  .db $04	; number of streams
  
  .db MUSIC_SQ1
  .db $01
  .db SQUARE_1
  .db %10110000
  .db ve_fallingLFO2
  .dw themeSunset_square1
  .db themeSunsetTempo
   
  .db MUSIC_SQ2
  .db $01
  .db SQUARE_2
  .db %10110000
  .db ve_fallingconstant0A
  .dw themeSunset_square2
  .db themeSunsetTempo
  
  .db MUSIC_TRI
  .db $01
  .db TRIANGLE
  .db $80
  .db ve_constant
  .dw themeSunset_tri
  .db themeSunsetTempo
  
  .db MUSIC_NOI
  .db $01
  .db NOISE
  .db $30
  .db ve_muted
  .dw themeSunset_noi
  .db themeSunsetTempo
  
themeSunset_square1:
.infloop

  .db n_1, E2, C2, F2, G2

  .db inf_loopto
  .dw .infloop
  .db endsound
  
themeSunset_square2:
.infloop

  .db n_1, E4
  .db n_4, C4, C4, C4, n_16, C4, rr, n_8, C4
  .db n_1, F4
  ;.db n_4, G4, G4, G4, n_16, G4
  .db change_ve, ve_fallingLFO2, n_d2, change_ve, ve_fallingconstant0A, G4, n_16, rr
  .db n_d16, Fs4, F4

  .db inf_loopto
  .dw .infloop
  .db endsound
  
themeSunset_tri:
.infloop

  .db n_4, D5, n_d2, E5
  .db n_16, Fs5, n_d8, G5, n_d2, G5
  .db n_16, Gs5, n_d8, A5, n_d2, A5
  .db n_2, A5, G5

  .db inf_loopto
  .dw .infloop
  .db endsound
  
themeSunset_noi:
.infloop
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db hat1, rr, rr, rr, n_8, change_ve, ve_drumsnare2, kick2
  
  .db n_8, rr, n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_drumsnare2, kick2, n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  
  ; same as above, without last hat
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db hat1, rr, rr, rr, n_8, change_ve, ve_drumsnare2, kick2
  
  .db n_8, rr, n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_4, change_ve, ve_drumsnare2, kick2
  .db n_8, change_ve, ve_fallingsnare1, snare1, n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_4, change_ve, ve_drumsnare2, kick2

  .db inf_loopto
  .dw .infloop
  .db endsound


