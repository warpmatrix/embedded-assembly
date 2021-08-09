; ����Ŀʵ��led��(���İ��ϵ�PC13)��˸
BIT13      EQU 0x00002000
LED2       EQU BIT13       ;LED2--PC.13
CFGC       EQU 0x00300000  ;PC.13�� ���������50MHz
	
GPIOC      EQU 0x40011000  ;GPIOC ��ַ
GPIOC_CRL  EQU 0x40011000  ;�����üĴ���
GPIOC_CRH  EQU 0x40011004  ;�����üĴ���
GPIOC_ODR  EQU 0x4001100C  ;�����ƫ�Ƶ�ַ0Ch
GPIOC_BSRR EQU 0x40011010  ;����λ�������ƫ�Ƶ�ַ10h
GPIOC_BRR  EQU 0x40011014  ;�����ƫ�Ƶ�ַ14h
GIOPCEN    EQU 0x00000010  ;GPIOCʹ��λ
RCC_APB2ENR EQU 0x40021018

STACK_TOP EQU 0x20002000
 AREA RESET,CODE,READONLY   ; AREA���ܶ���д,�����"RESET"��XXX.sct�ļ��е�" *.o (RESET, +First)"������ͬ
 DCD STACK_TOP 				; MSP����ջָ��
 DCD START   				; ��λ��PC��ʼֵ 
 ENTRY         				; ָʾ��ʼִ��,����C�ļ���ENTRYע�͵�
START                      	; ���еı�ű��붥��д������ð��
 LDR    R1, =RCC_APB2ENR    ; 0x40021018
 LDR    R0, [R1]
 LDR    R2, =GIOPCEN         
 ORR    R0, R2
 STR    R0, [R1]             ; ʹ��GPIOCʱ��
 
;LED13--PC.13  ���������50MHz  0011 ��CNF��MODE��
 MOV    R0, #CFGC
 LDR    R1, =GPIOC_CRH
 STR    R0, [R1]              
 NOP
 NOP
LOOP5
 LDR    R1, =GPIOC_ODR 
 LDR    R2, =LED2            ;��PC.13����ߵ�ƽ
 STR    R2, [R1]
 BL Delay
 LDR    R2, =0x0             ;��PC.13����͵�ƽ
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