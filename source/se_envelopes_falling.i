;;;; Custom volume envelopes (FALLING) ;;;;

;; For Night theme

; long, quiet hat
se_ve_fallinghat1:
  .db $09, $08, $06, $04, $02, $00
  .db $FF  ; end
  
; quiet snare
se_ve_fallingsnare1:
  .db $0B, $09, $05, $02, $00
  .db $FF  ; end

  
;; For Sunset theme
  
; LFO envelope, completes 4 cycles during one whole note, starts low
se_ve_fallingLFO1:
  ;;;  8 10 12 13 13 12 10 8
  .db $08, $0A, $0C, $0D, $0D, $0C, $0A, $08
  .db $08, $0A, $0C, $0D, $0D, $0C, $0A, $08
  .db $08, $0A, $0C, $0D, $0D, $0C, $0A, $08
  .db $08, $0A, $0C, $0D, $0D, $0C, $0A, $08
  
  .db $FF  ; end
  
; LFO envelope, completes 4 cycles during one whole note, starts high
se_ve_fallingLFO2:
  ;;;  8 10 12 13 13 12 10 8
  .db $0D, $0C, $09, $07, $08, $0A, $0C, $0E
  .db $0D, $0C, $09, $07, $08, $0A, $0C, $0E
  .db $0D, $0C, $09, $07, $08, $0A, $0C, $0E
  .db $0D, $0C, $09, $07, $08, $0A, $0C, $0E
  
  .db $FF  ; end
  
se_ve_fallingconstant0A:
  .db $0A
  .db $FF  ; end
  
  
;; For Day theme

; quick, quiet snare
se_ve_fallingsnare2:
  .db $0A, $07, $03, $00
  .db $FF  ; end
  
; quick, quiet kick
se_ve_fallingkick1:
  .db $0A, $07, $03, $00
  .db $FF  ; end
  
; very long fade out
se_ve_fallingfadeout:
  .db $0A, $0A, $0A, $0A, $0A, $09, $09, $09, $08, $08
  .db $08, $07, $07, $06, $06, $05, $05, $04, $04, $03
  .db $03, $02, $02, $01, $00
  .db $FF  ; end
  
  