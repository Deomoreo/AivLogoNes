.db "NES", $1A, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0

.org $8000

.define PPUCTRL $2000
.define PPUMASK $2001
.define PPUSTATUS $2002
.define OAMADDR $2003
.define OAMDATA $2004
.define PPUSCROLL $2005
.define PPUADDR $2006
.define PPUDATA $2007
.define OAMDMA $4014

.define JOYPAD1 $4016
.define JOYPAD2 $4017
.define SCROLL_X $00
.define SCROLL_Y $01
.define buttons $02

.define High $05
.define Low  $06
.define addressLow $07
.define addressHigh $08
.define PatternTable $09
.define Row  $0A
.define Col $0B

.define PlayerX $11
.define PlayerY $12

start:
    LDA #%10000000
    STA PPUCTRL
    LDA #%00011110
    STA PPUMASK
    

    LDA #$3f
    STA PPUADDR
    LDA #$10
    STA PPUADDR
    
    
    LDA #$21
    STA PPUDATA
    LDA #$22
    STA PPUDATA
    LDA #$17
    STA PPUDATA
    LDA #$24
    STA PPUDATA
    
    LDA #$00
    STA OAMDATA
    

    LoadPalette:
        LDA PPUSTATUS         
        LDA #$3F
        STA PPUADDR           
        LDA #$00
        STA PPUADDR           
        LDX #$00              

    LoadBackgroundPaletteLoop:
    LDA background_palette,X        
    STA PPUDATA            
    INX                    
    CPX #$10              
    BNE LoadBackgroundPaletteLoop 

    LDA #$20
    STA addressHigh
    LDA #$00
    STA addressLow
    JSR NameTableCreate

    LDA #$24
    STA addressHigh
    LDA #$00
    STA addressLow
    JSR NameTableCreate

loop:
    JMP loop

NameTableCreate:
        LDA addressHigh
        STA High
        STA PPUADDR

        LDA addressLow
        STA Low
        STA PPUADDR

        LDY #0
        LDX #0
        STX PatternTable
        STX Row
        STX Col
        NextRow:
            LDA #%10010000
            STA PPUCTRL
            LDA PatternTable
            STA PPUDATA
            INC PatternTable
            LDA PatternTable
            CMP #$FF
            BEQ END

            INC Low
            LDA Low
            CMP #$00
            BEQ HighIncrease

            INC Col
            LDA Col
            CMP #$10
            BEQ NextLine
            JMP NextRow

        NextLine:
            LDA #%10000100
            STA PPUCTRL

            LDA High
            STA PPUADDR

            LDA Low
            ADC #$0F
            STA Low
            STA PPUADDR
            LDA #0
            STA Col
            INC Row
            LDA Row
            CMP #08
            BNE SkipHighIncrease
                HighIncrease:
                    INC High
                    LDA High
                    STA High
                    STA PPUADDR
                    LDA #$00
                    STA Low
                    STA PPUADDR
                        SkipHighIncrease:
                            LDA Row
                            CMP #$10
                            BNE NextRow
        END:                    
            RTS 

readjoy:
    LDA #$01
    STA JOYPAD1
    STA buttons
    LSR A
    STA JOYPAD1
joyloop:
    LDA JOYPAD1
    LSR A 
    ROL buttons
    BCC joyloop
    RTS

nmi:
    PHA
    JSR readjoy
    PLA
    ReadMoveUp:
        LDA buttons
        AND #%00001000
        BNE StartMoveUp
        JMP ReadUpDone

    ReadUpDone:

    ReadMoveDown:
        LDA buttons
        AND #%00000100
        BNE StartMoveDown
        JMP ReadDownDone

    ReadDownDone:

    ReadMoveLeft:
        LDA buttons
        AND #%00000010
        BNE StartMoveLeft
        JMP ReadLeftDone

    ReadLeftDone:

    ReadMoveRight:
            LDA buttons
            AND #%00000001
            BNE StartMoveRight
            JMP ReadRightDone
ReadRightDone:
  RTI

StartMoveLeft:
    DEC SCROLL_X
    JSR ApplyScroll
    LDX PlayerX
    CPX #$00
    BEQ ReadLeftDone
    DEX 
    LDA #3
    STA OAMADDR
    STX OAMDATA
    STX PlayerX
    JMP ReadLeftDone

StartMoveRight:
    INC SCROLL_X
    JSR ApplyScroll
    LDX PlayerX
    CPX #$F8
    BEQ ReadRightDone
    INX
    LDA #3
    STA OAMADDR
    STX OAMDATA
    STX PlayerX
    JMP ReadRightDone

StartMoveDown:
    INC SCROLL_Y
    JSR ApplyScroll
    LDY PlayerY
    CPY #$DF
    BEQ ReadDownDone
    INY
    LDA #0
    STA OAMADDR
    STY OAMDATA
    STY PlayerY
    JMP ReadDownDone

StartMoveUp:
    DEC SCROLL_Y
    JSR ApplyScroll
    LDY PlayerY
    CPY #$07
    BEQ ReadUpDone
    DEY
    LDA #0
    STA OAMADDR
    STY OAMDATA
    STY PlayerY
    JMP ReadUpDone

ApplyScroll:
    LDA SCROLL_X
    STA PPUSCROLL
    LDA #0
    STA PPUSCROLL

    
    EndScroll:
        RTS
RTI
irq:
    RTI

background_palette:
  .db $11,$05,$28,$0F	;background palette 1
  

.goto $FFFA

.dw nmi
.dw start   
.dw irq

.incbin "Cards.chr"
.incbin "aiv256.chr"
