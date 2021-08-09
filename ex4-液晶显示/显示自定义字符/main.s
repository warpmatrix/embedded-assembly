GPIOA_BASE  EQU 0x40010800      ; GPIOA基地址
GPIOA_CRL   EQU GPIOA_BASE      ; 低配置寄存器
GPIOA_CRH   EQU GPIOA_BASE+4    ; 高配置寄存器
GPIOA_IDR   EQU GPIOA_BASE+0x08 ; 输入数据寄存器
GPIOA_ODR   EQU GPIOA_BASE+0x0c ; 输出数据寄存器
GPIOA_BSRR  EQU GPIOA_BASE+0x10 ; 端口位置位/清除寄存器
GPIOA_BRR   EQU GPIOA_BASE+0x14 ; 端口位清除寄存器
CFGAL       EQU 0x33333333      ; PA0~7：  推挽输出，50MHz
CFGAH       EQU 0x40000033      ; PA8~11： 推挽输出，50MHz    PA15：浮空输入

GPIOB_BASE EQU 0x40010c00       ; GPIOB基地址
GPIOB_CRL  EQU GPIOB_BASE+0x00  ; GPIOB低配置寄存器
GPIOB_CRH  EQU GPIOB_BASE+0x04  ; GPIOB高配置寄存器
GPIOB_IDR  EQU GPIOB_BASE+0x08  ; GPIOB输入数据寄存器
GPIOB_ODR  EQU GPIOB_BASE+0x0c  ; GPIOB输出数据寄存器
GPIOB_BSRR EQU GPIOB_BASE+0x10  ; GPIOB位端口置位/清零寄存器
CFGBL      EQU 0x0003      		; GPIOB配置：PB0--推挽输出(50MHz)；
	
RCC_APB2ENR EQU 0x40021018
GIOPAEN     EQU 0x00000004  			; GPIOA使能位
GIOPBEN     EQU 0x00000008      		; RCC时钟GPIOB使能位
AFIOEN      EQU 0x00000001      		; AFIO时钟使能位	
APB2ENALL   EQU GIOPAEN :OR: GIOPBEN	; 可以:OR:其它使能位

CLEAR		EQU 0x01
RESETCUR	EQU	0x02
INMODE		EQU	0x06
DISPON		EQU	0x0c
DISPMODE	EQU 0x38
DEFSYM		EQU 0x40
CRLF		EQU	0xc0

WRTSYM		EQU	0x0200
WRTDIGIT	EQU 0x0230
WRTLETTER	EQU 0x0241
WRTDOT		EQU	0x022e
WRTSPACE	EQU	0x0220


STACK_TOP EQU 0X20002000
 AREA RESET,CODE,READONLY   ; AREA不能顶格写
 DCD STACK_TOP 				; MSP主堆栈指针
 DCD START   				; 复位，PC初始值 
 ENTRY         				; 指示开始执行,有了C文件，ENTRY注释掉
START                      	; 所有的标号必须顶格写，且无冒号

; 设置RCC的APB2使能寄存器，启动 GPIOA、GPIOB 部件
 LDR    R1, =RCC_APB2ENR     ; 0X4002101C
 LDR    R0, =APB2ENALL
 STR    R0, [R1]             ; 使能GPIOA,GPIOB

; 设置 GPIOA 配置寄存器，令 PA0~PA9 设置为推挽输出(50MHz)，P15为浮空输入
 MOV    R0, #CFGAL
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]
 LDR    R0, =CFGAH
 LDR    R1, =GPIOA_CRH
 STR    R0, [R1]
 
;设置GPIOB低配置寄存器：PB0 推挽输出(50MHz)
 MOV    R0, #CFGBL
 LDR    R1, =GPIOB_CRL
 STR    R0, [R1]
 
 BL LedDefDeg
 BL LedInit
 
 LDR	R1, =GPIOA_ODR
 MOV	R2, #WRTDIGIT
 
 ADD	R0, R2, #2
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #0
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #2
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #0
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #WRTDOT
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #1
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #1
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #WRTDOT
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #8
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #WRTSPACE
 STR	R0, [R1]
 BL ExcCmd
 STR	R0, [R1]
 BL ExcCmd
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #2
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #3
 STR	R0, [R1]
 BL ExcCmd
 
 ; MOV	R0, #WRTSPACE
 ; STR	R0, [R1]
 ; BL ExcCmd
 
 MOV	R0, #WRTSYM
 ADD	R0, #0x03
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #CRLF
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R2, #WRTLETTER
 ADD	R0, R2, #('S'-'A')
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #('Y'-'A')
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #('S'-'A')
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #('U'-'A')
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #WRTDOT
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #('E'-'A')
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #('D'-'A')
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #('U'-'A')
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #WRTDOT
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #('C'-'A')
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #('N'-'A')
 STR	R0, [R1]
 BL ExcCmd
 
LOOP
 B LOOP
 
LedDefDeg
 PUSH	{R0, R1, R2, R3, LR}
 LDR	R1, =GPIOA_ODR
 MOV	R2, #DEFSYM
 ; 确定自定义字符的序号 3
 ADD	R2, #0x18
 
 MOV	R3, #WRTSYM
 
 ADD	R0, R2, #0
 STR	R0, [R1]
 BL ExcCmd
 ADD	R0, R3, #0x10
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #1
 STR	R0, [R1]
 BL ExcCmd
 ADD	R0, R3, #0x06
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #2
 STR	R0, [R1]
 BL ExcCmd
 ADD	R0, R3, #0x09
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #3
 STR	R0, [R1]
 BL ExcCmd
 ADD	R0, R3, #0x08
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #4
 STR	R0, [R1]
 BL ExcCmd
 ADD	R0, R3, #0x08
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #5
 STR	R0, [R1]
 BL ExcCmd
 ADD	R0, R3, #0x09
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #6
 STR	R0, [R1]
 BL ExcCmd
 ADD	R0, R3, #0x06
 STR	R0, [R1]
 BL ExcCmd
 
 ADD	R0, R2, #7
 STR	R0, [R1]
 BL ExcCmd
 ADD	R0, R3, #0x00
 STR	R0, [R1]
 BL ExcCmd
 
 POP	{R0, R1, R2, R3, PC}

 
LedInit
 PUSH	{R0, R1, LR}
 LDR	R1, =GPIOA_ODR
 
 MOV	R0, #DISPMODE
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #DISPON
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #INMODE
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #CLEAR
 STR	R0, [R1]
 BL ExcCmd
 
 MOV	R0, #RESETCUR
 STR	R0, [R1]
 BL	ExcCmd
 
 POP	{R0, R1, PC}
 
 
ExcCmd
 PUSH	{R0, R1, LR}
 LDR	R1, =GPIOB_ODR
 MOV	R0, #1
 STR	R0, [R1]
 MOV	R0, #0
 STR	R0, [R1]
 BL Delay
 POP	{R0, R1, PC}
 
Delay
  PUSH {R0,R1,R2,LR}
               
  MOVS R0,#0
  MOVS R1,#0
  MOVS R2,#0
                
DelayLoop0        
  ADDS R0,#1

  CMP R0,#33
  BCC DelayLoop0
 
  MOVS R0,#0
  ADDS R1,#1
  CMP R1,#33
  BCC DelayLoop0

  MOVS R0,#0
  MOVS R1,#0
  ADDS R2,#1
  CMP R2,#3
  BCC DelayLoop0                
  POP {R0,R1,R2,PC}   

 END
