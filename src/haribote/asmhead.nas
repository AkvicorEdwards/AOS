; haribote-os boot asm
; TAB=4

[INSTRSET "i486p"]                ; 说明使用486指令
                                  ; 为了使用LGDT、EAX、CR0等关键字

VBEMODE	EQU	0x105		; 1024 x  768 x 8bit 彩色
; 显示模式
;	0x100 :  640 x  400 x 8bit 彩色
;	0x101 :  640 x  480 x 8bit 彩色
;	0x103 :  800 x  600 x 8bit 彩色
;	0x105 : 1024 x  768 x 8bit 彩色
;	0x107 : 1280 x 1024 x 8bit 彩色

BOTPAK     EQU        0x00280000        ; 加载bootpack
DSKCAC     EQU        0x00100000        ; 磁盘缓存的位置
DSKCAC0    EQU        0x00008000        ; 磁盘缓存的位置（实模式）

; BOOT_INFO相关
CYLS    EQU        0x0ff0               ; 引导扇区设置
LEDS    EQU        0x0ff1
VMODE   EQU        0x0ff2               ; 关于颜色的信息。颜色的位数
SCRNX   EQU        0x0ff4               ; 分辨率X
SCRNY   EQU        0x0ff6               ; 分辨率Y
VRAM    EQU        0x0ff8               ; 图像缓冲区的起始地址

        ORG        0xc200               ;  这个的程序要被装载的内存地址
                                        ;（由二进制编辑器打开镜像文件可知）

; 确认VBE是否存在

        MOV	AX,0x9000
        MOV	ES,AX
        MOV	DI,0
        MOV	AX,0x4f00
        INT	0x10
	CMP	AX,0x004f
	JNE	scrn320

; 检查VBE的版本

	MOV	AX,[ES:DI+4]
	CMP	AX,0x0200
	JB	scrn320		; if (AX < 0x0200) goto scrn320

; 取得画面模式信息

	MOV	CX,VBEMODE
	MOV	AX,0x4f01
	INT	0x10
	CMP	AX,0x004f
	JNE	scrn320

; 画面模式信息的确认

	CMP	BYTE [ES:DI+0x19],8 ;颜色数 必须为8
	JNE	scrn320
	CMP	BYTE [ES:DI+0x1b],4 ;颜色的指定方法 必须为4(4是调色板模式)
	JNE	scrn320
	MOV	AX,[ES:DI+0x00] ;模式属性 bit7不是1就不能加上0x4000
	AND	AX,0x0080
	JZ	scrn320        ; 模式属性的bit7是0，所以放弃

;	画面设置

	MOV	BX,VBEMODE+0x4000
	MOV	AX,0x4f02
	INT	0x10
	MOV	BYTE [VMODE],8	; 屏幕的模式（参考C语言的引用）
	MOV	AX,[ES:DI+0x12] ; X的分辨率
	MOV	[SCRNX],AX
	MOV	AX,[ES:DI+0x14] ; Y的分辨率
	MOV	[SCRNY],AX
	MOV	EAX,[ES:DI+0x28] ; VRAM的地址
	MOV	[VRAM],EAX
	JMP	keystatus

scrn320:
	MOV	AL,0x13	; VGA图、320x200x8bit彩色
	MOV	AH,0x00
	INT	0x10
	MOV	BYTE [VMODE],8	; 记下画面模式（参考C语言）
	MOV	WORD [SCRNX],320
	MOV	WORD [SCRNY],200
	MOV	DWORD [VRAM],0x000a0000

;	通过 BIOS 获取指示灯状态

keystatus:

        MOV        AH,0x02
        INT        0x16             ; keyboard BIOS
        MOV        [LEDS],AL

; PIC关闭一切中断
; 根据AT兼容机的规范，如果要初始化PIC，
; 必须在CLI之前进行，否则有时会挂起。
; 随后进行PIC的初始化。
        MOV        AL,0xff
        OUT        0x21,AL
        NOP                        ; 如果连续执行OUT指令，有些机种会无法正常运行
        OUT        0xa1,AL

        CLI                        ; 禁止CPU级别的中断

; 让CPU支持1M以上内存、设置A20GATE

        CALL       waitkbdout
        MOV        AL,0xd1
        OUT        0x64,AL
        CALL       waitkbdout
        MOV        AL,0xdf            ; enable A20
        OUT        0x60,AL
        CALL       waitkbdout

; 切换到保护模式

[INSTRSET "i486p"]				; 说明使用486指令

        LGDT       [GDTR0]            ; 设置临时GDT
        MOV        EAX,CR0
        AND        EAX,0x7fffffff    ; 设置bit31为0（为了禁止分页）
        OR         EAX,0x00000001    ; 设置bit0为1（为了切换到保护模式）
        MOV        CR0,EAX
        JMP        pipelineflush
pipelineflush:
        MOV        AX,1*8            ;  可读写的段 32bit
        MOV        DS,AX
        MOV        ES,AX
        MOV        FS,AX
        MOV        GS,AX
        MOV        SS,AX

; bootpack传递

        MOV        ESI,bootpack      ; 转送源
        MOV        EDI,BOTPAK        ; 转送目的地
        MOV        ECX,512*1024/4
        CALL       memcpy

; 磁盘数据最后转送到它本来的位置去

; 首先从启动扇区开始

        MOV        ESI,0x7c00        ; 转送源
        MOV        EDI,DSKCAC        ; 转送目的地
        MOV        ECX,512/4
        CALL       memcpy

; 剩余的全部

        MOV        ESI,DSKCAC0+512    ; 转送源
        MOV        EDI,DSKCAC+512     ; 转送目的地
        MOV        ECX,0
        MOV        CL,BYTE [CYLS]
        IMUL       ECX,512*18*2/4    ; 从柱面数变换为字节数/4
        SUB        ECX,512/4         ; 减去IPL
        CALL       memcpy

; 必须由asmhead来完成的工作，至此全部完成
; 以后就交由bootpack来完成

; bootpack启动

        MOV        EBX,BOTPAK
        MOV        ECX,[EBX+16]
        ADD        ECX,3           ; ECX += 3;
        SHR        ECX,2           ; ECX /= 4;
        JZ         skip            ; 没有要转送的东西时
        MOV        ESI,[EBX+20]    ; 转送源
        ADD        ESI,EBX
        MOV        EDI,[EBX+12]    ; 转送目的地
        CALL       memcpy
skip:
        MOV        ESP,[EBX+12]    ; 栈初始值
        JMP        DWORD 2*8:0x0000001b

waitkbdout:
        IN         AL,0x64
        AND        AL,0x02
	IN	   AL,0x60 		; から読み(受信バッファが悪さをしないように)
        JNZ        waitkbdout        ; AND结果不为0跳转到waitkbdout
        RET

memcpy:
        MOV        EAX,[ESI]
        ADD        ESI,4
        MOV        [EDI],EAX
        ADD        EDI,4
        SUB        ECX,1
        JNZ        memcpy            ; 减法运算的结果如果不为0,跳转到memcpy
        RET
; memcpy地址前缀大小

        ALIGNB    16    ; 一直添加DBO,直到时机合适的时候(地址能被16整除)为止
                        ; 如果GDT0的地址不是8的整数倍,向段寄存器复制的MOV指令就会慢一些
GDT0:
        RESB      8                ; NULL selector
        DW        0xffff,0x0000,0x9200,0x00cf    ; 可以读写的段(segment) 32bit
        DW        0xffff,0x0000,0x9a28,0x0047    ; 可以执行的段(segment) 32bit （bootpack用）

        DW        0
GDTR0:
        DW        8*3-1
        DD        GDT0

        ALIGNB    16
bootpack:
