  processor 6502
  org $1001               ; Unexpanded VIC

; BASIC stub (unexpanded vic)
  dc.w $100b              ; Pointer to next BASIC line
  dc.w 1981               ; BASIC Line#
  dc.b $9e                ; BASIC SYS token
  dc.b $34,$31,$30,$39    ; 4109 (ML start)
  dc.b 0                  ; End of BASIC line
  dc.w 0                  ; End of BASIC program

getRandom:
  lda #0 ;clear the accumulator
  adc .seed
  adc $9003 ;add random number from raster memory (can change this to somewhere else if needed)
  sta .seed
  jsr $ffd2 ;for now print the value
  rts

.seed dc.b #74 ;constant seed
