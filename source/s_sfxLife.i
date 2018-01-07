;; Stream header format:
 ; 
 ; Stream number (MUSIC_SQ1, MUSIC_SQ2, MUSIC_TRI, MUSIC_NOI, SFX_1, or SFX_2)
 ; Stream status (1=enabled, 0=disabled: If stream is disabled, skip to next header)
 ; Channel number
 ; Channel settings (Squares: Duty cycle %DD110000, Triangle: $80, Noise: $30)
 ; Volume envelope (offset for pointer table)
 ; Note stream pointer (points to label with notes below)
 ; Tempo

sfxLife_header:
  .db $01	; number of streams

  .db SFX_1
  .db $01
  .db TRIANGLE
  .db $80 
  .db ve_constant
  .dw sfxLife_tri
  .db $40
  
  
sfxLife_tri:
  .db n_32
  .db G7, E7, C7, A6, D7, C7, rest
  
  .db endsound