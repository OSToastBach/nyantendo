;FamiTone2 v1.12



;settings, uncomment or put them into your main program; the latter makes possible updates easier

; FT_BASE_ADR		= $0300	;page in the RAM used for FT2 variables, should be $xx00
; FT_TEMP			= $00	;3 bytes in zeropage used by the library as a scratchpad
; FT_DPCM_OFF		= $c000	;$c000..$ffc0, 64-byte steps
; FT_SFX_STREAMS	= 4		;number of sound effects played at once, 1..4

; FT_DPCM_ENABLE			;undefine to exclude all DMC code
; FT_SFX_ENABLE			;undefine to exclude all sound effects code
; FT_THREAD				;undefine if you are calling sound effects from the same thread as the sound update call

; FT_PAL_SUPPORT			;undefine to exclude PAL support
; FT_NTSC_SUPPORT			;undefine to exclude NTSC support



;internal defines

	.if(FT_PAL_SUPPORT)
	.if(FT_NTSC_SUPPORT)
FT_PITCH_FIX = (FT_PAL_SUPPORT|FT_NTSC_SUPPORT)			;add PAL/NTSC pitch correction code only when both modes are enabled
	.endif
	.endif

FT_DPCM_PTR		= (FT_DPCM_OFF&$3fff)>>6


;zero page variables

FT_TEMP_PTR			= FT_TEMP		;word
FT_TEMP_PTR_L		= FT_TEMP_PTR+0
FT_TEMP_PTR_H		= FT_TEMP_PTR+1
FT_TEMP_VAR1		= FT_TEMP+2


FT_OUT_BUF		= FT_VARS+12	;11 bytes


;sound effect stream variables, 2 bytes and 15 bytes per stream
;when sound effects are disabled, this memory is not used

FT_SFX_ADR_L		= FT_VARS+23
FT_SFX_ADR_H		= FT_VARS+24
FT_SFX_BASE_ADR		= FT_VARS+25

FT_SFX_STRUCT_SIZE	= 15
FT_SFX_REPEAT		= FT_SFX_BASE_ADR+0
FT_SFX_PTR_L		= FT_SFX_BASE_ADR+1
FT_SFX_PTR_H		= FT_SFX_BASE_ADR+2
FT_SFX_OFF			= FT_SFX_BASE_ADR+3
FT_SFX_BUF			= FT_SFX_BASE_ADR+4	;11 bytes


;aliases for sound effect channels to use in user calls

FT_SFX_CH0			= FT_SFX_STRUCT_SIZE*0
FT_SFX_CH1			= FT_SFX_STRUCT_SIZE*1
FT_SFX_CH2			= FT_SFX_STRUCT_SIZE*2
FT_SFX_CH3			= FT_SFX_STRUCT_SIZE*3


;aliases for the APU registers

APU_PL1_VOL		= $4000
APU_PL1_SWEEP	= $4001
APU_PL1_LO		= $4002
APU_PL1_HI		= $4003
APU_PL2_VOL		= $4004
APU_PL2_SWEEP	= $4005
APU_PL2_LO		= $4006
APU_PL2_HI		= $4007
APU_TRI_LINEAR	= $4008
APU_TRI_LO		= $400a
APU_TRI_HI		= $400b
APU_NOISE_VOL	= $400c
APU_NOISE_LO	= $400e
APU_NOISE_HI	= $400f
APU_DMC_FREQ	= $4010
APU_DMC_RAW		= $4011
APU_DMC_START	= $4012
APU_DMC_LEN		= $4013
APU_SND_CHN		= $4015


;aliases for the APU registers in the output buffer

	.if(!FT_SFX_ENABLE)				;if sound effects are disabled, write to the APU directly
FT_MR_PULSE1_V		= APU_PL1_VOL
FT_MR_PULSE1_L		= APU_PL1_LO
FT_MR_PULSE1_H		= APU_PL1_HI
FT_MR_PULSE2_V		= APU_PL2_VOL
FT_MR_PULSE2_L		= APU_PL2_LO
FT_MR_PULSE2_H		= APU_PL2_HI
FT_MR_TRI_V			= APU_TRI_LINEAR
FT_MR_TRI_L			= APU_TRI_LO
FT_MR_TRI_H			= APU_TRI_HI
FT_MR_NOISE_V		= APU_NOISE_VOL
FT_MR_NOISE_F		= APU_NOISE_LO
	.else								;otherwise write to the output buffer
FT_MR_PULSE1_V		= FT_OUT_BUF
FT_MR_PULSE1_L		= FT_OUT_BUF+1
FT_MR_PULSE1_H		= FT_OUT_BUF+2
FT_MR_PULSE2_V		= FT_OUT_BUF+3
FT_MR_PULSE2_L		= FT_OUT_BUF+4
FT_MR_PULSE2_H		= FT_OUT_BUF+5
FT_MR_TRI_V			= FT_OUT_BUF+6
FT_MR_TRI_L			= FT_OUT_BUF+7
FT_MR_TRI_H			= FT_OUT_BUF+8
FT_MR_NOISE_V		= FT_OUT_BUF+9
FT_MR_NOISE_F		= FT_OUT_BUF+10
	.endif





	.if(FT_SFX_ENABLE)

	;process all sound effect streams

	.if FT_SFX_STREAMS>0
	ldx #FT_SFX_CH0
	jsr _FT2SfxUpdate
	.endif
	.if FT_SFX_STREAMS>1
	ldx #FT_SFX_CH1
	jsr _FT2SfxUpdate
	.endif
	.if FT_SFX_STREAMS>2
	ldx #FT_SFX_CH2
	jsr _FT2SfxUpdate
	.endif
	.if FT_SFX_STREAMS>3
	ldx #FT_SFX_CH3
	jsr _FT2SfxUpdate
	.endif


	;send data from the output buffer to the APU

	lda FT_OUT_BUF		;pulse 1 volume
	sta APU_PL1_VOL
	lda FT_OUT_BUF+1	;pulse 1 period LSB
	sta APU_PL1_LO
	lda FT_OUT_BUF+2	;pulse 1 period MSB, only applied when changed
	cmp FT_PULSE1_PREV
	beq @no_pulse1_upd
	sta FT_PULSE1_PREV
	sta APU_PL1_HI
@no_pulse1_upd:

	lda FT_OUT_BUF+3	;pulse 2 volume
	sta APU_PL2_VOL
	lda FT_OUT_BUF+4	;pulse 2 period LSB
	sta APU_PL2_LO
	lda FT_OUT_BUF+5	;pulse 2 period MSB, only applied when changed
	cmp FT_PULSE2_PREV
	beq @no_pulse2_upd
	sta FT_PULSE2_PREV
	sta APU_PL2_HI
@no_pulse2_upd:

	lda FT_OUT_BUF+6	;triangle volume (plays or not)
	sta APU_TRI_LINEAR
	lda FT_OUT_BUF+7	;triangle period LSB
	sta APU_TRI_LO
	lda FT_OUT_BUF+8	;triangle period MSB
	sta APU_TRI_HI

	lda FT_OUT_BUF+9	;noise volume
	sta APU_NOISE_VOL
	lda FT_OUT_BUF+10	;noise period
	sta APU_NOISE_LO

	.endif

	rts




	.if(FT_SFX_ENABLE)

;------------------------------------------------------------------------------
; init sound effects player, set pointer to data
; in: X,Y is address of sound effects data
;------------------------------------------------------------------------------

FamiToneSfxInit:

	stx <FT_TEMP_PTR_L
	sty <FT_TEMP_PTR_H
	
	ldy #0
	
	.if(FT_PITCH_FIX)

	lda FT_PAL_ADJUST		;add 2 to the sound list pointer for PAL
	bne @ntsc
	iny
	iny
@ntsc:

	.endif
	
	lda (FT_TEMP_PTR),y		;read and store pointer to the effects list
	sta FT_SFX_ADR_L
	iny
	lda (FT_TEMP_PTR),y
	sta FT_SFX_ADR_H

	ldx #FT_SFX_CH0			;init all the streams

@set_channels:
	jsr _FT2SfxClearChannel
	txa
	clc
	adc #FT_SFX_STRUCT_SIZE
	tax
	cpx #FT_SFX_STRUCT_SIZE*FT_SFX_STREAMS
	bne @set_channels

	rts


;internal routine, clears output buffer of a sound effect
;in: A is 0
;    X is offset of sound effect stream

_FT2SfxClearChannel:

	lda #0
	sta FT_SFX_PTR_H,x		;this stops the effect
	sta FT_SFX_REPEAT,x
	sta FT_SFX_OFF,x
	sta FT_SFX_BUF+6,x		;mute triangle
	lda #$30
	sta FT_SFX_BUF+0,x		;mute pulse1
	sta FT_SFX_BUF+3,x		;mute pulse2
	sta FT_SFX_BUF+9,x		;mute noise

	rts


;------------------------------------------------------------------------------
; play sound effect
; in: A is a number of the sound effect 0..127
;     X is offset of sound effect channel, should be FT_SFX_CH0..FT_SFX_CH3
;------------------------------------------------------------------------------

FamiToneSfxPlay:

	asl a					;get offset in the effects list
	tay

	jsr _FT2SfxClearChannel	;stops the effect if it plays

	lda FT_SFX_ADR_L
	sta <FT_TEMP_PTR_L
	lda FT_SFX_ADR_H
	sta <FT_TEMP_PTR_H

	lda (FT_TEMP_PTR),y		;read effect pointer from the table
	sta FT_SFX_PTR_L,x		;store it
	iny
	lda (FT_TEMP_PTR),y
	sta FT_SFX_PTR_H,x		;this write enables the effect

	rts


	
;internal routine, update one sound effect stream
;in: X is offset of sound effect stream

_FT2SfxUpdate:

	lda FT_SFX_REPEAT,x		;check if repeat counter is not zero
	beq @no_repeat
	dec FT_SFX_REPEAT,x		;decrement and return
	bne @update_buf			;just mix with output buffer

@no_repeat:
	lda FT_SFX_PTR_H,x		;check if MSB of the pointer is not zero
	bne @sfx_active
	rts						;return otherwise, no active effect

@sfx_active:
	sta <FT_TEMP_PTR_H		;load effect pointer into temp
	lda FT_SFX_PTR_L,x
	sta <FT_TEMP_PTR_L
	ldy FT_SFX_OFF,x
	clc

@read_byte:
	lda (FT_TEMP_PTR),y		;read byte of effect
	bmi @get_data			;if bit 7 is set, it is a register write
	beq @eof
	iny
	sta FT_SFX_REPEAT,x		;if bit 7 is reset, it is number of repeats
	tya
	sta FT_SFX_OFF,x
	jmp @update_buf

@get_data:
	iny
	stx <FT_TEMP_VAR1		;it is a register write
	adc <FT_TEMP_VAR1		;get offset in the effect output buffer
	tax
	lda (FT_TEMP_PTR),y		;read value
	iny
	sta FT_SFX_BUF-128,x	;store into output buffer
	ldx <FT_TEMP_VAR1
	jmp @read_byte			;and read next byte

@eof:
	sta FT_SFX_PTR_H,x		;mark channel as inactive

@update_buf:

	lda FT_OUT_BUF			;compare effect output buffer with main output buffer
	and #$0f				;if volume of pulse 1 of effect is higher than that of the
	sta <FT_TEMP_VAR1		;main buffer, overwrite the main buffer value with the new one
	lda FT_SFX_BUF+0,x
	and #$0f
	cmp <FT_TEMP_VAR1
	bcc @no_pulse1
	lda FT_SFX_BUF+0,x
	sta FT_OUT_BUF+0
	lda FT_SFX_BUF+1,x
	sta FT_OUT_BUF+1
	lda FT_SFX_BUF+2,x
	sta FT_OUT_BUF+2
@no_pulse1:

	lda FT_OUT_BUF+3		;same for pulse 2
	and #$0f
	sta <FT_TEMP_VAR1
	lda FT_SFX_BUF+3,x
	and #$0f
	cmp <FT_TEMP_VAR1
	bcc @no_pulse2
	lda FT_SFX_BUF+3,x
	sta FT_OUT_BUF+3
	lda FT_SFX_BUF+4,x
	sta FT_OUT_BUF+4
	lda FT_SFX_BUF+5,x
	sta FT_OUT_BUF+5
@no_pulse2:

	lda FT_SFX_BUF+6,x		;overwrite triangle of main output buffer if it is active
	beq @no_triangle
	sta FT_OUT_BUF+6
	lda FT_SFX_BUF+7,x
	sta FT_OUT_BUF+7
	lda FT_SFX_BUF+8,x
	sta FT_OUT_BUF+8
@no_triangle:

	lda FT_OUT_BUF+9		;same as for pulse 1 and 2, but for noise
	and #$0f
	sta <FT_TEMP_VAR1
	lda FT_SFX_BUF+9,x
	and #$0f
	cmp <FT_TEMP_VAR1
	bcc @no_noise
	lda FT_SFX_BUF+9,x
	sta FT_OUT_BUF+9
	lda FT_SFX_BUF+10,x
	sta FT_OUT_BUF+10
@no_noise:

	rts

	.endif

