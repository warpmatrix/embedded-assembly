; 本项目利用 GPIOA.2 实现 led 灯的闪烁效果
BIT2       	EQU 0x00000004
LED        	EQU BIT2       ;LED--PA.2
CFGA       	EQU 0x00000300  ;PA.2: 推挽输出，50MHz
	
GPIOA      	EQU 0x40010800  ;GPIOA 地址
GPIOA_CRL  	EQU 0x40010800  ;低配置寄存器
GPIOA_CRH  	EQU 0x40010804  ;高配置寄存器
GPIOA_ODR  	EQU 0x4001080C  ;输出，偏移地址 0Ch
GPIOA_BSRR 	EQU 0x40010810  ;低置位，高清除偏移地址 10h
GPIOA_BRR  	EQU 0x40010814  ;清除寄存器偏移地址 14h
GIOPAEN    	EQU 0x00000004  ;GPIOA 时钟使能
RCC_APB2ENR EQU 0x40021018

STACK_TOP EQU 0x20002000
 AREA RESET,CODE,READONLY
 DCD STACK_TOP 				; MSP 主堆栈指针
 DCD START   				; 复位 PC 初始值
 ENTRY         				; 指示开始执行
START                      	
 LDR    R1, =RCC_APB2ENR    ; 0x40021018
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]             ; 使能 GPIOA 时钟
 
;LED--PA.2  推挽输出 50MHz  0011
 MOV    R0, #CFGA
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]              
 NOP
 NOP
LOOP5
 LDR    R1, =GPIOA_ODR 
 LDR    R2, =LED             ;PA.2 输出高电平
 STR    R2, [R1]
 BL Delay
 LDR    R2, =0x0             ;PA.2 输出低电平
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