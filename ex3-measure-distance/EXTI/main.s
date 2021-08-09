; 本项目实现数码管显示(毫米), 接线方法：
; 把数码管的a~f和dp连接到PA0~7，1~4连至PA8~11   
; 超声波检测器：Trig接PA12，Echo接PA15，Vcc接3.3v，Gnd接地

PULL0DOWN  EQU 0x00010000; ODR0=0--PX0输入下拉 (默认)  这里用于PB0
PULL0UP    EQU 0x00000001; ODR0=1--PX0输入上拉
	
GPIOA_BASE  EQU 0x40010800      ;GPIOA基地址
GPIOA_CRL   EQU GPIOA_BASE      ;低配置寄存器
GPIOA_CRH   EQU GPIOA_BASE+4    ;高配置寄存器
GPIOA_IDR   EQU GPIOA_BASE+0x08 ;输入数据寄存器
GPIOA_ODR   EQU GPIOA_BASE+0x0c ;输出数据寄存器
GPIOA_BSRR  EQU GPIOA_BASE+0x10 ;端口位置位/清除寄存器
GPIOA_BRR   EQU GPIOA_BASE+0x14 ;端口位清除寄存器
CFGAL        EQU 0x33333333      ;PA0~7：  推挽输出，50MHz
CFGAH        EQU 0x40033333      ;PA8~11： 推挽输出，50MHz    PA12；推挽输出，50MHz  PA15：浮空输入
	
GPIOB_BASE EQU 0x40010c00       ;GPIOB基地址
GPIOB_CRL  EQU GPIOB_BASE+0x00  ;GPIOB低配置寄存器
GPIOB_CRH  EQU GPIOB_BASE+0x04  ;GPIOB高配置寄存器
GPIOB_IDR  EQU GPIOB_BASE+0x08  ;GPIOB输入数据寄存器
GPIOB_ODR  EQU GPIOB_BASE+0x0c  ;GPIOB输出数据寄存器
GPIOB_BSRR EQU GPIOB_BASE+0x10  ;GPIOB位端口置位/清零寄存器
LED2ON     EQU 0x00000002  ; GPIOX_BSRR:   bit1=1---PX1 on
LED2OFF    EQU 0x00020000  ; GPIOX_BSRR:  bit17=1---PX1 off
CFGB       EQU 0x0038      ; GPIOB配置：PB0--下拉输入；PB1--推挽输出(50MHz)；

TIM2        EQU 0x40000000  ;TIM2基地址
TIM2_ARR    EQU TIM2+0x2c   ;自动装载寄存器
TIM2_PSC    EQU TIM2+0x28   ;预分频器
TIM2_DIER   EQU TIM2+0x0c   ;DMA/中断使能寄存器
TIM2_CR1    EQU TIM2+0x00   ;控制寄存器1
TIM2_SR     EQU TIM2+0x10   ;状态寄存器
TIM2_CNT    EQU TIM2+0x24   ;计数寄存器
	
RCC_APB2ENR EQU 0x40021018
AFIOEN      EQU 0x00000001  ;AFIO 时钟使能位
GIOPAEN     EQU 0x00000004  ;GPIOA 使能位
GIOPBEN     EQU 0x00000008  ;GPIOB 使能位
APB2ENALL   EQU GIOPAEN :OR: GIOPBEN :OR: AFIOEN
	
AFIO_BASE     EQU 0x40010000
AFIO_EXTICR1  EQU AFIO_BASE+0X08 ; 外部中断(EXTI)配置寄存器1
AFIO_EXTI0_PB EQU 0x1            ; EXTI0选择PB0作为输入
	
RCC_APB1ENR EQU 0x4002101c
TIM2EN      EQU 0x00000001  ;TIM2使能位
APB1ENALL   EQU TIM2EN	    ;可以:OR:其它使能位

EXTI_BASE  EQU 0x40010400
EXTI_IMR   EQU EXTI_BASE+0x00     ;EXTI中断屏蔽寄存器
EXTI_EMR   EQU EXTI_BASE+0x04     ;EXTI事件屏蔽寄存器
EXTI_PR    EQU EXTI_BASE+0x14     ;EXTI挂起寄存器
EXTI_RTSR  EQU EXTI_BASE+0x08     ;EXTI上升沿触发选择寄存器
RTSR_EXTI0 EQU 1                  ;EXTI0选择上升沿触发

NVIC_ISER0  EQU 0xe000e100  ;NVIC中断设置允许寄存器
TIM2_ITEN   EQU 0x10000000
EXTI0_ITEN  EQU 0x40         ;  允许EXTI0中断
ITEN        EQU TIM2_ITEN :OR: EXTI0_ITEN  ;可以:OR:其它使能位

STACK_TOP EQU 0X20002000
 AREA MYDATA,DATA,READONLY   ; AREA不能顶格写
CODES    DCB 0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f,0x77,0x7c,0x39,0x5e,0x79,0x71 ; 数码管0~9,a~f的字模
DIGITPOS DCB 0x07,0x0b,0x0d,0x0e                                         ; 定位要显示的数字：第0~3位为数码管4个数字的控制信号，为0则显示，否则不显示
 AREA MYDATA2,DATA,READWRITE   ; AREA不能顶格写(RAM,自动初始化为0)
DIGITS    DCB 0x00,0x00,0x00,0x00  ; 正在显示的4个数字，取值0~9
CURSELECT DCB 0x00                 ; 当前显示哪个数字，取值0~3 
          DCB 0x00                 ; padding
DURATION  DCW 0x00
 AREA RESET,CODE,READONLY   ; AREA不能顶格写
 DCD STACK_TOP 				; MSP主堆栈指针
 DCD START   				; 复位，PC初始值 
 SPACE 0x58-8;
 DCD   EXTI0_IRQHandler
 ENTRY         				; 指示开始执行,有了C文件，ENTRY注释掉
START                      	; 所有的标号必须顶格写，且无冒号

 BL     InitRamArea
 BL     RCC_CONFIG_72MHZ

; 设置RCC的APB2使能寄存器，启动 GPIOA、GPIOB和AFIO部件
 LDR    R1, =RCC_APB2ENR     ; 0X4002101C
 LDR    R2, =APB2ENALL
 STR    R2, [R1]             ; 使能GPIOA,GPIOB

; 设置RCC的APB1使能寄存器，启动定时器TIM2
 LDR    R1, =RCC_APB1ENR
 LDR    R2, =APB1ENALL         
 STR    R2, [R1]
 
; 设置 GPIOA 配置寄存器，令PA0~PA11设置为推挽输出(50MHz)，P12为推挽输出(50MHz)，P15为浮空输入
 MOV    R0, #CFGAL
 LDR    R1, =GPIOA_CRL
 STR    R0, [R1]              
 LDR    R0, =CFGAH
 LDR    R1, =GPIOA_CRH
 STR    R0, [R1]              
 
 ;设置GPIOB低配置寄存器：PB.0 下拉输入
 MOV    R0, #CFGB
 LDR    R1, =GPIOB_CRL
 STR    R0, [R1]              
 LDR    R1, =GPIOB_BSRR
 LDR    R2, =PULL0DOWN
 STR    R2, [R1]

; 设置AFIO的EXTI配置寄存器：把PB0连至EXTI0
 MOV    R0, #AFIO_EXTI0_PB
 LDR    R1, =AFIO_EXTICR1
 STR    R0, [R1] 
 
; 设置EXTI中断屏蔽寄存器：允许EXTI0中断
 MOV    R0, #1
 LDR    R1, =EXTI_IMR
 STR    R0, [R1] 
 
 ; 设置事件屏蔽寄存器：允许EXTI0事件中断
 MOV    R0, #1
 LDR    R1, =EXTI_EMR
 STR    R0, [R1] 
 
 ; 设置EXTI上升沿触发设置寄存器：EXTI0采用上升沿触发
 MOV    R0, #RTSR_EXTI0
 LDR    R1, =EXTI_RTSR
 STR    R0, [R1]
 
 ; 设置NVIC的中断设置允许寄存器(ISER)：允许EXTI0
 MOV    R0, #EXTI0_ITEN   ;第6位
 LDR    R1, =NVIC_ISER0
 STR    R0, [R1] 

 ; 设置定时器TIM2的重装载寄存器
 MOV    R0, #(10000-1)
 LDR    R1, =TIM2_ARR
 STR    R0, [R1]              

 ; 设置定时器TIM2的分频器
 MOV    R0, #(7200-1)
 LDR    R1, =TIM2_PSC
 STR    R0, [R1]              

; 设置定时器TIM2的DMA/中断允许寄存器 
 MOV    R0, #0   ;0-禁止中断 1-允许中断
 LDR    R1, =TIM2_DIER
 STR    R0, [R1]              
 
 ; 设置NVIC中断设置允许寄存器(ISER)
 LDR    R0, =ITEN
 LDR    R1, =NVIC_ISER0
 STR    R0, [R1]
   
 ;设置定时器配置寄存器:启动计数
 MOV    R0, #1
 LDR    R1, =TIM2_CR1
 STR    R0, [R1] 

 

LOOP  
  BL ShowDigits;
 B LOOP

;PA12-输出，PA15-输入
HandleSound
	PUSH {R0,R1,R4,R5,R6,R7,LR}
    LDR R5,=GPIOA_BSRR
	LDR R6,=0x10000000   ;PA12 <- 0
    STR R6,[R5]
	LDR R6,=0x1000       ;PA12 <- 1
    STR R6,[R5]
	BL  Delay
	LDR R6,=0x10000000   ;PA12 <- 0
    STR R6,[R5]
	
	
	LDR R5,=GPIOA_IDR
HSLOOP
    LDR R6,[R5]
	TST R6, #0x8000 ;PA15=0？
	BEQ HSLOOP
	
	
	LDR R5,=TIM2_CNT
	LDR R7,[R5]
	
	LDR R5,=GPIOA_IDR
HSLOOP2	
	LDR R6,[R5]
	TST R6, #0x8000 ;PA15=1？
	BNE HSLOOP2
	
	LDR R5,=TIM2_CNT
	LDR R6,[R5]
	
	SUB R6,R7
	
	MOV R5,#17
	MUL R7,R6,R5
	LDR R5, =DURATION;
	STRH R7,[R5]
	POP {R0,R1,R4,R5,R6,R7,PC}

StoreToDigitsByHex
	PUSH {R0,R1,R4,R5,R6,R7,LR}
	LDR  R5, =DURATION;
	LDRH R6,[R5]

    LDR   R5, =DIGITS;
	
	AND  R7,R6,#0x000f
	STRB R7,[R5,#0]

    LSR  R6,R6,#4
	AND  R7,R6,#0x000f
	STRB R6,[R5,#1]
	
    LSR  R6,R6,#4
	AND  R7,R6,#0x000f
	STRB R6,[R5,#2]

    LSR  R6,R6,#4
	AND  R7,R6,#0x000f
	STRB R6,[R5,#3]


	POP {R0,R1,R4,R5,R6,R7,PC}

Delay
  PUSH {R0,R1,R2,LR}
               
  MOVS R0,#0
  MOVS R1,#0
  MOVS R2,#0
                
DelayLoop0        
  ADDS R0,R0,#1

  CMP R0,#10
  BCC DelayLoop0
                
  MOVS R0,#0
  ADDS R1,R1,#1
  CMP R1,#10
  BCC DelayLoop0

  MOVS R0,#0
  MOVS R1,#0
  ADDS R2,R2,#1
  CMP R2,#15
  BCC DelayLoop0                
  POP {R0,R1,R2,PC} 
	  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;RCC  时钟配置 HCLK=72MHz=HSE*9
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
 LDR    R1,=0X40021004 ;RCC_CFGR时钟配置寄存器
 LDR    R0,[R1]
;PLL倍频系数,PCLK2,PCLK1分频设置
;HSE 9倍频PCLK2=HCLK,PCLK1=HCLK/2
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
	   
; 所有RAM(MYDATA2)中的数据必须进行初始化
InitRamArea
	PUSH {R5,R6,LR}
	
	; 初始化CURSELECT
	LDR  R5,=CURSELECT
    MOV  R6,#0
    STRB R6,[R5]   

    ; 初始化DIGITS
    LDR R5,=DIGITS	
	MOV R6,#0
    STRB R6,[R5,#3]
    STRB R6,[R5,#2]
    STRB R6,[R5,#1]
    STRB R6,[R5,#0]
	
	POP {R5,R6,PC}
	  
; 每次显示下一个数字(由CURSELECT指出)
ShowDigits
  PUSH {R4,R5,R6,R7,LR}
  
  ; 确定下一个当前要显示的数字
  LDR  R5,=CURSELECT
  LDRB R6,[R5]
  ADD  R6,#1     ; 每个数字4个字节
  CMP  R6,#4
  BNE  SGNEXT
  MOV  R6,#0  
SGNEXT
  STRB R6,[R5]  
  
  ; 取出字模
  LDR  R5,=DIGITS
  LDRB R7,[R6,R5]
  LDR  R5, =CODES  
  LDRB R7,[R5,R7]
  
  ; 形成数字控制线
  LDR  R5,=DIGITPOS 
  LDRB R4,[R5,R6] 
  LSL  R4,R4,#8  
  ADD  R7,R4
  
  ; 把数据输出到PA0~11
  LDR  R5, =GPIOA_ODR 
  STR  R7,[R5]   
  POP {R4,R5,R6,R7,PC}
		
TIM2_IRQHandler
   PUSH {R0,R1,R2,LR}

   LDR    R1, =TIM2_SR 
   MOV    R2, #0              ; 清除更新事件状态位
   STR    R2,[R1]
  
  POP {R0,R1,R2,PC}

EXTI0_IRQHandler
   PUSH {R0,R1,R2,LR}
 
	
   BL HandleSound
   BL StoreToDigitsByHex

EX
   LDR    R1, =EXTI_PR 
   MOV    R2, #1              ; 清除EXTI0的触发请求
   STR    R2,[R1]
  
   POP {R0,R1,R2,PC}

 END
	 