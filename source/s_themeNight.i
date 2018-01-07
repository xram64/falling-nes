themeNightTempo = $3F  ; starting tempo (110 bpm)
themeNightTempo2X = $7E  ; starting tempo for SQ_2 (220 bpm, doubled from 110 bpm)
;; Stream header format:
 ; 
 ; Stream number (MUSIC_SQ1, MUSIC_SQ2, MUSIC_TRI, MUSIC_NOI, SFX_1, or SFX_2)
 ; Stream status (1=enabled, 0=disabled: If stream is disabled, skip to next header)
 ; Channel number
 ; Channel settings (Squares: Duty cycle %DD110000, Triangle: $80, Noise: $30)
 ; Volume envelope (offset for pointer table)
 ; Note stream pointer (points to label with notes below)
 ; Tempo

themeNight_header:
  .db $04	; number of streams
  
  .db MUSIC_SQ1
  .db $01
  .db SQUARE_1
  .db %01110000
  .db ve_drumcrash1
  .dw themeNight_square1
  .db themeNightTempo
  
  .db MUSIC_SQ2
  .db $01
  .db SQUARE_2
  .db %10110000
  .db ve_fadeout2
  .dw themeNight_square2
  .db themeNightTempo2X
  ; Uses a doubled tempo to fit in "64th"-note multiple lengths.
  ; Note that if the tempo of this track is additively scaled, this channel will not scale properly.
  ; If scaling is implemented, the other channels should be rewritten in 220 BPM.
  
  .db MUSIC_TRI
  .db $01
  .db TRIANGLE
  .db $80
  .db ve_fadeout2
  .dw themeNight_tri
  .db themeNightTempo2X
  ; Uses a doubled tempo to fit in "64th"-note multiple lengths.
  ; Note that if the tempo of this track is additively scaled, this channel will not scale properly.
  ; If scaling is implemented, the other channels should be rewritten in 220 BPM.
  
  .db MUSIC_NOI
  .db $01
  .db NOISE
  .db $30
  .db ve_muted
  .dw themeNight_noi
  .db themeNightTempo
  
themeNight_square1:

.loop_sq1
  .db n_2
  .db Ds3, Ds3, Ds3, Ds3
  .db Cs3, Cs3, Cs3, Cs3
  .db Ds3, Ds3, Ds3, Ds3
  .db Fs2, Fs2, Gs2, Gs2
  .db inf_loopto
  .dw .loop_sq1
  .db endsound
  
themeNight_square2:

.infloop
  ; Welcome to swing note hell (:
  
  .db n_2, rr, n_s5_16, Cs5, n_s11_16, As4, n_s5_16, Gs4, n_s11_16, As4
  .db n_s5_16, As4, n_d8, C5, n_s5_32, Cs5, n_8, C5, n_s7_32, As4, n_2, Gs4
  
  .db n_2, rr, n_s5_16, Cs5, n_s11_16, As4, n_s5_16, Gs4, n_d8, As4
  .db n_s5_16, rr, n_d8, Gs4, n_s5_16, As4, n_d8, C5, n_s5_16, Cs5, n_d8, As4, n_s5_16, Cs5, n_d8, Ds5

  .db n_2, rr, n_s5_16, Cs5, n_s11_16, As4, n_s5_16, Gs4, n_s11_16, As4
  .db n_s5_16, As4, n_d8, C5, n_s5_32, Cs5, n_8, C5, n_s7_32, As4, n_s5_16, Gs4, n_d8, Fs4
  
  .db n_2, rr, n_s5_16, Ds4, n_d8, Cs4, n_s5_16, Ds4, n_d8, F4, n_s5_16, Fs4, n_s11_16, Gs4
  .db n_s5_16, Fs4, n_d8, F4, n_2, Ds4, Cs4
  
  
  .db n_2, rr, n_s5_16, Ds5, n_s11_16, As5, n_s5_16, Ds5, n_d8, Gs5
  .db n_s5_16, rr, n_d8, Ds5, n_2, Fs5, n_16, F5, n_4, Fs5, n_d8, F5, n_s5_16, Ds5, n_d8, Cs5
  
  .db n_2, rr, n_s5_16, Gs4, n_d8, As4, n_s5_16, Cs5, n_s7_16, Ds5, n_16, E5, n_2, F5
  .db n_2, Fs5, n_d8, Ds5, n_s5_32, Fs5, Ds5, n_d8, Cs5, n_s5_32, C5, Gs4, n_d8, Fs4
  
  .db n_2, rr, n_s5_16, C5, n_s11_16, As4, n_s5_16, Gs4, n_s11_16, As4
  .db n_s5_16, As4, n_d8, C5, n_s5_32, Cs5, n_8, C5, n_s7_32, As4, n_s5_16, Gs4, n_d8, Fs4
  
  .db n_2, rr, n_s5_16, Ds4, n_d8, Cs4, n_s5_16, Ds4, n_d8, F4, n_s5_16, Fs4, n_s11_16, Gs4
  .db n_s5_16, Fs4, n_d8, F4, n_s5_16, As3, n_d8, C4, n_s5_16, Cs4, n_d8, Ds4

  .db inf_loopto
  .dw .infloop
  .db endsound
  
themeNight_tri:

.infloop
  ; Copy of SQ_2, but triangle sounds one octave lower.
  
  .db n_2, rr, n_s5_16, Cs5, n_s11_16, As4, n_s5_16, Gs4, n_s11_16, As4
  .db n_s5_16, As4, n_d8, C5, n_s5_32, Cs5, n_8, C5, n_s7_32, As4, n_2, Gs4
  
  .db n_2, rr, n_s5_16, Cs5, n_s11_16, As4, n_s5_16, Gs4, n_d8, As4
  .db n_s5_16, rr, n_d8, Gs4, n_s5_16, As4, n_d8, C5, n_s5_16, Cs5, n_d8, As4, n_s5_16, Cs5, n_d8, Ds5

  .db n_2, rr, n_s5_16, Cs5, n_s11_16, As4, n_s5_16, Gs4, n_s11_16, As4
  .db n_s5_16, As4, n_d8, C5, n_s5_32, Cs5, n_8, C5, n_s7_32, As4, n_s5_16, Gs4, n_d8, Fs4
  
  .db n_2, rr, n_s5_16, Ds4, n_d8, Cs4, n_s5_16, Ds4, n_d8, F4, n_s5_16, Fs4, n_s11_16, Gs4
  .db n_s5_16, Fs4, n_d8, F4, n_2, Ds4, Cs4
  
  
  .db n_2, rr, n_s5_16, Ds5, n_s11_16, As5, n_s5_16, Ds5, n_d8, Gs5
  .db n_s5_16, rr, n_d8, Ds5, n_2, Fs5, n_16, F5, n_4, Fs5, n_d8, F5, n_s5_16, Ds5, n_d8, Cs5
  
  .db n_2, rr, n_s5_16, Gs4, n_d8, As4, n_s5_16, Cs5, n_s7_16, Ds5, n_16, E5, n_2, F5
  .db n_2, Fs5, n_d8, Ds5, n_s5_32, Fs5, Ds5, n_d8, Cs5, n_s5_32, C5, Gs4, n_d8, Fs4
  
  .db n_2, rr, n_s5_16, C5, n_s11_16, As4, n_s5_16, Gs4, n_s11_16, As4
  .db n_s5_16, As4, n_d8, C5, n_s5_32, Cs5, n_8, C5, n_s7_32, As4, n_s5_16, Gs4, n_d8, Fs4
  
  .db n_2, rr, n_s5_16, Ds4, n_d8, Cs4, n_s5_16, Ds4, n_d8, F4, n_s5_16, Fs4, n_s11_16, Gs4
  .db n_s5_16, Fs4, n_d8, F4, n_s5_16, As3, n_d8, C4, n_s5_16, Cs4, n_d8, Ds4

  .db inf_loopto
  .dw .infloop


  .db endsound
  
themeNight_noi:

.infloop
  .db loopfor, 4
.hatloop1
  .db n_8, change_ve, ve_fallinghat1, hat1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db loopto
  .dw .hatloop1
  
  .db n_8, rr					; changeup
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_fallinghat1, hat1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  
  .db loopfor, 2
.hatloop2
  .db n_8, change_ve, ve_fallinghat1, hat1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db loopto
  .dw .hatloop2
  
  .db loopfor, 4
.hatloop3
  .db n_8, change_ve, ve_fallinghat1, hat1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db loopto
  .dw .hatloop3
  
  .db loopfor, 2
.hatloop4
  .db n_8, rr					; changeup
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_fallinghat1, hat1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db n_8, change_ve, ve_fallingsnare1, snare1
  .db n_32, rr, change_ve, ve_drumhat4, hat1, rr, rr
  .db loopto
  .dw .hatloop4
  
  .db inf_loopto
  .dw .infloop
  
  .db endsound


