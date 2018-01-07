;; Stream header format:
 ; 
 ; Stream number (MUSIC_SQ1, MUSIC_SQ2, MUSIC_TRI, MUSIC_NOI, SFX_1, or SFX_2)
 ; Stream status (1=enabled, 0=disabled: If stream is disabled, skip to next header)
 ; Channel number
 ; Channel settings (Squares: Duty cycle %DD110000, Triangle: $80, Noise: $30)
 ; Volume envelope (offset for pointer table)
 ; Note stream pointer (points to label with notes below)
 ; Tempo

sfxUnpause_header:
  .db $01	; number of streams

  .db SFX_2
  .db $01
  .db SQUARE_2
  .db %10110000
  .db ve_constant
  .dw sfxUnpause_tri
  .db $50
  
  
sfxUnpause_tri:
  .db n_16
  .db As3, E4, A4, rr
  
  .db endsound