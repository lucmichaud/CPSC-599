;Test 02 for level
;TODO: Fix how level is loaded - doesn't look like test 08
;get character moving to bottom screen
;collision animation - prevent character from breaking wall - FIXED (But code is trashy)

;Things added: lives at top left 
;lost lives if collide with enemy (circle)
;changed icon of characters 
;ability to reset game if F1 pressed
;die after run out of lives
  
  ;Oct 24, 2016
 processor 6502
 org $1001              ; Unexpanded VIC


 ;loop counter for collisions = $1002
 ;collision colour = $1003
 ;key pressed = $1004
 ;colour = $1005
 ;row top = 1006
 ;col top = 1007
; row bottom = 1008
; col bottom = 1009
;status for top/bottom = 100a
;char icon = 100a
;enemy icon = 100b
;character lives = 100c


 
 ; BASIC stub (unexpanded vic)
 dc.w $100b              ; Pointer to next BASIC line
 dc.w 1981               ; BASIC Line#
 dc.b $9e                ; BASIC SYS token
 dc.b $34,$31,$30,$39    ; 4109 (ML start)
 dc.b 0                  ; End of BASIC line
 dc.w 0                  ; End of BASIC program

gameLoopTop:
   ;Setup new location for characters
 jsr $e55f       ; clear screen

;changes the colour of text -> page 173 vic manual
 lda #$44		 ; load new colour to acc
 sta $0286		 ; change text colour

;changes the border and background colour -> page 175 of vic do manual
 lda #$0f		 ; this makes a green border and black background
 sta $900f		 ; store in screen and border register
 ldx #$0
 lda #$44
 sta $1005
 
loadLevel:
 lda level1,x
 sta $1e00,x	; store space
 lda $1005		; colour to black
 sta $9600,x	; store colour in new location too 
 ;jsr $ffd2
 inx
 cpx #level1end-level1
 bne loadLevel
 ldy #level1end-level1
loop2:
 lda #level1,y
 ;jsr $ffd2
 sta $1f1e,y	; store space
 lda $1005		; colour to black
 sta $971e,y	; store colour in new location too 
 dey
 cpy level1
 bne loop2
 ldx #$03
 stx $100c
 
 lda #83
 sta $100a ; character symbol
 lda #81
 sta $100b	; enemy symbol
 lda #$55
 sta $1005	; colour for character
 
drawLives:		;draw lives to screen
 lda $100a
 sta $1e00,x		
 lda $1005
 sta $9600,x
 dex
 cpx #$00
 bne drawLives
;return

 lda $9005		; load character memory
 pha			; push acc onto stack
 ora #$0f		; set character memory (bits 0-3)
 sta $9005 		; store result
 bne initChars	; just a branch always over
 
gameOver: ;
;TODO: Print "Game over"
 jsr $e55f
 ;print game over to screen
gameOverEnd:	 ; bounce branch to get other subroutines to top of gameLoopTop
 lda $00c5		 ; current key held down -> page 179 of vic20 manual
 cmp #48 ;quit
 beq quit
 cmp #39 ;f1 to restart
 beq gameLoopTop	
 bne gameOverEnd
 
initChars:
 ldy $100b		; 'C' for collision
 sty $1e76		; store in the middle of the second row
 lda #$00	
 sta $1006		; row
 lda #$0b
 sta $1007		; col
 ldx $1005		;black/initializing character location on row (just convenience that it's also black)
 stx $9676		; char colour
 jsr getRowColForm
 lda $100a		; 'B'
 sta $1e00,x		; store far left second row
 lda $1005		;black/initializing character location on row (just convenience that it's also black)
 sta $9600,x		; char colour
 pla			; pull acc from stack
 sta $9005		; store in char memory
 
  ; screen registers 1e00-1fff -> 7680-8191 -> 511 
  
top:			; top of loop
 lda $9005		; load char memory
 pha			; push to stack
 lda $00c5		 ; current key held down -> page 179 of vic20 manual
 sta $1004
 cmp #39 ;f1 to restart
 beq gameOverEnd	;bounce to game over to take us to gameLoopTop
 cmp #17		 ;a pressed
 beq playleft	 ; move left	 
 cmp #18		 ;d pressed
 beq playright	 ; move right		
 cmp #9		 ;w pressed
 beq playup		
 cmp #41		 ;s pressed
 beq playdown		
 bne next		 ; neither pressed
  
playleft:
 jsr left		 ; subroutine to move left
 jmp next
  
playright:
 jsr right		; subroutine to move right
 jmp next

playup:
 jsr up
 jmp next
 
playdown:
 jsr down
 
next:
  ;Wait for user to press enter, and restore the character set
 pla			; pull acc from stack
 sta $9005 		; store in char mem
 lda $00c5		 ; current key held down -> page 179 of vic20 manual
 cmp #48		 ; check if Q is pressed -> quit
 bne top		 ;continue input
quit:
 jsr $e55f       ; clear screen before exiting
 rts			 ; quit
  
;These subroutines print the next letter of W,A,S,D (X,B,T,E) to make sure
;that we aren't just seeing W,A,S,D being typed without the code 
;working.
left:
 ldx $1006
 cpx #$00		; check if end of screen on left
 beq updateNewLocBounce	; don't move character because it is at end of left screen
 jsr updatePrevLoc
 
 dec $1006		; rows -1
 jmp updateNewLocBounce
 
right:
 ldx $1006
 cpx #$15		 ; check if x =21 (end of right)
 beq updateNewLocBounce	 ; at end of screen right
 jsr updatePrevLoc
 inc $1006 		 ; rows +1
 ldx $1006
 cpx #$00		 ; basically do a branch always to get to updateNewLoc
 bne updateNewLocBounce
 rts
 
updateNewLocBounce:	;fix branch out of range
 jmp updateNewLoc

up:
 ldx $1007
 ;cpx #$0b
 ;bpl upBot
 cpx #$00		 ; check if x < 21 (on top row)
 beq updateNewLoc	 ; at end of screen top
 jsr updatePrevLoc
 dec $1007 		 ; cols -1
 jmp updateNewLoc

upBot:
 ldx $1009
 cpx #$00
 beq updateNewLoc
 jsr updatePrevLoc
 dec $1009
 jmp updateNewLoc

down:
 ;lda #$01
 ;sta $100a
 ldx $1007
 cpx #$0b	 ; check if bottom (greater than last spot on second to bottom row)
 ;bpl downBot
 beq updateNewLoc	 ; at end of screen right
 jsr updatePrevLoc
 inc $1007 		 ; cols + 1
 jmp updateNewLoc

downBot:
 ldx $1009
 cpx #$0b
 beq updateNewLoc
 jsr updatePrevLoc
 inc $1009
 jmp updateNewLoc
 
updateNewLoc:
 jsr getRowColForm
 jsr collision	; collision detection
 rts			; return
  
gameOverBounce:	;just to fix branch out of range
 jmp gameOver
 
updatePrevLoc:
 jsr getRowColForm
 lda #32	 	;  space 
 bcs prevBot		;check if character is on bottom
 jsr drawToScreen
 clc
 bcc prevLocNext ;basically a branch always
prevBot:
 jsr drawToScreenBot
prevLocNext:
 rts
 
getRowColForm:		;get coord in row +column
 ldy #$00
 ldx $1007
 jsr addCols
 tya
 clc
 adc $1006
 tax
 rts
 
addCols:		;converts to row spacing
 cpx #$00
 beq colsnext
 tya
 clc
 adc #$16		; amount of spaces it takes to get to row below
 tay			
 dex 			; decrement number of rows left
 cpx #$00
 bne addCols
colsnext:
 rts

collision:		 ; detect collision between B and C
 ldy #$01
 sty $1002	;reg for coll animation
 ldy $1e00,x	; load current char
 cpy #35		; check if is # (wall)
 beq drawcoll
 cpy $100b		; check if character is 'C'
 bne drawCharacter	; not C
 ldy #$05			;set up all this for collision
 sty $1002	;reg for coll animation loops
 lda #$06
 sta $1003	; colour
 jsr resetcollision
 jsr loseLife
drawcoll:
 jsr collAnimationLoop
 jsr drawCharacter
collisionBottom:

 ;lda #$04 		; load 'D' into acc to indicate collision
 rts
 
loseLife:
 lda #32
 ldx $100c
 jsr drawTop
 dec $100c
 lda $100c
 cmp #$00
 bmi gameOverBounce
 rts
 ;ldy #$00
 ;lda $1007
 ;clc
 ;sbc #$0b	;num cols - 11
 ;sta $1007
 ;lda $1007
 ;sbc $1007
 ;clc
 ;tax
 ;jsr addCols
 ;sbc #$0d
 ;tya
 ;clc
 ;adc $1006
 ;clc
 ;tax
 ;lda #$02
 
drawCharacter:
 ldy #$00
 ldx $1007
 jsr addCols
 tya
 clc
 adc $1006
 tax
 lda $100a		; 'B'
 bcs drawBottom
 bcc drawTop
 ;jsr drawToScreen
 lda #$4f		; arbitrary number for timer
 jsr timerLoop	; jump to timer
 rts
 
drawBottom:
 ;ldy #$01
 ;sty $100a			;set bottom bit

 ldy #$00
 ldx $1007
 jsr addCols
 tya 
 clc 
 adc $1006
 ;sbc #$0d		;subtract 13
 tax
 lda $100a
 jsr drawToScreenBot
 lda #$4f		; arbitrary number for timer
 jsr timerLoop	; jump to timer
 rts
 
drawTop:
 jsr drawToScreen
 lda #$4f		; arbitrary number for timer
 jsr timerLoop	; jump to timer
 rts
resetcollision:	; reset D back to C
 ldy $1e00,x	; load current char
 cpy #$04		; check if char is 'D'
 bne resetcollbot
 lda $100b 		; ;load 'C' into reg if D is char'
 jsr drawToScreen
resetcollbot: 
 rts
 
drawToScreen:
 sta $1e00,x	; store space
 lda $1005		; colour to black
 sta $9600,x	; store colour in new location too 
 rts
 
drawToScreenBot:
 sta $1f00,x	; store space
 lda $1005		; colour to black
 sta $9700,x	; store colour in new location too 
 rts
 
collAnimationLoop:
 jsr collMovementCheck
 jsr collisionAnimation 
 lda #32
 jsr drawToScreen
 dec $1003
 ldx $1002
 dex
 stx $1002
 cpx #$00
 bne collAnimationLoop
doneCollAnimLoop:
 rts
 
collisionAnimation:
 ldy #$00
 ldx $1007
 jsr addCols
 tya
 clc
 adc $1006
 tax 
 lda $100a
 sta $1e00,x	; store in new index
 lda $1003		    ; colour
 sta $9600,x	; store colour
 lda #$40		; arbitrary number for timer
 jsr timerLoop	; jump to timer
 rts

collMovementCheck:
 lda $1004		 ; current key held down -> page 179 of vic20 manual
 cmp #17		 ;a pressed
 beq collLeft	 ; move left	

 cmp #18		 ;d pressed
 ;beq playright	 ; move right
 beq collRight
 cmp #9	 ;w pressed
 beq collUp
 ;beq playup		
 cmp #41		 ;s pressed
 beq collDown
 bne collRight ;default
 

collLeft:
 ;ldx $1006
 ldy #$00
 ldx $1007
 jsr addCols
 tya 
 clc 
 adc $1006
 
 ;sbc #$0d		;subtract 13
 tax
 inx
 lda $1e00,x
 cmp #35
 beq collRet
 ldx $1006
 inx
 stx $1006
 rts
collRight:
 ldy #$00
 ldx $1007
 jsr addCols
 tya 
 clc 
 adc $1006
 
 ;sbc #$0d		;subtract 13
 tax
 dex
 lda $1e00,x
 cmp #35
 beq collRet
 ldx $1006
 dex
 stx $1006
 rts
 
collUp:
 ldy #$00
 ldx $1007
 inx
 jsr addCols
 tya 
 clc 
 adc $1006
 ;sbc #$0d		;subtract 13
 tax
 lda $1e00,x
 cmp #35
 beq collRet
 ldx $1007
 inx
 stx $1007
 rts
collDown:
 ldy #$00
 ldx $1007
 dex
 jsr addCols
 tya 
 clc 
 adc $1006
 
 ;sbc #$0d		;subtract 13
 tax
 lda $1e00,x
 cmp #35
 beq collRet
 ldx $1007
 dex
 stx $1007
 rts
collRet:
 rts
 
timerLoop:		 ; super simple loop to slow down movement of 'B' (not have it fly across screen)
 ldy #$ff		 ; 255 (basically the biggest number possible)
 jsr timer		 ; jump to timer loop
 sbc #$01		 ; acc - 1 
 bpl timerLoop   ; branch if positive (N not set)
 rts			 ; N set, return
 
timer:
 dey			 ; y-1
 cpy #$00		 ; check if y=0
 bne timer		 ; if not, loop
 rts			 ; return
 



 ;text
 ;44 = purple, 55 = green; ff = blurry and black

 ;border/background -> 0f = green border, black background

level1:
  dc.b $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  dc.b $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  dc.b $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  dc.b $20,$20,$20,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23,$23
  dc.b $20,$20,$20,$23,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  dc.b $20,$20,$20,$23,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  dc.b $20,$20,$20,$23,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  dc.b $20,$20,$20,$23,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  dc.b $20,$20,$20,$23,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  dc.b $23,$23,$23,$23,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  dc.b $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
level1end