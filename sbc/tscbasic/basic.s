* MICRO BASIC PLUS SOURCE LISTING
*
* MICRO BASIC PLUS
* COPYRIGHT (C) 1976 BY
*
* TECHNICAL SYSTEMS CONSULTANTS
* BOX 2574
* W. LAFAYETTE INDIANA 47906
*
* Ported to 6809 Single Board computer by
* Jeff Tranter <tranter@pobox.com>
*
* TODO: Fix random crashes?

	opt	l
	opt	s19

* EQUATES
STACK	EQU	$7FFF
EXTERN	EQU	$1F00   ; TODO: Put this outside of memory used by BASIC
MONITR	EQU	$F837   ; Go to ASSIST09
STKBOT	EQU	$1E00

; ASSIST09 SWI call numbers

A_INCHNP EQU	0	; INPUT CHAR IN A REG - NO PARITY
A_OUTCH  EQU	1	; OUTPUT CHAR FROM A REG
A_VCTRSW EQU	9	; Vector swap
.ECHO	EQU	50	; Secondary command list

* TEMPORARY STORAGE

RNDM	RMB	4
BUFPNT	RMB	2
FORSTK	RMB	2
DIMPNT	RMB	2
XTEMP3	RMB	2
DATAST	RMB	2
DATAPT	RMB	2
TRYVAL	RMB	2
CRFLAG	RMB	1
QMFLAG	RMB	1
ROWVAR	RMB	1
ROWCON	RMB	1
COLCON	RMB	1
TABFLG	RMB	1
DIMFLG	RMB	1
RUNFLG	RMB	1
DATAFL	RMB	1
SUBCNT	RMB	1
LETFLG	RMB	1
FLDCNT	RMB	1
NXPNTR	RMB	2
XTEMP	RMB	2
XSAVE	RMB	2
XSAVE2	RMB	2
NUMCNT	RMB	1
NEGFLG	RMB	1
NOEXFL	RMB	1
EXTRA	RMB	2
COUNT	RMB	1
STKCNT	RMB	1
AUXCNT	RMB	1
SIGN	RMB	1
AXSIGN	RMB	1
OVFLBF	RMB	1
XTEMP2	RMB	2
XTEMP4	RMB	2
XTEMP5	RMB	2
CPX1	RMB	2
CPX2	RMB	2
STKEND	RMB	3
CHRCNT	RMB	1
OPSTAK	RMB	32
AC	RMB	3
NUMBER	RMB	3
AX	RMB	3
BUFFER	RMB	72

* LABEL TABLE

LBLTBL	RMB	78
STKTOP	RMB	2

* CONSTANTS

BACKSP	EQU	$8
DELCOD	EQU	$18
PRMPTC	EQU	$21	; '!'

	ORG	$0100

* MAIN PROGRAM

START	JMP	MICBAS	; JMP TO BEGIN
RESTRT	JMP	FILBUF

* EXTERNAL I-O ROUTINES

; OUTEEE is a jump to the output routine in MIKBUG (character in
; accumulator A, other registers undisturbed), and is at location 0106.
; If MIKBUG is not used, this should be patched to vector to your
; routine.

OUTEEE	SWI		; Call ASSIST09 monitor function
	FCB	A_OUTCH	; Service code byte
	RTS

; Get character from the console
; A contains character read. Blocks until key pressed. Character may
; be echoed depending on echo flag. Ignores NULL ($00) and RUBOUT
; ($7F). CR ($OD) is converted to LF ($0A).
; Registers changed: none (flags may change). Returns char in A.
INCH	SWI		; Call ASSIST09 monitor function
	FCB	A_INCHNP ; Service code byte
	RTS

BREAK	JMP	INTBRK
MEMEND	FDB	$6EFF

* KEYWORD AND JUMP TABLE

KEYTBL	FCC	;PRI;
	FDB	PRINT

	FCC	;INP;
	FDB	INPUT

	FCC	;IF ;
	FDB	IF

	FCC	;LET;
LETADR	FDB	LET

	FCC	;FOR;
	FDB	FOR

	FCC	;NEX;
	FDB	NEXT

	FCC	;GOT;
	FDB	GOTO

	FCC	;GOS;
	FDB	GOSUB

	FCC	;ON ;
	FDB	ONGOTO

	FCC	;RET;
	FDB	RETURN

	FCC	;REA;
	FDB	READ

	FCC	;DAT;
	FDB	DATA

	FCC	;RES;
	FDB	RESTOR

	FCC	;DIM;
	FDB	DIM

	FCC	;EXT;
	FDB	EXTRNL

	FCC	;MON;
	FDB	MONITR

	FCC	;END;
	FDB	FILBUF

	FCC	;REM;
	FDB	RUNEXC

	FCC	;RUN;
	FDB	RUN

	FCC	;LIS;
	FDB	LIST

	FCC	;SCR;
	FDB	MICBAS
	FCB	0

FCTTBL	FCC	;RND;
	FDB	EVAL88

	FCC	;ABS;
	FDB	EVAL85

	FCC	;SGN;
	FDB	EVAL86
	FCB	0

* INITIALIZATION

ECHOOFF	PSHS	A,X	; Save registers
	LDX	#$FFFF	; New echo value (off)
	LDA	#.ECHO	; Load subcode for vector swap
	SWI		; Request service
	FCB	A_VCTRSW ; Service code byte
	PULS	A,X	; Save registers
	RTS		; Return to monitor

CLRBEG	JSR	ECHOOFF	; Turn off echo
	LDX	#START
	STX	XTEMP3	; SAVE X
CLRBG2	LDX	#DATAST	; SET START
	BRA	CLEAR	; GO CLEAR

CLREND	LDX	MEMEND	; SET END
	STX	XTEMP3	; SAVE
	LDX	ENDSTR
CLEAR	clra		; CLEAR ACC.
CLEAR2	sta	0,X	; CLEAR BYTE
	leax	1,x	; BUMP THE POINTER
	CPX	XTEMP3	; DONE?
	BNE	CLEAR2
	RTS		; RETURN

MICBAS	BSR	CLRBEG	; GO CLEAR
	LDX	#STORSP
	STX	ENDSTR	; SET END STORAGE:
	BSR	CLREND	; GO CLEAR

* GET LINE INTO INPUT BUFFER

FILBUF	;LDX	#RESTRT
	;STX	MONPC	; SET UP RETURN POINTER
	LDS	#STACK
	LDX	#BUFFER
	STX	XTEMP3	; SAVE BOUND
	BSR	CLRBG2
	LDX	#ENDSTR	; SET PUNCH LIMITS
	LDX	0,X	; SET END
	STX	DIMPNT
	LDX	#BUFFER	; POINT TO BUFFER
	JSR	PCRLF	; OUT A CR & LF
	lda	#PRMPTC
	JSR	OUTCH	; OUTPUT PROMPT
FILBU2	JSR	INCHAR	; GET A CHARACTER
	BEQ	FILBUF
	sta	0,X	; SAVE CHAR.
	cmpa	#$0D	; IS IT A C.R.?
	BEQ	FILBU6
	leax	1,x	; BUMP THE POINTER
	CPX	#BUFFER+72
	BNE	FILBU2	; END OF BUFFER?
	BRA	FILBUF
FILBU6	LDX	#BUFFER	; RESET POINTER
	JSR	BCDCO1	; LINE NO. CONV.
	STX	XTEMP2	; SAVE POINTER
	JSR	FNDKEY	; CHECK KEY WORD
	tsta
	BNE	FILBU8	; IF NONZERO THEN OK
	LDX	BUFPNT	; POINT TO BUFFER
	lda	0,X	; GET CHARACTER
	cmpa	#$D	; IS IT A C.R.?
	BNE	FILBU7
	ldb	NOEXFL	; DIR. EXECUTION?
	BEQ	FILBUF
	sta	CRFLAG	; SET FLAG
	BRA	FILBU8	; IT IS OK
FILBU7	JSR	TSTLET	; LET?
	BEQ	FILBU8
FILB75	lda	#$10
	JMP	MISTAK	; REPORT ERROR #0
FILBU8	lda	CHRCNT	; GET CHAR. COUNT
	suba	NUMCNT	; SUB LINE # DIGITS
	sta	CHRCNT	; SAVE
	ldb	NOEXFL	; DIRECT EXECUTE?
	BNE	STUFLN	; IF NOT GO PUT LINE
	JSR	PCRLF	; OUTPUT C.R. L.F.
	JMP	RUNEX4	; GO TO ROUTINE

* PUT LINE IN PROGRAM STORAGE

STUFLN	LDX	MEMEND
	STX	CPX1
	LDX	XTEMP2	; SET POINTER
	STX	BUFPNT	; SAVE POINTER
	JSR	FNDLIN	; GO FIND LINE IN STORE
	STX	XSAVE	; SAVE POINTER
	tstb		; DID WE FIND IT?
	BNE	INSERT	; IF NOT GO INSERT


* REPLACE EXISTING LINE WITH NEW ONE

REPLAC	incb		; INC THE COUNTER
	lda	0,X	; GET A CHARACTER
	leax	1,x	; BUMP THE POINTER
	cmpa	#$D	; IS IT A C.R,?
	BNE	REPLAC
REPLA4	stb	OFSET2+1	; SETUP OFFSET
	lda	#$FF	; GET COUNT
	negb		; 2'S COMP. IT
	BSR	ADJEND	; GO FIX END PNTR
	LDX	XSAVE	; RESTORE THE POINTER
REPLA5	CPX	ENDSTR	; END OF STORAGE?
	BEQ	REPLA6
OFSET2	lda	0,X
	sta	0,X	; MOVE A CHARACTER
	leax	1,x	; BUMP THE POINTER
	BRA	REPLA5	; REPEAT
REPLA6	LDX	XSAVE	; RESTORE THE POINTER

* INSERT A LINE INTO PROGRAM STORAGE

INSERT	lda	CRFLAG	; LONE C.R.?
	BNE	INSER6
	LDX	ENDSTR
	ldb	CHRCNT	; GET CHAR. COUNT
	addb	#2	; BIAS FOR LINE NUM.
	stb	OFFSET+1	; SETUP OFFSET
	BSR	ADJEND	; FIX END PNTR
INSER2	CPX	XSAVE	; DONE?
	BEQ	INSER3
	leax	-1,x	; DEC THE POINTER
	lda	0,X	; GET A CHAR,
OFFSET	sta	0,X
	BRA	INSER2	; MOVE IT
INSER3	leax	-1,x
	JSR	PUTLB2	; PUT LAB
	leax	1,x	; BUMP THE POINTER
	leax	1,x
INSER4	STX	XSAVE	; SAVE POINTER
	LDX	BUFPNT
	lda	0,X	; GET CHAR*
	leax	1,x	; BUMP THE POINTER
	STX	BUFPNT	; SAVE
	LDX	XSAVE	; RESTOR PNTR
	leax	1,x
	sta	0,X	; SAVE IT
	cmpa	#$D	; IS IT A C.R.?
	BNE	INSER4
INSER6	JMP	FILBUF	; 60 TO MAIN LOOP

* ADJUST THE END OF PROGRAM POINTER

ADJEND	addb	ENDSTR+1
	adca	ENDSTR	; ADD IN VALUE
	stb	CPX2+1
	sta	CPX2	; SET END POINTER
	JSR	CMPX1
	BCC	ADJEN2
	stb	ENDSTR+1
	sta	ENDSTR	; SAVE NEW POINTER
	RTS		; RETURN
ADJEN2	lda	#$90	; SET ERROR
	JMP	MISTAK

* TRY TO FIND LINE

FNDLIN	lda	NUMBER+2
	ldb	NUMBER+1
FINDLN	LDX	#STORSP	; SETUP POINTER
FINDL1	CPX	ENDSTR	; END OF STORAGE?
	BNE	FINDL4
FINDL2	incb
	RTS		; RETURN
FINDL4	cmpb	0,X	; CHECK M.S. DIGITS
	BHI	FINDL6
	BNE	FINDL2
	cmpa	1,X	; CHECK L.S, DIGITS
	BHI	FINDL6
	BNE	FINDL2
	clrb		; CEAR FLAG
	RTS		; RETURN
FINDL6	BSR	FNDCRT	; GO FIND C.R,
	leax	1,x	; BUMP THE POINTER
	BRA	FINDL1	; REPEAT

* FIND A C,R, IN STORAGE

FNDCRT	pshs	A	; SAVE A
	lda	#$D
FNDVAL	leax	1,x	; BUMP THE POINTER
	cmpa	0,X	; TEST FOR C.R.
	BNE	FNDVAL
	puls	A	; RESTORE A
	RTS		; RETURN

* INPUT

INCHAR	JSR	INCH	; GET THE CHAR.
	cmpa	#BACKSP	; IS IT A BACKSPACE?
	BNE	INCHR2
	CPX	#BUFFER	; BEGINNING OF BUF?
	BEQ	INCHR4
	leax	-1,x	; BACKUP ONE POS.
	lda	#$8
	jsr	OUTEEE
	lda	#$20
	jsr	OUTEEE
	lda	#$8
	jsr	OUTEEE
	DEC	CHRCNT	; DEC CHAR. COUNT
	BRA	INCHAR
INCHR2	cmpa	#DELCOD	; DELETE LINE?
	BEQ	INCHR4
	jsr	OUTEEE
	INC	CHRCNT
INCHR4	RTS		; RETURN

* PRINT CARRIAGE RETURN & LINEFEED

PCRLF	STX	XSAVE	; SAVE X REG
	LDX	#CRLFST	; POINT TO STRING
PDATA1	lda	0,X	; GET CHAR
	cmpa	#4	; IS IT 4?
	BEQ	PCRLF2
	JSR	OUTCH	; OUTPUT CHAR
	leax	1,x	; BUMP THE POINTER
	BRA	PDATA1	; REPEAT
PCRLF2	LDX	XSAVE	; RESTORE X REG
	CLR	FLDCNT	; ZERO FIELD COUNT
	RTS		; RETURN

CRLFST	FCB	$D,$A,0,0,0,0,4

* TEST FOR STATEMENT TERMINATOR

TSTTRM	cmpa	#$D	; C,R,?
	BEQ	TSTTR2
	cmpa	#':	; COLON?
TSTTR2	RTS		; RETURN

* CLEAR NUMBER THROUGH NUMBER+2

UPSCLR	JSR	STAKUP
CLRNUM	clra
	sta	NUMBER
	sta	NUMBER+1
	sta	NUMBER+2
	RTS

* CONVERT NUMBER TO PACKED BCD

BCDCON	BSR	CLRNUM	; CLEAR NUMBER
	sta	NOEXFL
	sta	NEGFLG
	sta	NUMCNT
	JSR	SKIPSP	; SKIP SPACES
	cmpa	#'+	; IS IT A +?
	BEQ	BCDC01
	cmpa	#'-	; IS IT A -?
	BNE	BCDCO1
	COM	NEGFLG	; SET FLAG
BCDC01	leax	1,x
BCDCO1	JSR	CLASS	; GET A DIGIT
	cmpb	#3	; IS IT A NUMBER?
	BEQ	BCDCO2
	lda	NEGFLG
	JMP	FIXSIN	; GO FIX UP THE SIGN
BCDCO2	leax	1,x	; BUMP THE POINTER
	sta	NOEXFL	; SET NO EXEC FLU
	anda	#$0F	; MASK OFF ASCII
	ldb	#4	; SET COUNTER
BCDCO4	ASL	NUMBER+2
	ROL	NUMBER+1
	ROL	NUMBER	; SHIFT PREV. OVER
	decb		; DEC THE COUNTER
	BNE	BCDCO4
	adda	NUMBER+2
	sta	NUMBER+2  ; SAVE NEW VALUE
	INC	NUMCNT	; INC NUMBER CNTR
	BRA	BCDCO1

* FIND NEXT BLOCK

NXTBLK	LDX	BUFPNT	; RESTORE POINTER
NXTBL4	lda	0,X	; GET A CHAR.
	cmpa	#' 	; IS IT A SPACE?
	BEQ	SKIPSP
	leax	1,x	; BUMP THE POINTER
	BRA	NXTBL4	; REPEAT

* CONVERT AND SKIP

CONSKP	BSR	BCDCON
	leax	-1,x

* SKIP ALL SPACES

SKPSP0	leax	1,x
SKIPSP	lda	0,X	; GET CHR FROM BUF
	cmpa	#$20	; IS IT A SPACE?
	BEQ	SKPSP0
SKIPS4	RTS		; RETURN

* FIND NEXT BLOCK NOT EXPECTING A SPACE

NXTSPC	LDX	BUFPNT	; SET POINTER
NXTSP4	JSR	CLASS	; GO CLASSIFY
	cmpb	#2	; IS IT A LETTER?
	BNE	SKIPSP
	leax	1,x	; BUMP THE POINTER
	BRA	NXTSP4

* FIND KEY WORD IF POSSIBLE

FNDKEY	JSR	SKIPSP	; SKIP SPACES
	STX	BUFPNT	; SAVE THE POINTER
	STX	XSAVE
	LDX	#KEYTBL	; POINT TO KEY WORDS
FNDKE2	ldb	#5
FNDKE4	;anda	#$20
	cmpa	0,X	; TEST THE CHARACTER
	BNE	FNDKE6
	STX	XTEMP3	; SAVE POINTER
	LDX	XSAVE
	leax	1,x	; BUMP POINTER
	lda	0,X	; GET CHAR.
	STX	XSAVE
	LDX	XTEMP3	; REST. PNTR.
	leax	1,x
	decb
	cmpb	#2
	BNE	FNDKE4	; IF NOT DONE REPEAT
FNDKE5	RTS		; RETURN
FNDKE6	leax	1,x	; BUMP THE COUNTER
	decb
	BNE	FNDKE6
	lda	0,X	; GET CHARACTER
	BEQ	FNDKE5	; IF ZERO, END OF LIST
	STX	XTEMP3	; SAVE POINTER
	LDX	BUFPNT
	STX	XSAVE
	lda	0,X	; GET NEW CHAR.
	LDX	XTEMP3	; RESTORE POINTER
	BRA	FNDKE2	; REPEAT


* OUTPUT A NUMBER FROM PACKED BCD BYTES

OUTBCD	LDX	#NUMBER	; SET POINTER
OUTBCI	ldb	#2	; SET COUNTER
	andcc	#$fe
	lda	0,X	; GET A WORD
	BPL	OUTBC4	; IF NOT NEG JMP AHEAD
	lda	#'-
	JSR	OUTCH	; OUTPUT A
	INC	FLDCNT
	BRA	OUTBC4
OUTBC2	lda	0,X	; GET DIGITS
	bita	#$F0	; MASK
	BCS	OUTBC3
	BEQ	OUTBC4	; JMP IF ZEROES
OUTBC3	JSR	OUTHL	; OUTPUT A DIGIT
	INC	FLDCNT
	orcc	#$1
OUTBC4	lda	0,X	; GET A DIGIT
	bitb	#$FF	; LAST DIGIT?
	BEQ	OUTBC6
	bita	#$0F	; MASK
	BCS	OUTBC6
	BEQ	OUTBC8	; JMP IF ZEROES
OUTBC6	JSR	OUTHR	; OUTPUT A DIGIT
	INC	FLDCNT
	orcc	#$1
OUTBC8	leax	1,x	; BUMP THE POINTER
	decb		; DEC THE COUNTER
	BPL	OUTBC2	; REPEAT IF NOT DONE
	RTS		; RETURN

* LIST USERS PROGRAM

LIST	JSR	NXTSPC	; FIND NEXT
	cmpa	#$D
	BEQ	LIST3
	JSR	BCDCON	; GET LINE NUM
	STX	BUFPNT	; SAVE POINTER
	JSR	FNDLIN	; FIND LINE
	STX	XSAVE	; SAVE IT
	JSR	NXTSPC
	cmpa	#$D	; C.R.?
	BNE	LIST1
	INC	SUBCNT	; SET TO 1
	BRA	LIST2
LIST1	leax	1,x	; BUMP THE POINTER
	JSR	SKIPSP
	JSR	BCDCON	; GET COUNT
	lda	NUMBER+2
	sta	SUBCNT	; SAVE IT
LIST2	LDX	XSAVE	; POINT TO LINE
	BRA	LIST4
LIST3	LDX	#STORSP	; SET POINTER
LIST4	CPX	ENDSTR	; END OF STORAGE?
	BEQ	LIST8
	JSR	PCRLF	; OUTPUT A
	ldb	#1	; SETUP COUNTER
	andcc	#$fe
	BSR	OUTBC2	; OUT LINE NUMBER
LIST5	lda	0,X	; GET A CHARACTER
	cmpa	#$D	; IS IT A C.R.?
	BEQ	LIST6
	BSR	OUTCH	; OUTPUT CHARACTER
	leax	1,x	; BUMP THE POINTER
	BRA	LIST5	; REPEAT
LIST6	leax	1,x	; BUMP THE POINTER
	lda	SUBCNT	; GET COUNT
	BEQ	LIST4
	adda	#$99	; DEC THE COUNT
	DAA
	BEQ	LIST8
	sta	SUBCNT	; SAVE
	BRA	LIST4
LIST8	JMP	FILBUF

OUTHL	lsra
	lsra
	lsra
	lsra		; MOVE TO BOTTOM
OUTHR	anda	#$0F	; MASK
	adda	#$30	; BIAS
OUTCH	JSR	BREAK	; CHECK FOR BREAK
	JMP	OUTEEE	; GO PRINT

* INTERNAL BREAK ROUTINE

; This routine monitors the ACIA for activity such that hitting the
; Control-C key during program execution or listing will immediately
; return to the main BASIC loop and respond with an error 99 ("BREAK
; DETECTED") and then the prompt.

UART	EQU	$A000	; 6820 ACIA registers
RECEV	EQU	UART+1
USTAT	EQU	UART

INTBRK	PSHS	A	; Save current A
	LDA	USTAT	; Read ACIA status register
	BITA	#1	; Check RDR bit
	BNE	BREAK2	; Branch if key pressed
RETN	PULS	A	; Restore A
	RTS		; Return
BREAK2	LDA	RECEV	; Get character
	ANDA	#$7F	; Convert to 7 bit ASCII
	CMPA	#$03	; Control-C?
	BNE	RETN	; If not, return
	LDA	#$99	; SET ERROR CODE

* OUTPUT ERROR MESSAGE

MISTAK	pshs	A	; SAVE A
	JSR	PCRLF	; OUTPUT A CR & LF
MISTA1	LDX	#ERRSTR	; POINT TO ERROR STRING
	JSR	PDATA1	; OUTPUT IT
	puls	A	; RESTORE A
	pshs	A	; SAVE A
	JSR	OUTHL	; OUTPUT DIGIT
MISTA2	puls	A	; RESTORE A
	JSR	OUTHR	; OUT 1'S DIGIT
	ldb	RUNFLG	; RUNNING?
	BNE	RUNER1
MISTA4	JMP	FILBUF
RUNER1	LDX	#ERSTR2	; POINT TO STRING
	JSR	PDATA1	; OUTPUT IT
	LDX	BUFPNT	; SET POINTER
RUNER2	leax	-1,x	; DEC THE POINTER
	CPX	#STORSP	; BEGINNING?
	BEQ	RUNER4
	lda	0,X	; GET CHAR
	cmpa	#$D	; C.R.?
	BNE	RUNER2
	leax	1,x	; BUMP THE POINTER
RUNER4	ldb	#1
	andcc	#$fe
	JSR	OUTBC2	; OUT LINE NUM.
	BRA	MISTA4
ERRSTR	FCB	7
	FCC	;ERROR #;
	FCB	4

ERSTR2	FCC	; AT ;
	FCB	4

* PRINT ROUTINE

PRINT	JSR	NXTSPC	; FIND NEXT BLOCK
PRINT0	JSR	TSTTRM
	BNE	FIELD1
	JMP	PRINT8
FIELD1	CLR	CRFLAG
	cmpa	#',	; IS IT A ","
	BNE	PRINT2
	ldb	FLDCNT	; GET COUNT
FIELD2	lda	#' 	; SPACE
	JSR	OUTCH	; OUTPUT A SPACE
	incb
	bitb	#7	; END OF FIELD?
	BNE	FIELD2
	cmpb	#$47	; END OF LINE?
	BHI	FIELD3
	stb	FLDCNT	; SAVE FIELD INFO
	BRA	PRINT1
FIELD3	JSR	PCRLF	; OUT A C.R. & L.F.
PRINT1	INC	CRFLAG	; SET FLAG
	leax	1,x	; BUMP THE POINTER
	JSR	SKIPSP
	BRA	PRINT0
PRINT2	cmpa	#';	; IS IT A ";"
	BEQ	PRINT1
	cmpa	#'"	; IS IT A QUOTE?
	BNE	PRINT4
	leax	1,x	; BUMP THE POINTER
	BSR	PSTRNG	; OUTPUT STRING
	BRA	PRINT6
PRINT4	CLR	TABFLG	; CLEAR FLAG
	cmpa	#'T	; IS IT A T?
	BNE	PRIN45
	sta	TABFLG	; SET FLAG
	lda	#'A
	BRA	PRIN47
PRIN45	cmpa	#'S	; IS IT A S?
	BNE	PRIN55
	lda	#'P
PRIN47	cmpa	1,X
	BNE	PRIN55
	JSR	NXTSP4	; FIND NEXT
	JSR	EXPR	; EVALUATE
	JSR	BINCON	; CONVERT
	ldb	NUMBER+2
	BEQ	PRINT6
	lda	TABFLG	; CHECK FLAG
	BEQ	PRINT5
	decb
	cmpb	FLDCNT	; CHECK COUNT
	BLS	PRINT6
	BRA	PRIN51
PRINT5	addb	FLDCNT
PRIN51	lda	#' 	; SPACE
	JSR	OUTCH	; OUTPUT SPACE
	INC	FLDCNT	; BUMP COUNTER
	cmpb	FLDCNT
	BNE	PRIN51	; REPEAT
PRIN52	BRA	PRINT6
PRIN55	JSR	EXPR	; EVAL EXPRESSION
	STX	XSAVE	; SAVE POINTER
	JSR	OUTBCD	; OUTPUT VALUE
	LDX	XSAVE	; RESTORE
PRINT6	JSR	SKYCLS
	decb
	BNE	PRINT7	; CHECK FOR ERROR
	JMP	PRINT0
PRINT7	lda	#$31
	JMP	MISTAK
PRINT8	TST	CRFLAG	; C.R.?
	BNE	PRINT9
	JSR	PCRLF	; OUTPUT C.R. L.F
PRINT9	JMP	RUNEXC

* PRINT STRING ROUTINE

PSTRNG	lda	0,X	; GET A CHAR.
	cmpa	#'"	; IS IT A QUOTE?
	BEQ	PSTRN4
	JSR	TSTTRM	; IS IT A C.R.?
	BEQ	PSTRN8
	JSR	OUTCH	; OUTPUT CHARACTER
	INC	FLDCNT	; BUMP FIELD CNT
	leax	1,x	; BUMP THE POINTER
	BRA	PSTRNG	; REPEAT
PSTRN4	leax	1,x
	JMP	SKIPSP
PSTRN8	lda	#$32
	JMP	MISTAK	; REPORT ERROR

* FIND LABEL ROUTINE

FNDVAR	STX	BUFPNT	; SAVE POINTER
	JSR	CLASS1	; GO CLASSIFY CHAR.
	cmpb	#2	; CHECK FOR LETTER
	BNE	FNDL25	; ERROR
	CLR	XTEMP
;	tfr	a,b	; SAVE LABEL
;	ASL	A	; MULT IT BY 2
;	ABA	ADD IT
	sta	,-s
	asla
	adda	,s+
	suba	#$13
	sta	XTEMP+1
	LDX	XTEMP	; POINT TO IT
	RTS		; RETURN

* FIND DIMENSIONED VARIABLE

FNDLB0	lda	0,X
FNDLBL	leax	1,x	; ADVANCE POINTER
	CLR	DIMFLG
	BSR	FNDVAR	; GO FIND VAR.
	clrb
	lda	0,X	; GET CHAR.
	cmpa	#$0A	; CHECK FOR 1 DIM
	BEQ	FNDLB2
	cmpa	#$0B	; CHECK IF 2 DIM
	BEQ	FNDLB1
	RTS
FNDLB1	incb		; SET FLAG-2 DIM
FNDLB2	lda	1,X	; SET POINTER
	pshs	A	;
	lda	2,X
	pshs	A	;
	pshs	B	; SAVE B
	JSR	NXTSPC	; FIND NEXT
	puls	B	;
	cmpa	#'(	; IS IT A PAREN?
FNDL25	BNE	FNDLB9
	tstb
	BEQ	FNDLB3
	leax	1,x
	JSR	EXPRO	; GO EVALUATE
	lda	NUMBER+2	; GET RESULT
	pshs	A	; SAVE IT
	JSR	STAKDN	; RESTORE
	JSR	NXTSPC	; FIND NEXT
	cmpa	#',	; IS IT A COMMA?
	BNE	FNDLB9
	BRA	FNDLB4
FNDLB3	clra
	pshs	A	; SET ROWV
FNDLB4	inca
	sta	DIMFLG	; SET FLAG
	leax	1,x
	JSR	EXPRO
	leax	1,x
	STX	BUFPNT	; SAVE POINTER
	puls	A	;
	sta	ROWVAR	; SAVE
	puls	A	;
	sta	XTEMP+1	; SAVE
	puls	A	;
	sta	XTEMP	; SAVE
	LDX	XTEMP	; SET POINTER
	lda	0,X	; GET CHAR
	sta	COLCON	; SAVE IT
	leax	1,x	; BUMP THE POINTER
	leax	1,x
	STX	XTEMP
	JSR	UPSCLR
	lda	ROWVAR	; GET VAR.
	LDX	XTEMP
	leax	-1,x	; DEC POINTER
	cmpa	0,X	; CHECK
	BHI	FNDLB9
	sta	NUMBER+2
	JSR	UPSCLR	; PUSH STACK
	lda	COLCON	; GET CONST,
	cmpa	AC-1	; CHECK
	BEQ	FNDL45
	BLS	FNDLB9	; ERROR!
FNDL45	adda	#1
	DAA		; BIAS IT
	sta	NUMBER+2
	JSR	MULT	; GO MULTIPLY
	JSR	ADD	; GO ADD
FNDLB5	JSR	TIMTHR

* ROUTINE TO ADD VALUE TO X-REG.

ADDX	lda	XTEMP	; GET M.S.BYTE
	ldb	XTEMP+1
	addb	NUMBER+2
	adca	NUMBER+1
	sta	XTEMP	; SAVE SUM
	stb	XTEMP+1
	JSR	STAKDN
	LDX	XTEMP	; SET POINTER
	CLR	DIMFLG	; RESTORE FLAG
	RTS		; RETURN

FNDLB9	lda	#$14	; SET ERROR
	JMP	MISTAK	; GO REPORT

* ROUTINE TO MULTIPLY BY 3

TIMTHR	JSR	UPSCLR
	lda	#$3	; SET MULTIPLIER
	sta	NUMBER+2
	JSR	MULT	; GO MULTIPLY

* BCD TO BINARY CONVERT.

BINCON	lda	NUMBER+2	; GET LS BYTE
	pshs	A	; SAVE
	lda	NUMBER+1
	pshs	A	; SAVE:
	clrb
	stb	NUMBER+1
	stb	NUMBER+2	; INITIALIZE
	lda	NUMBER
	BSR	ADSHF1	; ADD A SHIFT
	puls	A	;
	pshs	A	;
	BSR	ADSHF0	; GO ADD IN AND SHIFT
	puls	A	; GET MS BYTE AGAIN
	BSR	ADSHF1	; GO ADD IN AND SHIFT
	puls	A	; GET LS BYTE
	pshs	A	;
	BSR	ADSHF0
	puls	A	;
	BRA	ADDIN	; G0 ADD IN ONES
ADSHF0	lsra
	lsra
	lsra
	lsra		; MOVE TO LS HALF
ADSHF1	BSR	ADDIN	; GO ADD IN
	ldb	NUMBER+1
	asla
	rolb		; MULT BY 2
	pshs	B	;
	pshs	A	; SAVE
	asla
	rolb
	asla
	rolb		; MULT BY 4 =*8
	sta	NUMBER+2
	puls	A	;
	stb	NUMBER+1
	BSR	ADDIN1	; GO ADD IN
	puls	A	;
	adda	NUMBER+1
	sta	NUMBER+1	; MULTIPLY BY TEN
	RTS
ADDIN	anda	#$0F	; MASK
ADDIN1	adda	NUMBER+2
	sta	NUMBER+2
	BCC	ADDIN2	; CHECK FOR CARRY
	INC	NUMBER+1
ADDIN2	RTS

* PUT LABEL ROUTINE

PUTLBL	lda	NUMBER
	sta	0,X	; PUT M.S. BYTE
PUTLB2	lda	NUMBER+1
	sta	1,X	; PUT NEXT
	lda	NUMBER+2
	sta	2,X	; PUT L.S. BYTE
	RTS		; RETURN

* DIMENSION

DIM	LDX	FORSTK	; SET BOUNDS
	STX	CPX1
	JSR	NXTSPC
DIMN	JSR	SKIPSP	; CLASSIFY
	JSR	FNDVAR
	STX	XTEMP3	; SAVE IT
	JSR	NXTSPC	; GET TO NEXT
	cmpa	#'(	; IS IT A PAREN
	BNE	DIM9
DIM01	leax	1,x	; BUMP THE POINTER
	JSR	CONSKP	; CONVERT DIM
	cmpa	#')	; IS IT A PAREN
	BNE	DIM1
	clra
	clrb
	pshs	A	; SAVE IT
	BRA	DIM2
DIM1	cmpa	#',	; COMMA?
	BNE	DIM9	; ERROR!
	lda	NUMBER+2
	BEQ	DIM9
	pshs	A	; SAVE
	leax	1,x	; BUMP THE POINTER
	JSR	CONSKP	; CONVERT
	ldb	#1
	cmpa	#')	; PAREN?
	BEQ	DIM2
DIM9	lda	#$40	; SET ERROR
	JMP	MISTAK	; REPORT
DIM2	lda	NUMBER+2
	BEQ	DIM9
	pshs	A	; SAVE
	STX	BUFPNT	; SAVE POINTER
	LDX	XTEMP3	; SET X
	lda	#$0A
;	ABA	SET MARKER
	stb	,-s
	adda	,s+
	sta	0,X	; SAVE IT
	lda	DIMPNT	; GET POINTER
	sta	1,X	; SAVE IT
	lda	DIMPNT+1
	sta	2,X
	LDX	DIMPNT	; SET POINTER
	puls	A	;
	sta	0,X	; SAVE 1ST DIM
	leax	1,x	; BUMP THE POINTER
	puls	B	;
	stb	0,X	; SAVE 2ND DIM
	leax	1,x
	STX	XTEMP	; SAVE POINTER
	adda	#1
	DAA		; BIAS
	pshs	A	;
	tfr	b,a
	adda	#1	; BIAS
	DAA		; ADJUST
	tfr	a,b	; SAVE
	JSR	CLRNUM	; CLEAR STORAGE
	stb	NUMBER+2
	JSR	UPSCLR	; GO CLEAR
	puls	A	;
	sta	NUMBER+2
	JSR	MULT	; MULTIPLY
	JSR	FNDLB5	; GO FIX X
	JSR	CMPX	; TEST BOUNDS
	BLS	DIM5
	JMP	ADJEN2
DIM5	STX	DIMPNT	; SAVE RESULT
	LDX	BUFPNT	; RESTORE F'NTR
	leax	1,x
	JSR	SKIPSP	; SKIP SPACES
	JSR	TSTTRM
	BEQ	RUNEXC
	leax	1,x	; BUMP THE POINTER
	JMP	DIMN

* EXTERNAL ROUTINE JUMP

EXTRNL	JSR	EXTERN	; GO TO IT

* RUN EXECUTIVE

RUNEXC	clra
	sta	CRFLAG
	sta	LETFLG
	sta	DIMFLG
	sta	STKCNT
	lda	RUNFLG	; RUN MODE?
	BNE	RUNEX0
RUNEXA	JMP	FILBUF
RUNEX0	LDX	BUFPNT	; SET POINTER
RUNE05	lda	#$D
	ldb	#':	; SETUP TERMINATORS
RUNEX1	cmpa	0,X	; C.R. ?
	BEQ	RUNEX2
	cmpb	0,X	; IS IT A ':' ?
	BEQ	RUNE27
	leax	1,x	; BUMP THE POINTER
	BRA	RUNEX1	; REPEAT
RUNEX2	leax	1,x
RUNE22	CPX	ENDSTR	; END OF STORAGE?
	BEQ	RUNEXA
RUNE25	leax	1,x	; BUMP THE POINTER
RUNE27	leax	1,x
	JSR	BREAK	; GO CHECK BREAK
RUNEX3	JSR	FNDKEY	; FIND KEY WORD
	tsta
	BNE	RUNEX4
	LDX	BUFPNT	; SET POINTER
	BSR	TSTLET
	BEQ	RUNEX4
	lda	#$10
RUNE35	JMP	MISTAK
RUNEX4	LDX	0,X
	JMP	0,X	; GO TO ROUTINE

* TEST FOR IMPLIED LET

TSTLET	JSR	CLASS	; CHECK CHAR.
	cmpb	#2	; LETTER?
	BNE	TSTLE2
	leax	1,x	; BUMP THE POINTER
	JSR	SKIPSP	; SKIP SPACES
	cmpa	#'=	; EQUALS?
	BEQ	TSTLE1
	cmpa	#'(	; LEFT PARENT
	BNE	TSTLE2
TSTLE1	LDX	#LETADR	; SET POINTER
	sta	LETFLG	; SET FLAG
	clrb
TSTLE2	RTS

* RUN ROUTINE

RUN	JSR	CLRBEG
	JSR	CLREND
	LDX	MEMEND
	STX	FORSTK
	LDX	#STORSP	; SET POINTER
	INC	RUNFLG
	BRA	RUNE22

* LET ROUTINE

LET	LDX	BUFPNT
	lda	LETFLG	; TEST FLAG
	BNE	LET2
	JSR	NXTBLK	; FIND NEXT
LET2	JSR	EXPEQU
	JMP	RUNEXC

* GOTO ROUTINE

GOTO	JSR	NXTSPC	; FIND BLOCK
GOTO1	JSR	EXPR	; GO EVALUATE
GOTO2	JSR	FNDLIN	; GO FIND LINE
GOTO3	tstb		; FIND?
	BEQ	GOTO5
	lda	#$16	; SET ERROR
GOTO4	JMP	MISTAK	; REPORT
GOTO5	incb
	stb	RUNFLG	; SET RUN FLAG
	JMP	RUNE22

* INPUT ROUTINE

INPUT	JSR	NXTSPC	; FIND NEXT
INPUT0	CLR	QMFLAG	; CLEAR FLAG
INPUT1	JSR	SKIPSP	; SKIP SPACES
	cmpa	#'"	; IS IT A QUOTE?
	BNE	INPUT2
	leax	1,x	; BUMP THE POINTER
	JSR	PSTRNG	; OUTPUT STRING
	BRA	INPUT6
INPUT2	JSR	FNDLBL	; FIND LABEL
	STX	XTEMP4	; SAVE POINTER
INPUT3	LDX	#BUFFER	; SET POINTER
	lda	QMFLAG	; TEST FLAG
	BNE	INPUT4
	lda	#'?
	sta	QMFLAG	; SET FLAG
	JSR	OUTCH	; OUT A ?
INPUT4	JSR	INCH	; GET A DIGIT
	cmpa	#DELCOD	; DELETE?
	BNE	INPU45
	CLR	QMFLAG
	BRA	INPUT3
INPU45	sta	0,X	; SAVE IT
        JSR     OUTCH   ; ECHO IT
	leax	1,x
	cmpa	#',	; IS IT COMMA?
	BEQ	INPUT5
	cmpa	#$D	; IS IT A C.R.?
	BNE	INPUT4
	sta	CRFLAG	; SET FLAG
	JSR	PCRLF	; OUTPUT A CR & LF
INPUT5	LDX	#BUFFER	; SET POINTER
	JSR	BCDCON	; GO CNVRT NUM.
	LDX	XTEMP4
	BSR	LABLS2
	STX	BUFPNT	; SAVE POINTER
INPUT6	cmpa	#',	; IS IT A COMMA?
	BNE	INPUT7
	leax	1,x
	lda	CRFLAG	; TEST FLAG
	BEQ	INPUT1
	BRA	INPUT0
INPUT7	JSR	TSTTRM
	BNE	INPUT9
INPU72	lda	CRFLAG	; TEST FLAG
	BEQ	INPUT8
INPU75	JMP	RUNEXC
INPUT8	JSR	INCH	; GET CHAR.
	cmpa	#$D	; C.R.?
	BNE	INPUT8
	JSR	PCRLF
	BRA	INPU75
INPUT9	lda	#$45
	JMP	MISTAK	; REPORT ERROR


* GET AND PUT LABEL

LABELS	JSR	FNDLBL	; GO FIND IT
LABLS2	JSR	PUTLBL	; GO PUT IT
	JMP	NXTSPC	; GET TO NEXT SET


* DATA ROUTINE

DATA	lda	RUNFLG	; RUNNING?
	BEQ	READ6
	JSR	NXTSPC	; FIND NEXT
	sta	DATAFL	; SET DATA FLAG
	STX	DATAST	; SET POINTER
	STX	DATAPT
	BRA	READ6	; RETURN


* READ DATA ROUTINE

READ	lda	RUNFLG	; RUNNING?
	BEQ	READ6
	lda	DATAFL	; CHECK FLAG
	BEQ	READ8
	JSR	NXTBLK	; GET NEXT
READ2	JSR	SKIPSP	; GO CLASSIFY
	JSR	FNDLBL
	STX	XTEMP4
	LDX	BUFPNT
	STX	XTEMP5	; SAVE IT
	LDX	DATAPT	; GET DATA PNTR
	JSR	EXPR	; GET DATA
	lda	0,X	; GET CHAR.
	JSR	TSTTRM	; TEST IT
	BNE	READ25
	LDX	DATAST	; SET POINTER
	BRA	READ3
READ25	leax	1,x	; BUMP THE POINTER
READ3	STX	DATAPT
	LDX	XTEMP5
	STX	BUFPNT
	LDX	XTEMP4
	BSR	LABLS2
	cmpa	#',	; IS IT A COMMA?
	BNE	READ4
	leax	1,x
	BRA	READ2	; REPEAT
READ4	JSR	TSTTRM
	BNE	READ8	; ERROR
READ6	JMP	RUNEXC	; RETURN
READ8	lda	#$51
	JMP	MISTAK

* RESTORE DATA STRING

RESTOR	STX	XSAVE	; SAVE POINTER
	LDX	DATAST
	STX	DATAPT	; FIX DATA PNTR
	LDX	XSAVE	; RESTORE POINTER
	BRA	READ6

* ON GOTO ROUTINE
ONGOTO	JSR	NXTBLK	; FIND NEXT BLOCK
	JSR	EXPR	; EVAL. EXPR.
	lda	NUMBER+2
	anda	#$0F	; MASK L.S. DIGIT
	pshs	A	; SAVE A
	CLR	CRFLAG
	leax	1,x	; BUMP THE POINTER
	leax	1,x
	lda	0,X	; GET CHAR
	cmpa	#'T	; IS IT A "T"?
	BEQ	ONGOT0
	sta	CRFLAG	; SET FLAG
ONGOT0	JSR	NXTBL4	; GET NEXT
	STX	XSAVE	; SAVE X
	puls	A	; RESTORE A
ONGOT1	deca
	BEQ	ONGOT4
ONGOT2	ldb	0,X	; GET A CHAR,
	leax	1,x	; BUMP THE POINTER
	cmpb	#',	; IS IT A COMMA?
	BNE	ONGOT3
	STX	XSAVE	; SAVE THE POINTER
	BRA	ONGOT1	; REPEAT
ONGOT3	cmpb	#$D	; C^R^ ?
	BNE	ONGOT2
	LDX	XSAVE	; RESTORE POINTER
ONGOT4	ldb	CRFLAG	; CHECK FLAG
	BEQ	ONGOT6
	JMP	GOSUB2
ONGOT6	JMP	GOTO1

* ROUTINE

IF	JSR	NXTSPC	; FIND NEXT
	JSR	EXPR	; EVAL EXPR
	lda	0,X	; GET CHAR
	BSR	CLSREL	; REL OPERATOR?
	BNE	IF9	; ERROR!
	pshs	A	; SAVE A
	lda	1,X	; GET CHAR
	BSR	CLSREL	; REL OP?
	puls	A	; RESTORE A
	BNE	IF1
	ldb	1,X
;	ABA	FORM REL CODE
	adda	1,x
	leax	1,x	; BUMP THE POINTER
IF1	leax	1,x
	pshs	A	; SAVE A
	JSR	EXPR	; EVAL EXPR
	puls	A	;
	anda	#$0F	; MASK
	suba	#9	; BIAS IT
	BMI	IF9	; ERROR?
	asla		; TIMES FOUR
	asla
	sta	OFSET3+1
	JSR	SUB	; GO COMPARE
	JSR	ZCHK	; SET CC REG
OFSET3	BRA	*
BRATBL	BLE	IF4	; BRANCH TABLE
	BRA	IF8
	BNE	IF4
	BRA	IF8
	BGE	IF4
	BRA	IF8
	BLT	IF4
	BRA	IF8
	BEQ	IF4
	BRA	IF8
	BGT	IF4
	BRA	IF8
	BRA	IF9	; ERROR!
IF4	LDX	BUFPNT	; SET POINTER
	lda	0,X	; GET CHAR
	cmpa	#'T	; IS IT A "T"?
	BNE	IF6
	JSR	NXTSPC
	STX	BUFPNT	; SAVE POINTER
	JSR	CLASS1	; GO CLASSIFY
	cmpb	#3	; IS IT A NUMBER?
	BNE	IF6
	JMP	GOTO1	; GO TO GOTO
IF6	JMP	RUNEX3
IF8	JMP	RUNEXC	; GO PROCESS CMND
IF9	lda	#$62	; SET ERROR
	JMP	MISTAK

* CLASSIFY RELATIONAL OPERATION

CLSREL	cmpa	#$3B
	BLS	CLSRE5
	cmpa	#$3E	; CHECK CHAR
	BHI	CLSRE5
	clrb		; CLEAR FLAG
	RTS		; RETURN
CLSRE5	incb		; SET FLAG
	RTS		; RETURN

* GOSUB ROUTINE

GOSUB	ldb	RUNFLG
	BEQ	IF8
	JSR	NXTSPC	; FIND NEXT
GOSUB2	INC	SUBCNT
	JSR	EXPR	; EVALUATE EXPR
	leax	-1,x
	JSR	FNDCRT	; FIND C.R.
	leax	1,x	; BUMP THE POINTER
	lda	0,X	; GET LINE NO
	pshs	A	;
	lda	1,X
	pshs	A	; SAVE AS RET. ADD.
	STS	CPX1	; SAVE SP
	LDX	#STKBOT+35
	JSR	CMPX	; CHECK BOUNDS
	BLS	GOSUB4
	JMP	ADJEN2	; RPT OVFL
GOSUB4	JMP	GOTO2

* RETURN ROUTINE

RETURN	lda	#$73
	DEC	SUBCNT	; DEC COUNTER
	BPL	RETUR2
	JMP	MISTAK	; ERROR!
RETUR2	puls	A	; GET RET. ADD.
	puls	B
	JSR	FINDLN	; GO FIND LINE
	JMP	GOTO3

* EXPRESSION EQUATE

EXPEQU	JSR	FNDLB0	; FIND LABEL
	STX	XTEMP4	; SAVE
	JSR	NXTSPC
	leax	1,x
	JSR	EXPR	; GO EVALUATE
	LDX	XTEMP4	; GET POINTER
	JMP	PUTLBL	; INSTALL

* FOR ROUTINE

FOR	JSR	NXTBLK	; FIND NEXT
	pshs	A	;
	BSR	EXPEQU
	LDX	DIMPNT
	STX	CPX1
	LDX	FORSTK
	puls	A	;
	sta	0,X
	lda	BUFPNT+1
	leax	-1,x	; DEC THE POINTER
	sta	0,X
	lda	BUFPNT	; SET UP IN INX
	leax	-1,x
	sta	0,X
	leax	-1,x
	JSR	CMPX	; CHECK FOR OVFLW
	BHI	FOR5
	JMP	ADJEN2
FOR5	STX	FORSTK	; SAVE POINTER
	JMP	RUNEXC

* NEXT ROUTINE

NEXT	JSR	NXTBLK	; FIND NEXT
	STX	NXPNTR
	LDX	FORSTK	; SET POINTER
NEXT1	CPX	MEMEND	; OVFLW?
	BNE	NEXT2
	LDX	BUFPNT	; RESTORE PNTR
	lbra	NEXT9	; ERROR!
NEXT2	leax	1,x	; FIXUP POINTER
	leax	1,x
	leax	1,x
	cmpa	0,X	; CHECK
	BNE	NEXT1
	leax	-1,x	; FIX POINTER
	leax	-1,x
	leax	-1,x
	STX	FORSTK
	leax	1,x
	LDX	0,X
	STX	BUFPNT	; SAVE IT
	JSR	FNDLBL	; FIND LABEL
	STX	XTEMP4	; SAVE IT
	JSR	NXTSPC	; FIND NEXT
	JSR	EXPR	; EVALUATE
	JSR	STAKUP
	LDX	XTEMP4	; RESTORE PNTR
	JSR	GETVAL	; GET LABEL VALUE
	LDX	BUFPNT
	lda	0,X	; GET CHAR
	cmpa	#'S	; IS IT STEP?
	BEQ	NEXT4
	JSR	UPSCLR
	inca
	sta	NUMBER+2
	BRA	NEXT5
NEXT4	JSR	NXTSP4
	JSR	EXPR
	lda	NUMBER
	sta	LETFLG	; SHOW NEG.
NEXT5	JSR	ADD	; GO ADD IN STEP
	LDX	#TRYVAL	; SET POINTER
	JSR	PUTLBL	; SAVE LABEL
	JSR	SUB	; COMPARE
	JSR	ZCHK	; SET CC REG
	ldb	LETFLG	; CHK FLAG
	BMI	NEXT6
	tfr	a,cc	; SET CC
	BGE	NEXT8
	BRA	NEXT7
NEXT6	tfr	a,cc	; SET CC
	BLE	NEXT8
NEXT7	LDX	FORSTK
	leax	1,x	; FIXUP PNTR
	leax	1,x
	leax	1,x
	STX	FORSTK	; SAVE IT
	LDX	NXPNTR
	STX	BUFPNT	; SAVE
	BRA	NEXT85
NEXT8	LDX	#TRYVAL
	JSR	GETVAL
	LDX	XTEMP4
	JSR	PUTLBL
NEXT85	JMP	RUNEXC
NEXT9	lda	#$81	; SET ERROR
NEXTIO	JMP	MISTAK

* EXPRESSION HANDLER

EXPR	CLR	STKCNT	; SET COUNT = 0
EXPRO	lda	STKCNT
	sta	AUXCNT
	BSR	EVAL
	tsta		; CHECK FOR ERROR
	BNE	NEXTIO
EXPR1	RTS		; RETURN
*
**EVAL
* EVALUATE AN ALGEBRAIC STRING
*
EVAL	STS	STKTOP	; SAVE SP TOP
EVA0A	JSR	SKYCLS
	STX	BUFPNT
	cmpb	#1	; SEE IF EMPTY EXPRESSION
	BNE	EVAL0
	lda	#$21
	BRA	EVAL3
EVAL0	lsrb		; SET UP
	cmpb	#3	; CHECK FOR UNARY + OR -
	BNE	EVAL1
	JSR	UPSCLR
EVAL1	LDX	BUFPNT
EVAL1A	JSR	SKYCLS	; GET NEXT CHAR
	STX	BUFPNT
	cmpb	#4	; CHECK FOR OPERATORS
	BLS	EVAL1Z
	ldb	#5	; SET UP
EVAL1Z	aslb
	stb	OFFREL+1	; SET UP BRANCH
OFFREL	BRA	*
	BRA	EVAL2	; ERROR
	BRA	EVAL4	; TERMINATOR
	BRA	EVAL8	; LETTER
	BRA	EVAL7	; NUMBER
	BRA	EVAL1C	; RIGHT PAREN
	pshs	A	; SAVE
	leax	1,x
	BRA	EVA0A	; AGAIN
EVAL1C	tfr	s,x	; GET SP
	ldb	DIMFLG
	CPX	STKTOP	; CHECK FOR EMPTY
	BEQ	EVAL1E
	puls	A	;
	clrb
	cmpa	#'(	; CHECK FOR L PAREN ON STACK
	lbeq	EVA11C	; IF SO, OK
EVAL1E
	TSTB		; CHECK FOR ALRIGHT
	BEQ	EVAL2	; IF NOT SET, ERROR
EVAL4	clra
	ldb	STKCNT	; GET STACK STKCNT
	decb		; CHECK OP STACK
	cmpb	AUXCNT
	BNE	EVAL2	; IF NOT EMPTY, ERROR
	tfr	s,x
	CPX	STKTOP	; CHECK OPERATOR STACK
	BEQ	EVAL3A	; IF NOT EMPTY ERROR
EVAL2	lda	#$20	; SET ERROR NUMBER
EVAL3	LDS	STKTOP	; GET SP
EVAL3A	LDX	BUFPNT	; SET POINTER
	RTS
EVAL7	JSR	STAKUP	; SHIFT OP STACK UP
	LDX	BUFPNT
	JSR	BCDCON	; GET OPERAND
	BRA	EVAL12
EVAL8	lda	1,X	; GET NEXT CHAR
	JSR	CLASS1	; GO CLASSIFY
	cmpb	#2	; CHECK FOR LETTER
	BNE	EVAL9	; IF NOT, VARIABLE
	lda	0,X	; GET CHAR BACK
	STX	XSAVE	; SET FOR ENTRY TO FIMDKEY
	LDX	#FCTTBL
	JSR	FNDKE2	; GO CHECK FUNCTION
	tsta		; CHECK SUCCESS
	BEQ	EVAL4
	JMP	RUNEX4	; GO SERVICE
EVAL86	lda	#'?	; GET STGNUM OPERATOR
EVAL87	pshs	A	; PUT ON STACK
	LDX	XSAVE
	JMP	EVA0A
EVAL85	lda	#'@	; GET ABS OPERATOR
	BRA	EVAL87
EVAL88	JSR	UPSCLR	; MOVE STACK UP
	JSR	RANDOM	; COMPUTE RANDOM #
	sta	NUMBER+2
EVAL89	LDX	XSAVE	; RESTORE POINTER
	BRA	EVAL12
EVAL9	ldb	STKTOP
	pshs	B	;
	ldb	STKTOP+1
	pshs	B	;
	ldb	AUXCNT	; GET COUNTER
	pshs	B	; SAVE
	ldb	DIMFLG	; GET FLAG
	pshs	B	; SAVE
	JSR	FNDLB0	; FIND VARIABLE STORAGE
	puls	B	; GET FLAG
	stb	DIMFLG	; RESTORE
	puls	B	; GET COUNTER
	stb	AUXCNT	; RESTORE
	puls	B	;
	stb	STKTOP+1
	puls	B	;
	stb	STKTOP
	JSR	STAKUP
	LDX	XTEMP
	JSR	GETVAL	; MOVE VALUE TO NUMBER
	BRA	EVA12A
EVA11C	LDX	BUFPNT	; RESTORE POINTER
	leax	1,x
EVAL12	STX	BUFPNT	; SAVE POINTER
EVA12A	tfr	s,x
	CPX	STKTOP	; CHECK OPERATOR STACK
	BEQ	EVAL10	; IF EMPTY, DON'T OPERATE
	puls	A	;
	pshs	A	; PUT BACK
	cmpa	#'(	; CHECK FOR LEFT PAREN
	BEQ	EVAL10	; IF SO, DON'T OPERATE
	JSR	CLASS1	; GO CLASSYFY
	pshs	B	;
	lsrb		; SET UP ID
	lda	STKCNT	; GET COUNT
	deca
	cmpb	#4	; CHECK FOR ABS OR SON
	BEQ	EVA12C	; IF SO, GO AHEAD
	cmpa	AUXCNT	; OTHERWISE CHECK FOR 2 OPERANDS
	BEQ	EVAL10	; IF NOT, ABORT
EVA12C	cmpa	#9	; CHECK OVERFLOW
	BLS	EVA12D	; OK
	lda	#$24	; SET ERROR
	BRA	EVAL19
EVA12D	puls	A	; GET CLASSIFICATION
	puls	B	; GET OPERATOR
	suba	#6	; REMOVE BIAS
	asla		; #2
	LDX	#OPTBL	; POINT
	jsr	[a,X]
	JSR	ZCHK	; CHECK RESULT
	BVC	EVA12A	; IF NO OVFL, GO OPERATE AGAIN
EVAL18	lda	#$23	; SET ERROR NUMBER
EVAL19	JMP	EVAL3
EVAL10	JMP	EVAL1
OPTBL	FDB	ADD
	FDB	SUB
	FDB	SIGNUM
	FDB	ABSVAL
	FDB	MULT
	FDB	DIVIDE
	FDB	EXPON
*
** GET VALUE
* MOVE 3 BYTES POINTED TO BY X TO NUMBER
*
GETVAL	lda	0,X	; GET VALUE
	sta	NUMBER	; STORE
	lda	1,X
	sta	NUMBER+1
	lda	2,X
	sta	NUMBER+2
	RTS
*
*
** STACKUP
* ROLL OPERATIONAL STACK UPWARD
*
STAKUP	LDX	#STKEND	; POINT TO END
STAKU2	ldb	3,X
	stb	0,X	; MOVE
	leax	1,x
	CPX	#NUMBER	; SEE IF DONE
	BNE	STAKU2
	INC	STKCNT
	RTS
*
*
** STACKDOWN
* ROLL OPERATIONAL STACK DOWNWARD
*
STAKDN	LDX	#AX-1	; POINT TO STORE
STAKD1	ldb	0,X
	stb	3,X
	leax	-1,x
	CPX	#STKEND-1	; SEE IF DONE
	BNE	STAKD1
	DEC	STKCNT
	RTS
*
*
** UADD
* UNSIGNED ADD OF AX TO NUMBER
*
UADD	andcc	#$fe	; ZERO THE CARRY
UADD1	LDX	#NUMBER+2	; POINT TO STORE
	pshs	cc	;
UADD2	lda	0,X	; GET ADDEND
	puls	cc
	adca	3,X	; ADD IN AUGEND
	DAA
	pshs	cc	;
	sta	0,X	; SAVE
	leax	-1,x
	CPX	#NUMBER-1	; SEE IF DONE
	BNE	UADD2
	puls	cc	;
UADD22	pshs	B	;
	ldb	#$02	; SET FOR OVFL
	bita	#$F0	; AND AGAIN
	BNE	UADD25
	clrb		; RESET OFVL
UADD25	orb	OVFLBF
	stb	OVFLBF	; SET OVFL IF NECESSARY
	tfr	b,a
	puls	B	;
UADD3	RTS
*
*
**USUB
* UNSIGNED SUBTRACT OF AX FROM NUMBER
*
USUB	BSR	TENCOM	; GO TEN'S COMPLEMENT
	orcc	#$1	; FIX UP
	BRA	UADD1	; GO ADD
*
*
**TENCOM
* UNSIGNED TEN'S COMPLEMENT OF AX (ALMOST)
*
TENCOM	LDX	#AX+2	; POINT TO AX
TENCO1	lda	#$99
	suba	0,X	; SUBTRACT FROM 99
	sta	0,X	; SAVE
	leax	-1,x
	CPX	#AX-1
	BNE	TENCO1
	anda	#$0F	; RESET SIGN
	sta	1,X	; STORE
	RTS
*
*
** SET SIN
* CALCULATE RESULT SIGN
*
SETSIN	CLR	OVFLBF	; CLEAR OVFL INDICATOR
SETSI0	lda	AX	; GET SIGN
	tfr	a,b	; SAVE
	andb	#$0F	; RESET SIGN
	stb	AX	; PUT BACK
	sta	AXSIGN	; SAVE SIGN
	eora	NUMBER	; FORM NEW SIGN
	sta	SIGN	; SAVE
ABSVAL	ldb	NUMBER	; GET MS BYTE
	andb	#$0F	; RESET SIGN
	stb	NUMBER	; PUT BACK
	tsta		; TEST NEW SIGN
	RTS
*
*
**
* SUBTRACT AX FROM NUMBER
*
SUB	lda	NUMBER	; GET MS BYTE
	eora	#$F0	; CHANGE SIGN
	sta	NUMBER	; PUT BACK
* GO INTO ADD
*
*
* ADD
* ADD AX TO NUMBER
*
ADD	BSR	STAKDN
	BSR	SETSIN	; GO CALCULATE SIGN
	BPL	ADD0	; USE EITHER SIGN
	BSR	USUB	; OTHERWISE SUBTRACT
	tfr	a,cc	; SET CCR
	BVC	ADD1	; CHECK OVERFLOW
	COM	AXSIGN	; CHANGE FOR AX SMALLER
	BRA	ADD15
ADD0	lbsr	UADD	; GO ADD
	BRA	ADD2	; GO FIX SIGN
ADD1	lbsr	STAKDN	; COPY NUMBER TO AX
	JSR	UPSCLR	; RESTORE
	BSR	USUB	; GO NEGATE
ADD15	CLR	OVFLBF
ADD2	lda	AXSIGN	; GET OLD SIGN
*
*
** FIXSIN
* SET THE SIGN ON THE RESULT
*
FIXSIN	anda	#$F0	; MASK
	ldb	#$0F	; SET MASK
	andb	NUMBER	; RESET SIGN
;	ABA	TACK ON SIGN
	stb	NUMBER
	adda	NUMBER
	sta	NUMBER	; PUT BACK
FIX2	RTS
*
*
** MULT
* MULTIPLY AC BY AX
*
MULT	lbsr	STAKDN	; MOVE STACK
	BSR	SETSIN	; GO CALC. SIGNS
MULT0	JSR	UPSCLR	; MOVE STACK UP
	ldb	#5	; SET COUNTER
MULT1	lda	AC	; GET MS BYTE OF AC
	BEQ	MULT3	; IF ZERO, LOOP
MULT2	JSR	UADD	; ADD IN AX
	dec	AC	; ONCE DONE
	BNE	MULT2
MULT3	decb		; ONCE DONE
	BEQ	MULT4	; CHECK IF ALL DONE
	BSR	ACLEFT	; SHIFT AC LEFT
	lda	NUMBER
	JSR	UADD22
	BRA	MULT1
*
*
** DIVIDE
* DIVIDE AC-NUMBER BY AX
*
DIVIDE	lbsr	STAKDN
	LDX	#AX
	JSR	ZCHK1	; GO CHECK IF AX=O
	BNE	DIVID1	; IF NOT, OK
DIVID0	lda	#$22	; SET ERROR
	JMP	EVAL3
DIVID1	JSR	SETSIN	; CALC, SIGNS
	JSR	STAKUP	; PUSH BACK
	BSR	ACLEFT	; SHIFT DOWN
	CLR	2,X
	CLR	3,X	; ZERO OUT NUMBER
	ldb	#5	; SET LOOP COUNT
DIVID2	BSR	ACLEFT	; MOVE AC DOWN
DIVI2A	JSR	TENCOM	; TAKE 10'S COMP
DIVID3	BSR	DADD	; GO SPECIAL ADD
	bita	#$F0	; CHECK FOR OVERFLOW
	BNE	DIVID4
	JSR	TENCOM	; IF SO, RESTORE AX
	andcc	#$fe
	BSR	DADD1	; ADD BACK IN
	decb		; ONE PASS MADE
	BNE	DIVID2
MULT4	lda	SIGN	; GET THE SIGN
	BSR	FIXSIN	; GO FIX UP THE SIGN
	LDX	#AC-1	; POINT TO AC
	JMP	STAKD1	; MOVE STACK BACK
DIVID4	INC	NUMBER+2	; ADD ONE IN
	BRA	DIVID3	; GO DO AGAIN
*
*
** ACLEFT
* SHIFT AC-NUMBER LEFT 4 BITS
*
ACLEFT	lda	#4	; SET FOR 4 BITS
ACLEF1	LDX	#AX-1	; POINT X
	andcc	#$fe
	pshs	cc	;
ACLEF2
	puls	cc	;
	ROL	0,X	; ROTATE
	pshs	cc	;
	leax	-1,x
	CPX	#AC-1	; CHECK IF DONE
	BNE	ACLEF2
	puls	cc	;
	deca		; CHECK FOR DONE
	BNE	ACLEF1
	RTS
*
*
** DADD
* ADD AX TO A C
*
DADD	orcc	#$1
DADD1	LDX	#AC+2
	lda	AC	; GET MS BYTE
	anda	#$0F	; RESET SIGN
	sta	AC	; STORE BACK
	pshs	cc	;
DADD2	lda	0,X	; GET ADDEND
	puls	cc	;
	adca	6,X	; ADD IN
	DAA
	pshs	cc	;
	sta	0,X	; SAVE
	leax	-1,x
	CPX	#AC-1	; SEE IF DONE
	BNE	DADD2
	puls	cc	;
	RTS
*
** SIGNUM
* CALCULATE SIGNUM FUNCTION
*
SIGNUM	BSR	ZCHK	; GO CHECK = O
	BEQ	SIGNU2	; IF SO RESULT =0
	ldb	NUMBER	; OTHERWISE GET SIGN
SIGNU1	BSR	SIGNU2	; GO CLEAR
	INC	NUMBER+2	; MAKE = I
	tfr	b,a	; SET FOR FIXSIN
	JMP	FIXSIN	; GO SET THE SIGN
SIGNU2	JMP	CLRNUM
*
*
** EXPON
* CALCULATE EXPONENTIATION
* ONLY POSITIVE EXPONENTS UP TO 99 ALLOWED
*
EXPON	lbsr	STAKDN	; MOVE OPERANDS DOWN
	clrb
	stb	OVFLBF	; CLEAR OVER FLOW
	lda	AX+2	; GET EXPONENT
	BEQ	SIGNU1	; IF O, GO MAKE RESULT +1
	JSR	STAKUP	; GET TWO COPIES
	lbsr	STAKDN	; MOVE DOWN
EXPON1	adda	#$99	; DECREMENT
	DAA
	BEQ	CMPX2	; WHEN 0 ALL DONE
	pshs	A	; SAVE EXP
	JSR	SETSI0	; GO FIX SIGNS
	JSR	MULT0	; GO MULTIPLY
	puls	A	; GET EXPONENT
	BRA	EXPON1	; LOOP
*
*
** CMPX
* FULL COMPARE ON X
* COMPARES X WITH CONTENTS OF CPX1
*
CMPX	STX	CPX2	; SAVE
CMPX1	lda	CPX2	; GET MS BYTE
	cmpa	CPX1	; COMPARE
	BNE	CMPX2	; IF NOT EQUAL, DONE
	ldb	CPX2+1	; GET LS BYTE
	cmpb	CPX1+1	; COMPARE
CMPX2	RTS		; DONE
*
*
** ZCHK
* CHECK OPERAND FOR EQUAL TO 0
*
ZCHK	LDX	#NUMBER
ZCHK1	clrb
	TST	2,X
	BNE	ZCHK2
	TST	1,X
	BNE	ZCHK2
	lda	0,X	; GET MS BYTE
	anda	#$0F
	BNE	ZCHK2	; CHECK FOR 0
	sta	0,X	; RESET SIGN BITS
	ldb	#4
ZCHK2	lda	0,X	; GET MS BYTE
	rora		; MOVE A SIGN BIT TO N
	anda	#8	; MASK N BIT
;	ABA	MERGE Z AND N
	tstb
	beq	ZCHK3
	ora	#4
ZCHK3
	ora	OVFLBF	; ADD IN V
	tfr	a,cc	; SET CCR
	RTS
*
*
**
SKYCLS	JSR	SKIPSP
	BRA	CLASS1
*
*
**CLASS
*CLASSIFY A CHARACTER IN THE A ACCUMULATOR
*CLASSIFICATION RETURNED IN B
*  0 ERROR
*  1 TERMINATOR
*  2 LETTER
*  3 NUMBER
*  4 )
*  5 (
*  6 +
*  7 -
*  8 SGN
*  9 ABS
* 10 *
* 11 /
* 12 ~
CLASS	lda	0,X	; GET CHAR
CLASS1	ldb	#1	; SET UP
	cmpa	#$D	; CHECK FOR CR
	BEQ	CLAS25
	decb
	pshs	A	; SAVE CHAR
CLAS2B	suba	#'(	; REMOVE BIAS
	BMI	CLASS2	; CHECK ILLEGAL
	cmpa	#'@-'(	; CHECK LIMIT
	BLS	CLASS3	; NOT LETTER
	cmpa	#'Z-'(	; CHECK FOR LETTER
	BLS	CLAS1B
	cmpa	#'^-'(	; CHECK FOR ILLEGAL
	BNE	CLASS2
	ldb	#10	; FIX UP
CLAS1B	addb	#02
CLASS2	puls	A	; RESTORE CHARACTER
CLAS25	RTS		; DONE
CLASS3	STX	XSAVE2	; SAVE X REG
	LDX	#CLSTBL	; POINT TO TABLE
	ldb 	a,X
	LDX	XSAVE2	; RESTORE X REG,
	BRA	CLASS2
CLSTBL	FCB	5,4,10,6,1,7,0,11,3,3,3,3
	FCB	3,3,3,3,3,3,1,1,1,1,1,8,9
*
*
* RANDOM GENERATOR
*
RANDOM	ldb	#8	; SET COUNTER
	LDX	#RNDM
RPT	lda	3,X	; GET M.S. BYTE OF RANDOM NO.
	asla		; SHIFT IT LEFT THREE:
	asla		; TIMES TO GET BIT 28
	asla		; IN LINE WITH BIT 31
	eora	3,X	; XOR A WITH RANDOM NO
	asla		; PUT BIT 28.XOR31 IN
	asla		; CARRY BY SHIFTING LEFT
	ROL	0,X	; ROTATE ALL FOUR BYTES OF
	ROL	1,X	; THE RANDOM NO, ROTATING
	ROL	2,X	; THE CARRY INTO THE LSB
	ROL	3,X	; THE MSB IS LOST
	decb		; DECREMENT THE COUNTER
	BNE	RPT	; IF ITS NOT O, GO REPEAT
	lda	0,X	; PUT RANDOM # IN A
	cmpa	#$9F	; CHECK IN RANGE
	BHI	RANDOM	; IF NOT GET ANOTHER
	adda	#0	; SET HALF CARRY
	DAA
	RTS

ENDSTR	RMB	2
STORSP	EQU	*

	ORG	EXTERN
	RTS
	END
