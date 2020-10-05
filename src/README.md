```sh
DB # defien byte 定义字节类型变量，一个字节数据占1个字节单元，读完一个，偏移量加1
DW # define word "16位 2byte" 定义字类型变量，一个字数据占2个字节单元，读完一个，偏移量加2
DD # define double-word "32位 4byte" 定义双字类型变量，一个双字数据占4个字节单元，读完一个，偏移量加4

RESB # Reserve byte

ORG # origin 程序要用此地址开始，也就是把程序装载到内存中的指定地址。
JMP # jump 相当于C中的goto语句
MOV # move 赋值 `MOV AX,0` 相当于 `AX=0`
ADD # 加法 `ADD SI,1`就是C语言中的`SI=SI+1`
CMP # compare 比较 `CMP AL,0` 将AL中的值与0比较
JE # 条件跳转指令之一，如果比较结果相等，跳转到指定的地址。如果不等，则不调转，继续执行下一条指令
JC # jump if carry 如果进位标志(carry flag)是1的话，就跳转
JNC # jump if not carry 进位标志是0的话就跳转
JAE # 大于或等于时跳转
JBE # jump if below or equal 小于等于则跳转
JB # jump if below 如果小于的话，就跳转
EQU # equal 相当于C中的#define命令，用来声明常数
```

```
BYTE 8
WORD 16
DWARD 32
```
  
```sh
# 16位寄存器，可以存储16位的二进制数
# X 代表 extend

AX - accumulator, 累加寄存器
CX - counter, 计数寄存器
DX - data, 数据寄存器
BX - base, 基址寄存器
SP - stack pointer, 栈指针寄存器
BP - base pointer, 基址指针寄存器
SI - source index,源变址寄存器
DI - destination index, 目的变址寄存器

# 段寄存器 segment register （16位寄存器）
ES - 附加段寄存器 extra segment
CS - 代码段寄存器 code segment
SS - 栈段寄存器 stack segment
DS - 数据段寄存器 data segment
FS - 没有名称 segment part 2
GS - 没有名称 segment part 3


# 8 位寄存器
# AX寄存器共有16位，0-7的低8位称为AL
#                 8-15的高8位称为AH
AL - accumulator low 累加寄存器低位
CL - counter low 计数寄存器低位
DL - data low 数据寄存器低位
BL - base low 基址寄存器低位
AH - accumulator high 累加寄存器高位
CH - counter high 计数寄存器高位
DH - data high 数据寄存器高位
BH - base high 基址寄存器高位


# 32位寄存器
# 16位寄存器名字前加E
EAX
ECX
EDX
EBX
ESP
EBP
ESI
EDI
```
