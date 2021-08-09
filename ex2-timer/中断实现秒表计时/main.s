; 本项目采用时钟更新事件中断方式实现秒表，从00分00秒开始计数，采用数码管显示分和秒
; 把数码管的引脚 a~g 和 dp 连接到 PA0~7，数码管的引脚 1~4 连至 PA8~11
	
GPIOA_BASE  EQU 0X40010800      ; GPIOA 基地址
GPIOA_CRL   EQU GPIOA_BASE      ; 低配置寄存器
GPIOA_CRH   EQU GPIOA_BASE+4    ; 高配置寄存器
GPIOA_ODR   EQU GPIOA_BASE+0XC  ; 输出，偏移地址 0ch
GPIOA_BSRR  EQU GPIOA_BASE+0X10 ; 低置位高清除，偏移地址 10h
GPIOA_BRR   EQU GPIOA_BASE+0X14 ; 清除，偏移地址 14h
	
CFGAL        EQU 0x33333333      ;PA0~7		推挽输出，50MHz
CFGAH        EQU 0x00003333      ;PA8~11	推挽输出，50MHz

TIM2        EQU 0X40000000  ; TIM2 及地址
TIM2_ARR    EQU TIM2+0X2C   ; 自动装载寄存器
TIM2_PSC    EQU TIM2+0X28   ; 预分频器
TIM2_DIER   EQU TIM2+0X0C   ; DMA/中断使能寄存器
TIM2_CR1    EQU TIM2+0X00   ; 控制寄存器 1
TIM2_SR     EQU TIM2+0X10   ; 状态寄存器
	
RCC_APB2ENR EQU 0X40021018
GIOPAEN     EQU 0X00000004  ;GPIOA 使能位
;GIOPBEN     EQU 0X00000008  ;GPIOB 使能位
;GIOPALLEN   EQU GIOPAEN :OR: GIOPBEN

RCC_APB1ENR EQU 0X4002101C
TIM2EN      EQU 0X00000001  ;TIM2 使能位

ISER_TIM2   EQU 0xe000e100  ;
TIM2_ITEN   EQU 0x10000000

STACK_TOP EQU 0X20002000
	
 AREA MYDATA,DATA,READONLY                                               ; AREA 不能顶格写
CODES    DCB 0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f,0x00,0x00 ; 数码管 0~9 的字模
DIGITPOS DCB 0x07,0x0b,0x0d,0x0e                                         ; 定位要显示的数字：第 0~3 位为数码管 4 个数字的控制信号，为 0 显示

 AREA MYDATA2,DATA,READWRITE       ; AREA 不能顶格写（RAM，自动初始化为 0）
DIGITS    DCB 0x00,0x00,0x00,0x00  ; 正在显示的 4 个数字，取值 0~9
CURSELECT DCB 0x00                 ; 当前显示哪个数字，取值 0~3

 AREA RESET,CODE,READONLY   ; AREA 不能顶格写
 DCD STACK_TOP 				; MSP 主堆栈指针
 DCD START   				; 复位，PC 初始值
 SPACE 0xB0-8;
 DCD   TIM2_IRQHandler      ; TIM2
 ENTRY         				; 指示开始执行
START                      	; 标号顶格写，无冒号
 BL     RCC_CONFIG_72MHZ
 BL 	InitRamArea
 
 ; 配置 RCC 的 APB2 使能寄存器，启动 GPIOA
 LDR    R1, =RCC_APB2ENR
 LDR    R0, [R1]
 LDR    R2, =GIOPAEN         
 ORR    R0, R2
 STR    R0, [R1]
 
 ; 配置 GPIO 配置寄存器，设置 GPIOA.2 PA0~PA11 为推挽输出和 50MHz
 MOV    R0, #CFGAL
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]              
 MOV    R0, #CFGAH
 LDR    R1, =GPIOA_CRH
 STR    R0, [R1]            
 
 ; 设置 RCC 的 APB1 使能寄存器，启动 TIM2 时钟
 LDR    R1, =RCC_APB1ENR
 LDR    R0, [R1]
 LDR    R2, =TIM2EN
 ORR    R0, R2
 STR    R0, [R1]
 
 ; 设置定时器 Tim2 的重装载寄存器
 MOV    R0, #(10000-1)
 LDR    R1, =TIM2_ARR
 STR    R0, [R1]              

 ; 设置定时器 Tim2 的分频器
 MOV    R0, #(7200-1)
 LDR    R1, =TIM2_PSC
 STR    R0, [R1]             

 ; 设置定时器 Tim2 的 DMA/中断允许寄存器
 MOV    R0, #1
 LDR    R1, =TIM2_DIER
 STR    R0, [R1] 
   
 ; 设置 NVIC 的中断设置运训寄存器(ISER)
 MOV    R0, #TIM2_ITEN
 LDR    R1, =ISER_TIM2   ;0xE000E100
 STR    R0, [R1] 

 ; 设置定时器 Tim2 的配置寄存器，启动计数
 MOV    R0, #1
 LDR    R1, =TIM2_CR1
 STR    R0, [R1]      
 LDR    R1, =TIM2_SR 
 MOV    R2, #0              ; Çå³ý¸üÐÂÊÂ¼þ×´Ì¬Î»
 STR    R2,[R1]        

 
LOOP
 BL ShowDigits
 nop
 B LOOP
 
Delay
  PUSH {R0,R1,R2,LR}
  LDR    R1, =TIM2_SR 
Delay1
  BL ShowDigits
  LDR    R2, [R1]      ; 读状态寄存器
  TST    R2,#1         ; 测试是否有更新事件
  BEQ    Delay1		   ; 无，重复查询

  MOV    R2, #0        ; 有，清除更新事件状态
  STR    R2,[R1]

  POP {R0,R1,R2,PC}
	  
; 所有 RAM(MYDATA2) 中的数据必须进行初始化
InitRamArea
	PUSH {R5,R6,LR}
	
	; 初始化 CURSELECT
	LDR  R5,=CURSELECT
    MOV  R6,#0
    STRB R6,[R5]   

    ; 初始化 DIGITS
    LDR R5,=DIGITS	
	MOV R6,#0
    STRB R6,[R5,#3]
    STRB R6,[R5,#2]
    STRB R6,[R5,#1]
    STRB R6,[R5,#0]
	
	POP {R5,R6,PC}
	  
; 每次调用显示一位数字（CURSELECT）
ShowDigits
  PUSH {R4,R5,R6,R7,LR}
  
  ; È·¶¨ÏÂÒ»¸öµ±Ç°ÒªÏÔÊ¾µÄÊý×Ö
  LDR  R5,=CURSELECT
  LDRB R6,[R5]
  ADD  R6,#1     ; Ã¿¸öÊý×Ö4¸ö×Ö½Ú
  CMP  R6,#4
  BNE  SGNEXT
  MOV  R6,#0  
SGNEXT
  STRB R6,[R5]  
  
  ; È¡³ö×ÖÄ£
  LDR  R5,=DIGITS
  LDRB R7,[R6,R5]
  LDR  R5, =CODES  
  LDRB R7,[R5,R7]
  
  ; ÐÎ³ÉÊý×Ö¿ØÖÆÏß
  LDR  R5,=DIGITPOS 
  LDRB R4,[R5,R6] 
  LSL  R4,R4,#8  
  ADD  R7,R4
  
  ; °Ñ×ÖÄ£ºÍÎ»¿ØÖÆÊä³öµ½PA0~11
  LDR  R5, =GPIOA_ODR 
  STR  R7,[R5]   
  POP {R4,R5,R6,R7,PC}
		
AddTimer
  PUSH {R1,R5,LR}
  LDR    R5,=DIGITS
  
  ; 时间最低位加 1，如果加到 10，则进行进位操作
  LDRB   R1,[R5,#0]
  ADD    R1,#1
  STRB   R1,[R5,#0]
  CMP    R1, #10
  BNE    EXIT2
  MOV    R1,#0
  STRB   R1,[R5,#0]
  
  ; 更新时间次低位
  LDRB   R1,[R5,#1]
  ADD    R1,#1
  STRB   R1,[R5,#1]
  CMP    R1,#6
  BNE    EXIT2
  MOV    R1,#0
  STRB   R1,[R5,#1]
  
  ; 更新时间次高位
  LDRB   R1,[R5,#2]
  ADD    R1,#1
  STRB   R1,[R5,#2]
  CMP    R1,#10
  BNE    EXIT2
  MOV    R1,#0
  STRB   R1,[R5,#2]
  
  ; 更新时间最高位
  LDRB   R1,[R5,#3]
  ADD    R1,#1
  STRB   R1,[R5,#3]
  CMP    R1,#6
  BNE    EXIT2  
  MOV    R1,#0
  STRB   R1,[R5,#3]
  
EXIT2
  POP {R1,R5,PC}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;RCC  Ê±ÖÓÅäÖÃ HCLK=72MHz=HSE*9
;;;PCLK2=HCLK  PCLK1=HCLK/2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RCC_CONFIG_72MHZ
 LDR    R1,=0X40021000 ;RCC_CR
 LDR    R0,[R1]
 LDR    R2,=0X00010000 ;HSEON
 ORR    R0,R2
 STR    R0,[R1]
WAIT_HSE_RDY
 LDR    R2,=0X00020000 ;HSERDY
 LDR    R0,[R1]
 ANDS   R0,R2
 CMP    R0,#0
 BEQ    WAIT_HSE_RDY
 LDR    R1,=0X40022000 ;FLASH_ACR
 MOV    R0,#0X12
 STR    R0,[R1]
 LDR    R1,=0X40021004 ;RCC_CFGRÊ±ÖÓÅäÖÃ¼Ä´æÆ÷
 LDR    R0,[R1]
;PLL±¶ÆµÏµÊý,PCLK2,PCLK1·ÖÆµÉèÖÃ
;HSE 9±¶ÆµPCLK2=HCLK,PCLK1=HCLK/2
;HCLK=72MHz 0x001D0400
;HCLK=64MHz 0x00190400
;HCLK=48MHz 0x00110400
;HCLK=32MHz 0x00090400
;HCLK=24MHz 0x00050400
;HCLK=16MHz 0x00010400
 LDR    R2,=0x001D0400 
 ORR    R0,R2
 STR    R0,[R1]
 LDR    R1,=0X40021000 ;RCC_CR  
 LDR    R0,[R1]
 LDR    R2,=0X01000000 ;PLLON
 ORR    R0,R2
 STR    R0,[R1]
WAIT_PLL_RDY
 LDR    R2,=0X02000000 ;PLLRDY
 LDR    R0,[R1]
 ANDS   R0,R2
 CMP    R0,#0
 BEQ    WAIT_PLL_RDY
 LDR    R1,=0X40021004 ;RCC_CFGR
 LDR    R0,[R1]
 MOV    R2,#0X02
 ORR    R0,R2
 STR    R0,[R1]
WAIT_HCLK_USEPLL
 LDR    R0,[R1]
 ANDS   R0,#0X08
 CMP    R0,#0X08
 BNE    WAIT_HCLK_USEPLL
 BX LR
	   
TIM2_IRQHandler
   PUSH {R1,R2,LR}
   BL AddTimer  
   LDR    R1, =TIM2_SR 
   MOV    R2, #0              ; Çå³ý¸üÐÂÊÂ¼þ×´Ì¬Î»
   STR    R2,[R1]
   POP {R1,R2,PC}
 END
