;; Stream header format:
 ; 
 ; Stream number (MUSIC_SQ1, MUSIC_SQ2, MUSIC_TRI, MUSIC_NOI, SFX_1, or SFX_2)
 ; Stream status (1=enabled, 0=disabled: If stream is disabled, skip to next header)
 ; Channel number
 ; Channel settings (Squares: Duty cycle %DD110000, Triangle: $80, Noise: $30)
 ; Volume envelope (offset for pointer table)
 ; Note stream pointer (points to label with notes below)
 ; Tempo

sfxGameover_header:
  .db $01	; number of streams

  .db SFX_2
  .db $01
  .db NOISE
  .db $30
  .db ve_constant
  .dw sfxGameover_noi
  .db $60
  
  
sfxGameover_noi:
  ;.db n_16, N1_8, n_16, rr, n_16, N1_8, n_16, rr
  ;.db n_32, N1_7, n_d8, N1_8, n_16, N1_A, rr
  .db n_32, N1_7, N1_8, n_d8, N1_9, n_d16, N1_B, rr
  
  .db endsound