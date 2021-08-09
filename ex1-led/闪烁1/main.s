; 本项目实现led灯(核心板上的PC13)闪烁
BIT13      EQU 0x00002000
LED2       EQU BIT13       ;LED2--PC.13
CFGC       EQU 0x00300000  ;PC.13： 推挽输出，50MHz
	
GPIOC      EQU 0x40011000  ;GPIOC 地址
GPIOC_CRL  EQU 0x40011000  ;低配置寄存器
GPIOC_CRH  EQU 0x40011004  ;高配置寄存器
GPIOC_ODR  EQU 0x4001100C  ;输出，偏移地址0Ch
GPIOC_BSRR EQU 0x40011010  ;低置位，高清除偏移地址10h
GPIOC_BRR  EQU 0x40011014  ;清除，偏移地址14h
GIOPCEN    EQU 0x00000010  ;GPIOC使能位
RCC_APB2ENR EQU 0x40021018

STACK_TOP EQU 0x20002000
 AREA RESET,CODE,READONLY   ; AREA不能顶格写,后面的"RESET"与XXX.sct文件中的" *.o (RESET, +First)"必须相同
 DCD STACK_TOP 				; MSP主堆栈指针
 DCD START   				; 复位，PC初始值 
 ENTRY         				; 指示开始执行,有了C文件，ENTRY注释掉
START                      	; 所有的标号必须顶格写，且无冒号
 LDR    R1, =RCC_APB2ENR    ; 0x40021018
 LDR    R0, [R1]
 LDR    R2, =GIOPCEN         
 ORR    R0, R2
 STR    R0, [R1]             ; 使能GPIOC时钟
 
;LED13--PC.13  推挽输出，50MHz  0011 （CNF，MODE）
 MOV    R0, #CFGC
 LDR    R1, =GPIOC_CRH
 STR    R0, [R1]              
 NOP
 NOP
LOOP5
 LDR    R1, =GPIOC_ODR 
 LDR    R2, =LED2            ;将PC.13输出高电平
 STR    R2, [R1]
 BL Delay
 LDR    R2, =0x0             ;将PC.13输出低电平
 STR    R2, [R1]
 BL Delay
 B LOOP5
 
Delay
  PUSH {R0,R1,R2,LR}
               
  MOVS R0,#0
  MOVS R1,#0
  MOVS R2,#0
                
DelayLoop0        
  ADDS R0,R0,#1

  CMP R0,#330
  BCC DelayLoop0
                
  MOVS R0,#0
  ADDS R1,R1,#1
  CMP R1,#330
  BCC DelayLoop0

  MOVS R0,#0
  MOVS R1,#0
  ADDS R2,R2,#1
  CMP R2,#15
  BCC DelayLoop0                
  POP {R0,R1,R2,PC}   
 END