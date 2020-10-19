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

readloop:
								; SI 原变址寄存器
		MOV		SI,0			; 记录失败次数寄存器

retry:
								; AX 高8位为AH 低8位为AL
								; AH 累加寄存器高位
		MOV		AH,0x02			; AH=0x02 : 读盘
								; AH=0x03 : 写盘
								; AH=0x04 : 校验
								; AH=0x0c : 寻道

		MOV		AL,1			; 1个扇区 AL=处理对象的扇区数
								; （只能同时处理连续的扇区）

		MOV		BX,0			; BX 基址寄存器
		MOV		DL,0x00			; A驱动器  驱动器号
		INT		0x13			; 调用磁盘BIOS 0x13中断向量指向的中断服务程序实质上就是磁盘服务程序

								; FLAGS.CF==0 没有错误，AH=0
								; FLAGS.CF==1 有错误，AH=错误号码（与重置（reset）功能一样）
		JNC		next			; 没出错则跳转到fin
								; 进位标志是0的话就跳转

		ADD		SI,1			; 往SI加1
		CMP		SI,5			; 比较SI与5
		JAE		error			; SI >= 5 跳转到error

		MOV		AH,0x00			; 系统复位：复位软盘状态，在读一次
		MOV		DL,0x00			; A驱动器  DL数据寄存器低位
		INT		0x13			; 重置驱动器

		JMP		retry
next:
								; EX 附加段寄存器
								; 把内存地址后移0x200（512/16十六进制转换）
								; ADD ES,0x020因为没有ADD ES，只能通过AX进行
		MOV		AX,ES			; 先将ES存入累加寄存器
		ADD		AX,0x0020		; 累加寄存器+0x0020（=512/16）
		MOV		ES,AX			; 将结果存入ES

								; MOV AL,[ES:BX] 代表 ES*16+BX 的内存地址
								; AL 累加寄存器低位
								; 可以省略默认的段寄存器DS，即 MOV AL,[DS:SI] == MOV AL,[SI]
								; 因此，DS必须预先置0，否则地址的值就会加上DS*16
								
								; 读下一个扇区
		ADD		CL,1			; 往CL里面加1
		CMP		CL,18			; 比较CL与18
		JBE		readloop		; CL <= 18 跳转到readloop

								; 扇区置1，更换磁头2
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readloop		; DH < 2 跳转到readloop

								; 更换柱面
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS
		JB		readloop		; CH < CYLS 跳转到readloop

; 读取完毕，跳转到haribote.sys执行！
; 用二进制编辑器打开img可知
; 文件名写在 0x002600 以后的地方
; 文件的内容会写在 0x004200 以后的地方
; 因为磁盘的内容装载在内存的0x8000号地址，那么0x4200就在内存的0x8000+0x4200=0xc200号地址
		MOV		[0x0ff0],CH		; IPL跳转到asmbead.nas
		JMP		0xc200

error:
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

		RESB	0x7dfe-$		; 填写0x00直到0x001fe

		DB		0x55, 0xaa