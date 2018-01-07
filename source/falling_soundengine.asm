;;;; Sound Engine (FALLING) ;;;;
;; Based on Nerdy Nights Sound tutorial (http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=23452)
; Sound is organized into 6 streams, including 4 dedicated music streams, and two SFX streams.
; Music/SFX streams are listed by priority.
; Streams with higher indices have higher priority and will overwrite the data coming in from lower priority streams.
; SFX have highest priority so they will always play above music.
; When an SFX stream takes over a sound channel, music streams will continue but that channel's music stream will be overtaken by the SFX.
; Songs and SFX will be loaded from .i files.

; TODO: Implement last features of http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=26247


;;; Approximate tempo chart ;;;;
; Equation: Y = (17/30)*BPM + (2/3)
; 110 BPM = $3F
; 140 BPM = $50
; 450 BPM = $FF


; Store sound engine variables starting at $0300
  .rsset $0300
  
;;; Variables ;;;
sound_disable_flag		.rs 1  ; state of sound engine (0=on, 1=off)
sound_temp1 			.rs 1  ; temporary variables
sound_temp2 			.rs 1
sound_sq1_old			.rs 1  ; last value written to $4003 (used to avoid crackling in squares)
sound_sq2_old			.rs 1  ; last value written to $4007 (used to avoid crackling in squares)
jmp_ptr					.rs 2  ; pointer used for indirect jumping
pause_flag				.rs 1  ; flag set on pause to force lower volume envelopes on music streams
pause_temp				.rs 1  ; temp variable to store duty and counter settings during pause filter
  
;; Data streams
stream_curr_sound 			.rs 6  ; song/sfx currently playing on stream
stream_status				.rs 6  ; status byte (Bit0: 0=stream disabled, 1=stream enabled; Bit1: 0=not resting, 1=resting)
stream_channel 				.rs 6  ; channel that stream is playing on
stream_duty 				.rs 6  ; initial duty settings for this stream (volume overwritten by envelope)
stream_volenv				.rs 6  ; current volume envelope
stream_volenv_index			.rs 6  ; current position within the volume envelope
stream_ptr_LO 				.rs 6  ; low byte of pointer to data stream
stream_ptr_HI 				.rs 6  ; high byte of pointer to data stream
stream_tempo 				.rs 6  ; the value to add to our ticker total each frame
stream_note_LO 				.rs 6  ; low 8 bits of period for the current note playing on the stream
stream_note_HI 				.rs 6  ; high 3 bits of the note period
stream_ticker_total 		.rs 6  ; our running ticker total.
stream_note_length_counter	.rs 6  ; how long a note should be played (next note will be loaded and played when this reaches 0)
stream_note_length 			.rs 6  ; keeps track of last note length encountered in stream (this way, several notes can follow one note length)
stream_loop1_counter		.rs 6  ; finite looping counter for loop 1
stream_loop1_address		.rs 6  ; finite looping address for loop 1
stream_loop2_counter		.rs 6  ; finite looping counter for loop 2
stream_loop2_address		.rs 6  ; finite looping address for loop 2

;; APU buffering
 ; Bytes 0-3:	Square 1 ports ($4000-$4003) 
 ; Bytes 4-7:	Square 2 ports ($4004-$4007)
 ; Bytes 8-11:	Triangle ports ($4008-$400B)
 ; Bytes 12-15:	Noise ports    ($400C-$400F)
soft_apu_ports				.rs 16 ; reserve 16 bytes for APU buffering

  
;;; Constants ;;;
NUMSTREAMS = 6	 ; number of streams allocated

; Stream aliases
MUSIC_SQ1 = $00  ; Music square wave 1 channel
MUSIC_SQ2 = $01  ; Music square wave 2 channel
MUSIC_TRI = $02  ; Music triangle wave channel
MUSIC_NOI = $03  ; Music noise channel
SFX_1	  = $04  ; SFX channel 1 (can be set to any sound channel)
SFX_2	  = $05  ; SFX channel 2 (can be set to any sound channel)

; Channel aliases
SQUARE_1 	= $00
SQUARE_2 	= $01
TRIANGLE 	= $02
NOISE   	= $03


;; Note length lookup table (order must match note length aliases)
note_length_table:
  .db $01  ; 32nd note (shortest)
  .db $02  ; 16th note
  .db $04  ; Eighth note
  .db $08  ; Quarter note
  .db $10  ; Half note
  .db $20  ; Whole note
  .db $03  ; Dotted 16th note
  .db $06  ; Dotted 8th note
  .db $0C  ; Dotted quarter note
  .db $18  ; Dotted half note
  .db $30  ; Dotted whole note
  .db $05  ; Swing note: 5/32
  .db $0A  ; Swing note: 5/16 = 10/32
  .db $0E  ; Swing note: 7/16 = 14/32
  .db $07  ; Swing note: 7/32
  .db $0B  ; Swing note: 11/32
  .db $16  ; Swing note: 11/16 = 22/32
; Note length aliases (order must match note lookup table)
n_32		= $80  ; 32nd note
n_16		= $81  ; 16th note
n_8 		= $82  ; Eighth note
n_4 		= $83  ; Quarter note
n_2 		= $84  ; Half note
n_1 		= $85  ; Whole note
n_d16		= $86  ; Dotted 16th note
n_d8 		= $87  ; Dotted Eighth note
n_d4 		= $88  ; Dotted Quarter note
n_d2 		= $89  ; Dotted Half note
n_d1 		= $8A  ; Dotted Whole note
n_s5_32		= $8B  ; Swing note: 5/32
n_s5_16		= $8C  ; Swing note: 5/16 = 10/32
n_s7_16		= $8D  ; Swing note: 7/16 = 14/32
n_s7_32		= $8E  ; Swing note: 7/32
n_s11_32	= $8F  ; Swing note: 11/32
n_s11_16	= $90  ; Swing note: 11/16 = 22/32


; Volume envelope pointer table
volume_envelopes:
  .dw se_ve_muted
  .dw se_ve_constant
  .dw se_ve_stac1
  .dw se_ve_stac2
  .dw se_ve_fadein
  .dw se_ve_fadeout1
  .dw se_ve_fadeout2
  .dw se_ve_stac_echo
  .dw se_ve_tri1
  .dw se_ve_drumkick
  .dw se_ve_drumsnare1
  .dw se_ve_drumsnare2
  .dw se_ve_drumhat
  .dw se_ve_drumhat2
  .dw se_ve_drumhat3
  .dw se_ve_drumhat4
  .dw se_ve_drumcrash1
  .dw se_ve_fallinghat1
  .dw se_ve_fallingsnare1
  .dw se_ve_fallingLFO1
  .dw se_ve_fallingLFO2
  .dw se_ve_fallingconstant0A
  .dw se_ve_fallingsnare2
  .dw se_ve_fallingkick1
  .dw se_ve_fallingfadeout
; Volume envelope aliases
ve_muted 		= $00
ve_constant 	= $01
ve_stac1 		= $02
ve_stac2		= $03
ve_fadein 		= $04
ve_fadeout1		= $05
ve_fadeout2		= $06
ve_stac_echo 	= $07
ve_tri1			= $08
ve_drumkick 	= $09
ve_drumsnare1 	= $0A
ve_drumsnare2 	= $0B
ve_drumhat 		= $0C
ve_drumhat2		= $0D
ve_drumhat3		= $0E
ve_drumhat4		= $0F
ve_drumcrash1	= $10
ve_fallinghat1			= $11
ve_fallingsnare1 		= $12
ve_fallingLFO1			= $13
ve_fallingLFO2			= $14
ve_fallingconstant0A 	= $15
ve_fallingsnare2 		= $16
ve_fallingkick1 		= $17
ve_fallingfadeout 		= $18

; Opcode jump table
sound_opcodes:
  .dw se_op_endsound			; should be $A0
  .dw se_op_change_ve			; should be $A1
  .dw se_op_change_duty			; should be $A2
  .dw se_op_change_tempo		; should be $A3
  .dw se_op_inf_loop			; should be $A4
  .dw se_op_loop1_set_counter	; should be $A5
  .dw se_op_loop1_set_address	; should be $A6
  .dw se_op_loop2_set_counter	; should be $A7
  .dw se_op_loop2_set_address	; should be $A8
; Opcode aliases
endsound 		= $A0
change_ve 		= $A1
change_duty		= $A2
change_tempo	= $A3
inf_loopto		= $A4
loop1for 		= $A5
loop1to			= $A6
loop2for 		= $A7
loop2to			= $A8
; Alternate opcode aliases
loopfor 		= $A5
loopto			= $A6  
  
  
;;; Entrances (sound engine accessor functions) ;;;
sound_init:
  LDA #%00001111
  STA $4015
  
  LDA #$00
  STA sound_disable_flag	; clear disable flag
  
  LDA #$FF
  STA sound_sq1_old
  STA sound_sq2_old
  
se_silence:
  LDA #$30
  STA soft_apu_ports+0		; set SQ1 volume to 0
  STA soft_apu_ports+4		; set SQ2 volume to 0
  STA soft_apu_ports+12		; set NOISE volume to 0
  
  LDA #$80
  STA soft_apu_ports+8		; silence TRIANGLE
  
  RTS  ; end of sound_init
  
sound_disable:
  LDA #$00
  STA $4015					; disable all sound channels
  LDA #$01
  STA sound_disable_flag	; set disable flag
  
  RTS
  
  
; sound_load will prepare the sound engine to play a song or sfx.
;   input A: song/sfx number to play
sound_load:
  STA sound_temp1			; save song number
  ASL A						; multiply by 2. we are indexing into a table of pointers (words)
  TAY
  LDA song_headers, y		; setup the pointer to our song header
  STA sound_ptr
  LDA song_headers+1, y
  STA sound_ptr+1
  
  LDY #$00
  LDA [sound_ptr], y		; read byte: # streams
  STA sound_temp2			; store in a temp variable. we will use this as a loop counter: how many streams to read stream headers for
  INY
.loop:
  LDA [sound_ptr], y		; read byte: stream number
  TAX						; stream number acts as our variable index
  INY
  
  LDA [sound_ptr], y		; read byte: status (1=enable, 0=disable)
  STA stream_status, x
  BEQ .next_stream			; if status byte is 0, stream disabled, so we are done
  INY
  
  LDA [sound_ptr], y		; read byte: channel number
  STA stream_channel, x
  INY
  
  LDA [sound_ptr], y		; read byte: initial duty settings
  STA stream_duty, x
  INY
  
  LDA [sound_ptr], y		; read byte: volume envelope
  STA stream_volenv, x
  INY
  
  LDA [sound_ptr], y		; read byte: pointer to stream data, LO byte (little endian, so low byte first)
  STA stream_ptr_LO, x
  INY
  
  LDA [sound_ptr], y		; read byte: pointer to stream data, HI byte (little endian, so high byte last)
  STA stream_ptr_HI, x
  INY
  
  LDA [sound_ptr], y		; read byte: initial tempo
  STA stream_tempo, x
  
  ; Initializations for stream variables not passed through header
  LDA #$00					; initialize volume envelope index (start of envelope)
  STA stream_volenv_index, x
  
  LDA #$FF					; initialize ticker counters (large value so first tick will happen quickly)
  STA stream_ticker_total, x
  
  LDA #$01					; initialize note length counters
  STA stream_note_length_counter, x
  
  LDA #$00					; initialize finite loop counters
  STA stream_loop1_counter, x
  LDA #$00					; initialize finite loop counters
  STA stream_loop2_counter, x
  
.next_stream:
  INY
  
  LDA sound_temp1			; song number
  STA stream_curr_sound, x
  
  DEC sound_temp2			; our loop counter
  BNE .loop
  RTS

  
; sound_play_frame advances the sound engine by one frame
sound_play_frame:
  LDA sound_disable_flag
  BNE .done   				; if disable flag is set, don't advance a frame


  LDX #$00
.loop:
  LDA stream_status, x
  AND #$01								; check whether the stream is active
  BEQ .nextstream						; if not, skip it
  
  LDA stream_ticker_total, x
  CLC
  ADC stream_tempo, x					; add the tempo to the ticker total. a "tick" will happen on overflow.
  STA stream_ticker_total, x
  BCC .nextstream						; if no overflow occured, there was no tick. we're done with this stream.
.tick
  DEC stream_note_length_counter, x		; also decrement the note length counter
  BNE .tick_update						; if counter is non-zero, our note isn't finished playing yet, end
.note_finished
  LDA stream_note_length, x				; else our note is finished. reload the note length counter
  STA stream_note_length_counter, x
  
  JSR se_fetch_byte						; if the note is finished, advance the stream
.tick_update
  JSR se_set_temp_ports					; populate port buffers with new stream data (happens on every tick)
  
.nextstream:
  INX
  CPX #NUMSTREAMS						; check if there is another stream
  BNE .loop								; end after all streams have been checked and/or played
  
.endloop
  JSR se_set_apu						; write data to APU (streams are buffered above and written all at once)
  
.done:
  RTS
  
  
  
sound_pause:
; Runs when game is paused
  LDA #$01
  STA pause_flag	; set pause flag to activate volume filter
  RTS
  
sound_unpause:
; Runs when game is unpaused
  LDA #$00
  STA pause_flag	; clear pause flag to deactivate volume filter
  RTS
  
  
;;; Internal Subroutines ;;;

; se_fetch_byte reads one byte from a sound data stream and handles it.
;   input X: stream number
se_fetch_byte:
  LDA stream_ptr_LO, x		; get LO byte of pointer to note data stream
  STA sound_ptr
  LDA stream_ptr_HI, x		; get HI byte of pointer to note data stream
  STA sound_ptr+1
  
  LDY #$00
.fetch:
  LDA [sound_ptr], y		; check next byte and determine whether it is Note, Note Length, or Opcode data
  BPL .note					; if < $80, it's a Note
  CMP #$A0
  BCC .note_length			; else if < $A0, it's a Note Length
.opcode:					; else it's an Opcode
  JSR se_opcode_launcher	; run opcode launcher (once opcode is run, it will RTS back here)
  INY						; next position in the data stream
  LDA stream_status, x
  
  AND #%00000001
  BNE .fetch				; after our opcode is done, grab another byte unless the stream is disabled
  JMP .end					; if the stream is disabled, quit (otherwise, fetch next note).
  
.note_length:
  AND #%01111111			; zero out Bit7 (subtracts $80 to align note length aliases with lookup table offsets)
  STY sound_temp1			; save Y because we are about to destroy it
  TAY
  LDA note_length_table, y				; get the note length count value
  STA stream_note_length, x				; save the note length in RAM so we can use it to refill the counter
  STA stream_note_length_counter, x		; stick it in our note length counter
  LDY sound_temp1			; restore Y
  INY						; set index to next byte in the stream
  JMP .fetch				; since this was a Note Length, fetch the next byte to get the Note
  
.note:
  STY sound_temp1			; save our index into the data stream
  ASL A						; muliply by 2
  TAY
  LDA note_table, y
  STA stream_note_LO, x
  LDA note_table+1, y
  STA stream_note_HI, x
  LDY sound_temp1			; restore data stream index
  
  LDA #$00					; reset volume envelope for next note
  STA stream_volenv_index, x
  
  JSR se_check_rest			; check for a rest
  
.update_pointer:
  INY
  TYA
  CLC
  ADC stream_ptr_LO, x		; increment LO byte of pointer
  STA stream_ptr_LO, x
  BCC .end
  INC stream_ptr_HI, x		; if LO byte wrapped, increment HI byte
  
.end:
  RTS

  
se_opcode_launcher:
  STY sound_temp1			; save y register, because we are about to destroy it
  SEC
  SBC #$A0					; turn our opcode byte into a table index by subtracting $A0 ($A0->$00, $A1->$01, $A2->$02, etc. Tables index from $00.)
  ASL A						; multiply by 2 because we index into a table of addresses (words)
  TAY
  LDA sound_opcodes, y		; get low byte of subroutine address
  STA jmp_ptr
  LDA sound_opcodes+1, y	; get high byte
  STA jmp_ptr+1
  LDY sound_temp1			; restore our y register
  INY						; set to next position in data stream (assume an argument)
  JMP [jmp_ptr]				; indirect jump to our opcode subroutine
  ; The opcode subroutine will RTS, returning to the JSR call in se_fetch_byte.
  
  
; se_check_rest reads the last note byte to see if it is our dummy "rest" note
se_check_rest:
  LDA [sound_ptr], y		; read the last note byte again
  CMP #rest					; is it a rest ($5E)?
  BNE .not_rest
  LDA stream_status, x
  ORA #%00000010			; if so, set the rest bit in the status byte
  BNE .store				; (this will always branch, but BNE is cheaper than a JMP)
.not_rest:
  LDA stream_status, x
  AND #%11111101			; if not, clear the rest bit in the status byte
.store:
  STA stream_status, x
  RTS
  
; se_set_apu writes buffered stream data to the APU ports.
; To avoid crackling generated by writing to square ports $4003 and $4007 too often, we only write if there was a note change.
se_set_apu:
.square1:
  LDA soft_apu_ports+0
  STA $4000
  LDA soft_apu_ports+1
  STA $4001
  LDA soft_apu_ports+2
  STA $4002
  LDA soft_apu_ports+3
  CMP sound_sq1_old			; compare to value last written to $4003
  BEQ .square2				; don't write this frame if it's unchanged
  STA $4003	
  STA sound_sq1_old			; save the value we just wrote to $4003
.square2:
  LDA soft_apu_ports+4
  STA $4004
  LDA soft_apu_ports+5
  STA $4005
  LDA soft_apu_ports+6
  STA $4006
  LDA soft_apu_ports+7
  CMP sound_sq2_old			; compare to value last written to $4007
  BEQ .triangle				; don't write this frame if it's unchanged
  STA $4007
  STA sound_sq2_old			; save the value we just wrote to $4007
.triangle:
  LDA soft_apu_ports+8
  STA $4008
  LDA soft_apu_ports+10		; $4009 is unused, so we skip it
  STA $400A
  LDA soft_apu_ports+11
  STA $400B
.noise:
  LDA soft_apu_ports+12
  STA $400C
  LDA soft_apu_ports+14		; $400D is unused, so we skip it
  STA $400E
  LDA soft_apu_ports+15
  STA $400F;$81E9
  RTS
  
; se_set_temp_ports populates port buffers (soft_apu_ports) with stream data
se_set_temp_ports:
  LDA stream_channel, x		; load the channel number of the stream and use it find the soft_apu_ports index for that channel
  ASL A
  ASL A
  TAY
 
  JSR se_set_stream_volume
 
  LDA #$08					; *disable sweep
  STA soft_apu_ports+1, y	; sweep
 
  LDA stream_note_LO, x
  STA soft_apu_ports+2, y	; period LO
 
  LDA stream_note_HI, x
  STA soft_apu_ports+3, y	; period HI
  
  RTS
  
; se_set_stream_volume modifies a stream's volume data using its volume envelope
se_set_stream_volume:
  STY sound_temp1				; save our index into soft_apu_ports (we are about to destroy Y)
 
  LDA stream_volenv, x			; which volume envelope?
  ASL A							; multiply by 2 because we are indexing into a table of addresses (words)
  TAY
  LDA volume_envelopes, y		; get the low byte of the address from the pointer table
  STA sound_ptr					; put it into our pointer variable
  LDA volume_envelopes+1, y		; get the high byte of the address
  STA sound_ptr+1
 
.read_ve:
  LDY stream_volenv_index, x	; our current position within the volume envelope.
  LDA [sound_ptr], y			; grab the value.
  CMP #$FF
  BNE .set_vol					; if not FF, set the volume
  DEC stream_volenv_index, x	; else if FF, go back one and read again
  JMP .read_ve					; ($FF essentially tells us to repeat the last volume value for the remainder of the note)
   
.set_vol:
  STA sound_temp2				; save our new volume value (about to destroy A)
  
  CPX #TRIANGLE					; triangle needs to be handled specially (a $00 in envelope should clear bits 0-6, not just 0-3)
  BNE .squares					; if not triangle channel, go ahead
  LDA sound_temp2
  BNE .squares					; else if volume not zero, go ahead (treat same as squares)
  LDA #$80
  BMI .store_vol				; else silence the channel with #$80
.squares:
  LDA stream_duty, x			; get current vol/duty settings
  AND #$F0						; zero out the old volume (preserving duty setting)
  ORA sound_temp2				; OR our new volume in
  
.store_vol:
  JSR se_pause_filter			; if a pause state is active, lower volume before writing

  LDY sound_temp1				; get our index into soft_apu_ports
  STA soft_apu_ports, y			; store the volume in our temp port
  INC stream_volenv_index, x	; set our volume envelop index to the next position

.rest_check
  ; Check the rest flag. If set, overwrite the volume data we just loaded into buffer with a silence value.
  LDA stream_status, x
  AND #%00000010			; check rest flag
  BEQ .done					; if clear, no rest, so quit
  LDA stream_channel, x
  CMP #TRIANGLE				; if triangle, silence with #$80
  BEQ .rest_tri        
  LDA #$30					; else, silence with #$30
  BNE .rest_store			; (this will always branch, but BNE is cheaper than a JMP)
.rest_tri:
  LDA #$80
.rest_store:
  STA soft_apu_ports, y
  
.done
  RTS
  
; When a pause state is active, se_pause_filter decreases the incoming volume before a write to soft_apu_ports.
se_pause_filter:
  PHA				; save incoming volume to stack
  AND #$0F			; clear all duty and counter data from A, leaving only last 4 volume bits
  STA pause_temp	; store volume-only data
  
  LDA pause_flag	; check pause flag
  BEQ .nopause		; if flag is not set, just return incoming volume
  
  CPX #SFX_1		; check which stream we're on. we only want to lower music streams.
  BCS .nopause		; if X >= SFX_1, just return incoming volume

; SQ_1 usually functions as the bass. Lower this only a little.
  LDA stream_channel, x
  CMP #SQUARE_1
  BNE .sq1_done		; not SQ_1
  
  LDA pause_temp				; load volume-only data
  TAY							; copy volume to Y for lookup
  SEC
  SBC VolumeScaling_SQ1, y		; subtract scaling in lookup table from A
  STA pause_temp				; store the new volume
  
  PLA							; retrieve original incoming volume
  AND #$F0						; clear volume bits
  ORA pause_temp				; and replace with new volume
  
  JMP .done						; return scaled volume in A
.sq1_done:
  
; SQ_2 usually functions as treble. Lower this a lot.
  LDA stream_channel, x
  CMP #SQUARE_2
  BNE .sq2_done		; not SQ_2
  
  LDA pause_temp				; load volume-only data
  TAY							; copy volume to Y for lookup
  SEC
  SBC VolumeScaling_SQ2, y		; subtract scaling in lookup table from A
  STA pause_temp				; store the new volume
  
  PLA							; retrieve original incoming volume
  AND #$F0						; clear volume bits
  ORA pause_temp				; and replace with new volume
  
  JMP .done						; return scaled volume in A
.sq2_done:

; TRI cannot be lowered, so mute it.
  LDA stream_channel, x
  CMP #TRIANGLE
  BNE .tri_done		; not TRI
  
  PLA				; retrieve incoming volume just to get it off the stack
  LDA #$80			; overwrite volume with $80 to mute triangle
  JMP .done			; return
.tri_done:

; NOI functions as percussion. Lower this only a little.
  LDA stream_channel, x
  CMP #NOISE
  BNE .noi_done		; not NOI
  
  LDA pause_temp				; load volume-only data
  TAY							; copy volume to Y for lookup
  SEC
  SBC VolumeScaling_NOI, y		; subtract scaling in lookup table from A
  STA pause_temp				; store the new volume
  
  PLA							; retrieve original incoming volume
  AND #$F0						; clear volume bits
  ORA pause_temp				; and replace with new volume
  
  JMP .done						; return scaled volume in A
.noi_done:

.nopause
  PLA				; retrieve original volume from stack and end
.done:
  RTS
  
; Volume scaling lookup tables. If incoming volume is A ($00-$0F), volume will be decreased by byte with index A.
  ;; $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F		; input
VolumeScaling_SQ1:
 .db $00, $00, $00, $01, $02, $03, $04, $04, $05, $06, $06, $07, $07, $07, $08, $08		; subtraction
VolumeScaling_SQ2:
 .db $00, $01, $01, $02, $02, $03, $04, $05, $06, $07, $08, $08, $09, $09, $0A, $0A		; subtraction
VolumeScaling_NOI:
 .db $00, $00, $00, $01, $01, $02, $02, $03, $03, $04, $05, $06, $06, $07, $07, $08		; subtraction
 
;; Opcode handlers
se_op_endsound:
  ; Ends all reading of the stream.
  ; Argument byte(s): N/A
  ; Usage:
  ;   .db n_4, C4, D4, E4, F4
  ;   .db endsound
  LDA stream_status, x		; we've reached end of stream, so disable it and silence
  AND #%11111110
  STA stream_status, x		; clear enable flag in status byte
  LDA stream_channel, x
  CMP #TRIANGLE
  BEQ .silence_tri			; triangle is silenced differently from squares and noise
  LDA #$30					; squares and noise silenced with $30
  BNE .silence
.silence_tri:
  LDA #$80					; triangle silenced with $80
.silence:
  STA stream_duty, x		; store silence value in the stream's volume variable.
  RTS

se_op_change_ve:
  ; Changes the volume envelope used by subsequent notes.
  ; Argument byte(s): [1] Volume envelope number/alias
  ; Usage:
  ;   .db n_4, C4, D4, E4, F4
  ;   .db change_ve
  ;   .db ve_stac1
  ;   .db n_4, C4, D4, E4, F4
  LDA [sound_ptr], y			; read the argument
  STA stream_volenv, x			; store it in our volume envelope variable
  LDA #$00
  STA stream_volenv_index, x	; reset volume envelope index to the beginning
  RTS
  
se_op_change_duty:
  ; Changes the duty cycle used by subsequent notes.
  ; Argument byte(s): [1] New duty cycle byte
  ; Usage:
  ;   .db n_4, C4, D4, E4, F4
  ;   .db change_duty
  ;   .db $B7
  ;   .db n_4, C4, D4, E4, F4
  LDA [sound_ptr], y		; read the argument (which duty cycle to change to)
  STA stream_duty, x		; store it.
  RTS
  
se_op_change_tempo:
  ; Changes the tempo used by subsequent notes.
  ; Argument byte(s): [1] New tempo
  ; Usage:
  ;   .db n_4, C4, D4, E4, F4
  ;   .db change_tempo
  ;   .db $80
  ;   .db n_4, C4, D4, E4, F4
  LDA [sound_ptr], y		; read the argument 
  STA stream_tempo, x		; store it in our tempo variable
  RTS 

se_op_inf_loop:
  ; Loops to a label to repeat a segment of notes (indefinitely).
  ; Argument byte(s): [1] Loop address (LO byte), [2] Loop address (HI byte)
  ; Usage:
  ;   .db n_4, C4, D4, E4, F4
  ; .loop_point
  ;   .db n_4, C5, D5, E5, F5
  ;   .db inf_loopto
  ;   .dw .loop_point
  LDA [sound_ptr], y		; read LO byte of the address argument from the data stream
  STA stream_ptr_LO, x		; save as our new data stream position
  INY
  LDA [sound_ptr], y		; read HI byte of the address argument from the data stream
  STA stream_ptr_HI, x		; save as our new data stream position data stream position

  STA sound_ptr+1			; update the pointer to reflect the new position.
  LDA stream_ptr_LO, x
  STA sound_ptr
  LDY #$FF					; After opcodes return, we do an INY. Since we reset the stream buffer position, we will want y to start out at $00 again.
  RTS

se_op_loop1_set_counter:
  ; Sets the counter for how many times we should loop. Must be done before label used as finite looping address.
  ; Argument byte(s): [1] Number of times to loop
  ; Usage:
  ;   .db n_4, C4, D4, E4, F4
  ;   .db loopfor, $08
  ; .loop_point
  ;   .db n_4, C5, D5, E5, F5
  ;   ... (see below)
  LDA [sound_ptr], y					; read the argument (# times to loop)
  STA stream_loop1_counter, x			; store it in the loop counter variable
  RTS
  
se_op_loop1_set_address:
  ; Sets the address where we will loop to. Loop counter must be set before the label of this address.
  ; Argument byte(s): [1] Loop address (LO byte), [2] Loop address (HI byte)
  ; Usage:
  ;   .db n_4, C4, D4, E4, F4
  ;   .db loopfor, $08
  ; .loop_point
  ;   .db n_4, C5, D5, E5, F5
  ;   .db loopto
  ;   .dw .loop_point
  DEC stream_loop1_counter, x		; decrement the counter
  LDA stream_loop1_counter, x		; check the counter
  BEQ .last_iteration				; if zero, we are done looping
  JMP se_op_inf_loop 				; if not zero, run a loop
.last_iteration:
  INY								; skip the first byte of the address argument. the second byte will be skipped automatically upon return.
  RTS
  
se_op_loop2_set_counter:
  ; Sets the counter for how many times we should loop. Must be done before label used as finite looping address.
  ; Argument byte(s): [1] Number of times to loop
  ; Usage: (Same as se_op_loop1_set_counter)
  LDA [sound_ptr], y				; read the argument (# times to loop)
  STA stream_loop2_counter, x		; store it in the loop counter variable
  RTS
  
se_op_loop2_set_address:
  ; Sets the address where we will loop to. Loop counter must be set before the label of this address.
  ; Argument byte(s): [1] Loop address (LO byte), [2] Loop address (HI byte)
  ; Usage: (Same as se_op_loop1_set_address)
  DEC stream_loop2_counter, x		; decrement the counter
  LDA stream_loop2_counter, x		; check the counter
  BEQ .last_iteration				; if zero, we are done looping
  JMP se_op_inf_loop				; if not zero, run a loop
.last_iteration:
  INY								; skip the first byte of the address argument. the second byte will be skipped automatically upon return.
  RTS
  
  
;;; Tables and Includes ;;;
  
;; Note period lookup table
  .include "se_note_table.i"
  
;; Constants for percussion noise samples
  .include "se_percussion.i"

;; Volume envelopes (aliases and pointers at top)
  .include "se_envelopes.i"
  .include "se_envelopes_falling.i"  ; extra custom envelopes
  
;; Pointers and song data

; Song pointer table (each entry is a pointer to a song header)
song_headers:
  .dw silence_header			; Music: silence
  .dw themeTitle_header			; Music: Day mode theme
  .dw themeDay_header			; Music: Day mode theme
  .dw themeSunset_header		; Music: Sunset mode theme
  .dw themeNight_header			; Music: Night mode theme
  .dw sfxCoin_header			; SFX: Coin pickup
  .dw sfxLife_header			; SFX: Extra life pickup
  .dw sfxObst_header			; SFX: Obstacle collision
  .dw sfxPause_header			; SFX: Pause
  .dw sfxUnpause_header			; SFX: Unpause
  .dw sfxGameover_header		; SFX: Game over
  
  
  ;.dw drumtest_header
  ;.dw noisetest_header
  ;.dw envtest_header
  
  
; Song files
  .include "s_silence.i"
  .include "s_themeTitle.i"
  .include "s_themeDay.i"
  .include "s_themeSunset.i"
  .include "s_themeNight.i"
  .include "s_sfxCoin.i"
  .include "s_sfxLife.i"
  .include "s_sfxObst.i"
  .include "s_sfxPause.i"
  .include "s_sfxUnpause.i"
  .include "s_sfxGameover.i"

  
  ;.include "s_drumtest.i"
  ;.include "s_noisetest.i"
  ;.include "s_envtest.i"

; Song aliases
sng_Silence 	= $00
sng_Title 		= $01
sng_DayMode 	= $02
sng_SunsetMode 	= $03
sng_NightMode 	= $04
sfx_Coin 		= $05
sfx_Life 		= $06
sfx_Obst 		= $07
sfx_Pause		= $08
sfx_Unpause		= $09
sfx_Gameover	= $0A




  
  