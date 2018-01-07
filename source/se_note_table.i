;NTSC Period Lookup Table.  Thanks Celius!
;http://www.freewebs.com/the_bott/NotesTableNTSC.txt
note_table:
  .dw																 $07F1, $0780, $0713 ; A1-B1 ($00-$02)
  .dw $06AD, $064D, $05F3, $059D, $054D, $0500, $04B8, $0475, $0435, $03F8, $03BF, $0389 ; C2-B2 ($03-$0E)
  .dw $0356, $0326, $02F9, $02CE, $02A6, $027F, $025C, $023A, $021A, $01FB, $01DF, $01C4 ; C3-B3 ($0F-$1A)
  .dw $01AB, $0193, $017C, $0167, $0151, $013F, $012D, $011C, $010C, $00FD, $00EF, $00E2 ; C4-B4 ($1B-$26)
  .dw $00D2, $00C9, $00BD, $00B3, $00A9, $009F, $0096, $008E, $0086, $007E, $0077, $0070 ; C5-B5 ($27-$32)
  .dw $006A, $0064, $005E, $0059, $0054, $004F, $004B, $0046, $0042, $003F, $003B, $0038 ; C6-B6 ($33-$3E)
  .dw $0034, $0031, $002F, $002C, $0029, $0027, $0025, $0023, $0021, $001F, $001D, $001B ; C7-B7 ($3F-$4A)
  .dw $001A, $0018, $0017, $0015, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D ; C8-B8 ($4B-$56)
  .dw $000C, $000C, $000B, $000A, $000A, $0009, $0008								     ; C9-F#9 ($57-$5D)
  .dw $08FF																			     ; Dummy rest note ($5E)
  
  ; Noise frequencies, RNG Mode 0 ($5F - $6E)
  .dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $000F
  ; Noise frequencies, RNG Mode 1 ($6F - $7E)
  .dw $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087, $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F

; Aliases for note values above
; Note: octaves in music traditionally start at C, not A    
A1 = $00    ; the "1" means Octave 1
As1 = $01   ; the "s" means "sharp"
Bb1 = $01   ; the "b" means "flat"  A# == Bb, so same value
B1 = $02

C2 = $03
Cs2 = $04
Db2 = $04
D2 = $05
Ds2 = $06
Eb2 = $06
E2 = $07
F2 = $08
Fs2 = $09
Gb2 = $09
G2 = $0A
Gs2 = $0B
Ab2 = $0B
A2 = $0C
As2 = $0D
Bb2 = $0D
B2 = $0E

C3 = $0F
Cs3 = $10
Db3 = $10
D3 = $11
Ds3 = $12
Eb3 = $12
E3 = $13
F3 = $14
Fs3 = $15
Gb3 = $15
G3 = $16
Gs3 = $17
Ab3 = $17
A3 = $18
As3 = $19
Bb3 = $19
B3 = $1a

C4 = $1b
Cs4 = $1c
Db4 = $1c
D4 = $1d
Ds4 = $1e
Eb4 = $1e
E4 = $1f
F4 = $20
Fs4 = $21
Gb4 = $21
G4 = $22
Gs4 = $23
Ab4 = $23
A4 = $24
As4 = $25
Bb4 = $25
B4 = $26

C5 = $27
Cs5 = $28
Db5 = $28
D5 = $29
Ds5 = $2a
Eb5 = $2a
E5 = $2b
F5 = $2c
Fs5 = $2d
Gb5 = $2d
G5 = $2e
Gs5 = $2f
Ab5 = $2f
A5 = $30
As5 = $31
Bb5 = $31
B5 = $32

C6 = $33
Cs6 = $34
Db6 = $34
D6 = $35
Ds6 = $36
Eb6 = $36
E6 = $37
F6 = $38
Fs6 = $39
Gb6 = $39
G6 = $3a
Gs6 = $3b
Ab6 = $3b
A6 = $3c
As6 = $3d
Bb6 = $3d
B6 = $3e

C7 = $3f
Cs7 = $40
Db7 = $40
D7 = $41
Ds7 = $42
Eb7 = $42
E7 = $43
F7 = $44
Fs7 = $45
Gb7 = $45
G7 = $46
Gs7 = $47
Ab7 = $47
A7 = $48
As7 = $49
Bb7 = $49
B7 = $4a

C8 = $4B
Cs8 = $4C
Db8 = $4C
D8 = $4D
Ds8 = $4E
Eb8 = $4E
E8 = $4F
F8 = $50
Fs8 = $51
Gb8 = $51
G8 = $52
Gs8 = $53
Ab8 = $53
A8 = $54
As8 = $55
Bb8 = $55
B8 = $56

C9 = $57
Cs9 = $58
Db9 = $58
D9 = $59
Ds9 = $5A
Eb9 = $5A
E9 = $5B
F9 = $5C
Fs9 = $5D
Gb9 = $5D

rest = $5E	; rest alias
r = $5E		; alternate rest alias
rr = $5E	; alternate rest alias

; Noise aliases
N0_0 = $5F	; mode 0, freq 1
N0_1 = $60	; mode 0, freq 2
N0_2 = $61
N0_3 = $62
N0_4 = $63
N0_5 = $64
N0_6 = $65
N0_7 = $66
N0_8 = $67
N0_9 = $68
N0_A = $69
N0_B = $6A
N0_C = $6B
N0_D = $6C
N0_E = $6D
N0_F = $6E
N1_0 = $6F	; mode 1, freq 1
N1_1 = $70	; mode 1, freq 2
N1_2 = $71
N1_3 = $72
N1_4 = $73
N1_5 = $74
N1_6 = $75
N1_7 = $76
N1_8 = $77
N1_9 = $78
N1_A = $79
N1_B = $7A
N1_C = $7B
N1_D = $7C
N1_E = $7D
N1_F = $7E




