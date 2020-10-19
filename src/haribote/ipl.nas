; haribote-ipl
; 只能读取10个柱面

CYLS	EQU		30				; 声明CYLS=30（相当于C中的#define）

		ORG		0x7c00			; 指明程序装载地址
		; 0x00007c00 - 0x00007dff 启动区内容的装载地址 

; 一张软盘有80个柱面，2个磁头，18个扇区，一个扇区有512字节
; 所以容量为 80*2*18*512 = 1474560Byte = 1440KB

; 含有IPL的启动区位于C0-H0-S1（柱面0，磁头0，扇区1），下一个扇区为C0-H0-S2

; 0x7c00-0x7dff 启动区
; 0x8000-0x81ff 启动区
; 0x8200-0x91ff 软盘的数据

; 标准FAT12格式软盘专用的代码 Stand FAT12 format floppy code

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; 启动区的名字可以是任意的字符串（8字节）
		DW		512				; 每个扇区（sector）的大小（必须为512字节）
		DB		1				; 簇（cluster）大小（必须为1个扇区）
		DW		1				; FAT起始位置（一般为第一个扇区）
		DB		2				; FAT个数（必须为2）
		DW		224				; 根目录大小（一般为224项）
		DW		2880			; 该磁盘大小（必须为2880扇区1440*1024/512）
		DB		0xf0			; 磁盘类型（必须为0xf0）
		DW		9				; FAT的长度（必须为9扇区）
		DW		18				; 一个磁道（track）有几个扇区（必须为18）
		DW		2				; 磁头数（必须为2）
		DD		0				; 不使用分区，必须是0
		DD		2880			; 重写一次磁盘大小
		DB		0,0,0x29		; 意义不明（固定）
		DD		0xffffffff		; （可能是）卷标号码
		DB		"HARIBOTEOS "	; 磁盘的名称（必须为11字节，不足填空格）
		DB		"FAT12   "		; 磁盘格式名称（必须为8字节，不足填空格）
		RESB	18				; 先空出18字节

; 程序主体

entry:
; 初始化寄存器
		MOV		AX,0		    ; AX=0   AX累加寄存器 16位
		MOV		SS,AX			; SS=AX  SS栈段寄存器 16位
		MOV		SP,0x7c00		; SP=    SP栈基址寄存器 16位
		MOV		DS,AX			; DS=AX  DS数据段寄存器 16位

; 读取磁盘
								; 装载到内存的 0x8200-0x83ff
		MOV		AX,0x0820		; 0x8000-0x81ff 这512字节留给了启动区
		MOV		ES,AX			; ES 指定读入地址
		MOV		CH,0			; 柱面0  柱面号&0xff
		MOV		DH,0			; 磁头0  磁头号
		MOV		CL,2			; 扇区2  扇区号（0-5位）|（柱面号&0x300）>>2
		MOV		BX,18*2*CYLS-1	; 要读取的合计扇区数
		CALL	readfast		; 告诉读取

; 读取结束，运行haribote.sys
		MOV		BYTE [0x0ff0],CYLS	; 记录IPL实际读取了多少内容
		JMP		0xc200

error:
		MOV		AX,0
		MOV		ES,AX
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; 给SI加1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; 显示一个文字
		MOV		BX,15			; 指定字符颜色
		INT		0x10			; 调用显卡BIOS
		JMP		putloop
fin:
		HLT						; 让CPU停止，等待指令
		JMP		fin				; 无限循环
msg:
		DB		0x0a, 0x0a		; 换行两次
		DB		"load error"
		DB		0x0a			; 换行
		DB		0
readfast:	; 使用AL尽量一次性读取数据
;   ES：读取地址， CH：柱面， DH：磁头， CL：扇区， BX：读取扇区数
		MOV		AX,ES			; <通过ES计算AL的最大值>
		SHL		AX,3			; 将AX除以32，将结果存入AH（SHL是左移位指令）
		AND		AH,0x7f			; AH是AH除以128所得的余数（512*128=64k）
		MOV		AL,128			; AL = 128 - AH; AH是AH除以128所得的余数（512*128=64K）
		SUB		AL,AH

		MOV		AH,BL			; <通过计算BX计算AL的最大值并存入AH>
		CMP		BH,0			; if (BH != 0) { AH = 18; }
		JE		.skip1
		MOV		AH,18
.skip1:
		CMP		AL,AH			; if (AL > AH) { AL = AH; }
		JBE		.skip2
		MOV		AL,AH
.skip2:
		MOV		AH,19			; <通过CL计算AL的最大值并存入AH>
		SUB		AH,CL			; AH = 19 - CL;
		CMP		AL,AH			; if (AL > AH) { AL = AH; }
		JBE		.skip3
		MOV		AL,AH
.skip3:
		PUSH	BX
		MOV		SI,0			; 计算失败次数的寄存器
retry:
		MOV		AH,0x02			; AH=0x02 : 读盘, AH=0x03 : 写盘, AH=0x04 : 校验, AH=0x0c : 寻道
		MOV		BX,0
		MOV		DL,0x00			; A驱动器  驱动器号
		PUSH	ES
		PUSH	DX
		PUSH	CX
		PUSH	AX
		INT		0x13			; 调用磁盘BIOS 0x13中断向量指向的中断服务程序实质上就是磁盘服务程序
		JNC		next			; 没出错则跳转到fin，进位标志是0的话就跳转
		ADD		SI,1			; 往SI加1
		CMP		SI,5			; 比较SI与5
		JAE		error			; SI >= 5 跳转到error
		MOV		AH,0x00			; 系统复位：复位软盘状态，在读一次
		MOV		DL,0x00			; A驱动器  DL数据寄存器低位
		INT		0x13			; 重置驱动器
		POP		AX
		POP		CX
		POP		DX
		POP		ES
		JMP		retry
next:
		POP		AX
		POP		CX
		POP		DX
		POP		BX				; 将ES的内容存入BX
		SHR		BX,5			; 将BX由16字节为单位转化为512字节为单位
		MOV		AH,0
		ADD		BX,AX			; BX += AL;
		SHL		BX,5			; 将BX由512字节为单位转换为16字节为单位
		MOV		ES,BX			; 相当于EX += AL * 0x20
		POP		BX
		SUB		BX,AX
		JZ		.ret
		ADD		CL,AL			; 将CL加上AL
		CMP		CL,18			; 将CL与18比较
		JBE		readfast		; CL <= 18 则跳转至readfast
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readfast		; DH < 2 则跳转至readfast
		MOV		DH,0
		ADD		CH,1
		JMP		readfast
.ret:
		RET
		RESB	0x7dfe-$		; 填写0x00直到0x001fe
		DB		0x55, 0xaa
