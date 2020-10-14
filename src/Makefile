OBJS_BOOTPACK = bootpack.obj naskfunc.obj hankaku.obj graphic.obj dsctbl.obj \
		int.obj fifo.obj keyboard.obj mouse.obj memory.obj sheet.obj timer.obj \
		mtask.obj window.obj console.obj file.obj

TOOLPATH = ../z_tools/
INCPATH  = ../z_tools/haribote/

MAKE     = $(TOOLPATH)make.exe -r
NASK     = $(TOOLPATH)nask.exe
CC1      = $(TOOLPATH)cc1.exe -I$(INCPATH) -Os -Wall -quiet
GAS2NASK = $(TOOLPATH)gas2nask.exe -a
OBJ2BIM  = $(TOOLPATH)obj2bim.exe
MAKEFONT = $(TOOLPATH)makefont.exe
BIN2OBJ  = $(TOOLPATH)bin2obj.exe
BIM2HRB  = $(TOOLPATH)bim2hrb.exe
RULEFILE = $(TOOLPATH)haribote/haribote.rul
EDIMG    = $(TOOLPATH)edimg.exe
IMGTOL   = $(TOOLPATH)imgtol.com
COPY     = copy
DEL      = del

default :
	$(MAKE) img

ipl.bin : ipl.nas
	$(NASK) ipl.nas ipl.bin ipl.lst

asmhead.bin : asmhead.nas
	$(NASK) asmhead.nas asmhead.bin asmhead.lst

hankaku.bin : hankaku.txt
	$(MAKEFONT) hankaku.txt hankaku.bin

hankaku.obj : hankaku.bin
	$(BIN2OBJ) hankaku.bin hankaku.obj _hankaku

bootpack.bim : $(OBJS_BOOTPACK)
	$(OBJ2BIM) @$(RULEFILE) out:bootpack.bim stack:3136k map:bootpack.map \
		$(OBJS_BOOTPACK)
# 3MB+64KB=3136KB

bootpack.hrb : bootpack.bim
	$(BIM2HRB) bootpack.bim bootpack.hrb 0

haribote.sys : asmhead.bin bootpack.hrb
	copy /B asmhead.bin+bootpack.hrb haribote.sys

hello.hrb : hello.nas
	$(NASK) hello.nas hello.hrb hello.lst

hello2.hrb : hello2.nas
	$(NASK) hello2.nas hello2.hrb hello2.lst

a.bim : a.obj a_nask.obj
	$(OBJ2BIM) @$(RULEFILE) out:a.bim map:a.map a.obj a_nask.obj

a.hrb : a.bim
	$(BIM2HRB) a.bim a.hrb 0

hello3.bim : hello3.obj a_nask.obj
	$(OBJ2BIM) @$(RULEFILE) out:hello3.bim map:hello3.map hello3.obj a_nask.obj

hello3.hrb : hello3.bim
	$(BIM2HRB) hello3.bim hello3.hrb 0

hello4.bim : hello4.obj a_nask.obj
	$(OBJ2BIM) @$(RULEFILE) out:hello4.bim stack:1k map:hello4.map \
		hello4.obj a_nask.obj

hello4.hrb : hello4.bim
	$(BIM2HRB) hello4.bim hello4.hrb 0

hello5.bim : hello5.obj
	$(OBJ2BIM) @$(RULEFILE) out:hello5.bim stack:1k map:hello5.map hello5.obj

hello5.hrb : hello5.bim
	$(BIM2HRB) hello5.bim hello5.hrb 0

winhelo.bim : winhelo.obj a_nask.obj
	$(OBJ2BIM) @$(RULEFILE) out:winhelo.bim stack:1k map:winhelo.map \
		winhelo.obj a_nask.obj

winhelo.hrb : winhelo.bim
	$(BIM2HRB) winhelo.bim winhelo.hrb 0

winhelo2.bim : winhelo2.obj a_nask.obj
	$(OBJ2BIM) @$(RULEFILE) out:winhelo2.bim stack:1k map:winhelo2.map \
		winhelo2.obj a_nask.obj

winhelo2.hrb : winhelo2.bim
	$(BIM2HRB) winhelo2.bim winhelo2.hrb 0

winhelo3.bim : winhelo3.obj a_nask.obj
	$(OBJ2BIM) @$(RULEFILE) out:winhelo3.bim stack:1k map:winhelo3.map \
		winhelo3.obj a_nask.obj

winhelo3.hrb : winhelo3.bim
	$(BIM2HRB) winhelo3.bim winhelo3.hrb 40k
haribote.img : ipl.bin haribote.sys \
		hello.hrb hello2.hrb a.hrb hello3.hrb hello4.hrb hello5.hrb \
		winhelo.hrb winhelo2.hrb winhelo3.hrb
	$(EDIMG)   imgin:../z_tools/fdimg0at.tek \
		wbinimg src:ipl.bin len:512 from:0 to:0 \
		copy from:haribote.sys to:@: \
		copy from:ipl.nas to:@: \
		copy from:make.bat to:@: \
		copy from:hello.hrb to:@: \
		copy from:hello2.hrb to:@: \
		copy from:a.hrb to:@: \
		copy from:hello3.hrb to:@: \
		copy from:hello4.hrb to:@: \
		copy from:hello5.hrb to:@: \
		copy from:winhelo.hrb to:@: \
		copy from:winhelo2.hrb to:@: \
		copy from:winhelo3.hrb to:@: \
		imgout:haribote.img

%.gas : %.c bootpack.h
	$(CC1) -o $*.gas $*.c

%.nas : %.gas
	$(GAS2NASK) $*.gas $*.nas

%.obj : %.nas
	$(NASK) $*.nas $*.obj $*.lst

img :
	$(MAKE) haribote.img

run :
	$(MAKE) img
	$(COPY) haribote.img ..\z_tools\qemu\fdimage0.bin
	$(MAKE) -C ../z_tools/qemu

install :
	$(MAKE) img
	$(IMGTOL) w a: haribote.img

clean :
	-$(DEL) *.bin
	-$(DEL) *.lst
	-$(DEL) *.obj
	-$(DEL) *.map
	-$(DEL) *.bim
	-$(DEL) *.hrb
	-$(DEL) haribote.sys

src_only :
	$(MAKE) clean
	-$(DEL) haribote.img
