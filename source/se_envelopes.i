;;;; Volume envelopes (General) ;;;;

; Silent (muted)
se_ve_muted:
  .db $00
  .db $FF  ; end

; No envelope (constant full volume)
se_ve_constant:
  .db $0F
  .db $FF  ; end

; Short staccato
se_ve_stac1:
  .db $0F, $0E, $0D, $0C, $09, $05, $00
  .db $FF  ; end
  
; Medium staccato
se_ve_stac2:
  .db $0F, $0F, $0E, $0D, $0C, $0A, $08, $05, $00
  .db $FF  ; end
  
; Long fade in
se_ve_fadein:
  .db $01, $01, $02, $02, $03, $03, $04, $04, $07, $07
  .db $08, $08, $0A, $0A, $0C, $0C, $0D, $0D, $0E, $0E
  .db $0F, $0F
  .db $FF  ; end
  
; Long fade out
se_ve_fadeout1:
  .db $0F, $0F, $0E, $0E, $0D, $0D, $0C, $0C, $0B, $0B
  .db $0A, $0A, $09, $09, $08, $08, $07, $06, $05, $04
  .db $02, $00
  .db $FF  ; end
  
; Medium fade out
se_ve_fadeout2:
  .db $0F, $0F, $0E, $0E, $0D, $0C, $0B, $0B, $0A, $09
  .db $08, $06, $05, $03, $02, $00
  .db $FF  ; end
  
; Short staccato with echo
se_ve_stac_echo:
  .db $0D, $0D, $0D, $0C, $0B, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $06, $06, $06, $05, $04, $00
  .db $FF  ; end
  
; Triangle envelope
se_ve_tri1:
  .db $0F, $0F, $0F, $0F, $00
  .db $FF  ; end
  
; Kick envelope
se_ve_drumkick:
  .db $0D, $06, $00
  .db $FF  ; end
  
; Snare envelope
se_ve_drumsnare1:
  .db $0F, $0E, $0B, $06, $02, $00
  .db $FF  ; end
  
; Bigger snare envelope, long tail
se_ve_drumsnare2:
  .db $0F, $06, $04, $02, $01, $00
  .db $FF  ; end
  
; Hi-hat envelope
se_ve_drumhat:
  .db $0F, $0D, $09, $05, $00
  .db $FF  ; end
  
; Shorter Hi-hat envelope
se_ve_drumhat2:
  .db $0E, $07, $01, $00
  .db $FF  ; end
  
; Even shorter Hi-hat envelope
se_ve_drumhat3:
  .db $0E, $04, $00
  .db $FF  ; end
  
; Even shorter Hi-hat envelope, quiet
se_ve_drumhat4:
  .db $07, $02, $00
  .db $FF  ; end
  
; Crash cymbal envelope
se_ve_drumcrash1:
  .db $0F, $0F, $0E, $0D, $0B, $09, $05, $03, $00
  .db $FF  ; end

  