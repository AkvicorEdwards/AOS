void io_hlt(void);
void io_cli(void);
void io_out8(int port, int data);
int io_load_eflags(void);
void io_store_eflags(int eflags);
void init_palette(void);
void set_palette(int start, int end, unsigned char *rgb);
void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1);
void init_screen(char *vram, int x, int y);
void putfont8(char *vram, int xsize, int x, int y, char c, char *font);

#define COL8_000000		0
#define COL8_FF0000		1
#define COL8_00FF00		2
#define COL8_FFFF00		3
#define COL8_0000FF		4
#define COL8_FF00FF		5
#define COL8_00FFFF		6
#define COL8_FFFFFF		7
#define COL8_C6C6C6		8
#define COL8_840000		9
#define COL8_008400		10
#define COL8_848400		11
#define COL8_000084		12
#define COL8_840084		13
#define COL8_008484		14
#define COL8_848484		15

struct BOOTINFO {
	char cyls, leds, vmode, reserve;
	short scrnx, scrny;
	char *vram;
};

void HariMain(void) {
	struct BOOTINFO *binfo = (struct BOOTINFO *) 0x0ff0;
    static char font_A[16] = {
		0x00, 0x18, 0x18, 0x18, 0x18, 0x24, 0x24, 0x24,
		0x24, 0x7e, 0x42, 0x42, 0x42, 0xe7, 0x00, 0x00
	};

	init_palette();
	init_screen(binfo->vram, binfo->scrnx, binfo->scrny);
    putfont8(binfo->vram, binfo->scrnx, 10, 10, COL8_FFFFFF, font_A);
    
    for (;;) {
        io_hlt();
    }
}

void init_palette(void) {
    static unsigned char table_rgb[16 * 3] = {
            0x00, 0x00, 0x00,    //  0:黑
            0xff, 0x00, 0x00,    //  1:亮红
            0x00, 0xff, 0x00,    //  2:亮绿
            0xff, 0xff, 0x00,    //  3:亮黄
            0x00, 0x00, 0xff,    //  4:亮蓝
            0xff, 0x00, 0xff,    //  5:亮紫
            0x00, 0xff, 0xff,    //  6:浅亮蓝
            0xff, 0xff, 0xff,    //  7:白
            0xc6, 0xc6, 0xc6,    //  8:亮灰
            0x84, 0x00, 0x00,    //  9:暗红
            0x00, 0x84, 0x00,    // 10:暗绿
            0x84, 0x84, 0x00,    // 11:暗黄
            0x00, 0x00, 0x84,    // 12:暗青
            0x84, 0x00, 0x84,    // 13:暗紫
            0x00, 0x84, 0x84,    // 14:浅暗蓝
            0x84, 0x84, 0x84     // 15:暗灰
    };
    set_palette(0, 15, table_rgb);
    return;

    // static char 只能用于数据，相当于汇编中的DB指令
}

// 256色同屏，每个点只有0-255的调色板索引，具体什么颜色
// 需要查找一个256*3=768字节的调色板（每个索引3个字节RGB）
// 设置一个颜色的调色盘需要向向 0x03c8 写入颜色编号
// 接着在 0x03c9 端口依次写入R、G、B三个分量的具体数值
void set_palette(int start, int end, unsigned char *rgb) {
    int i, eflags;
    eflags = io_load_eflags();    // 记录中断许可标志位
    io_cli();                    // 将中断许可标志置为0，禁止中断
    io_out8(0x03c8, start);
    for (i = start; i <= end; i++) {
        io_out8(0x03c9, rgb[0] / 4);
        io_out8(0x03c9, rgb[1] / 4);
        io_out8(0x03c9, rgb[2] / 4);
        rgb += 3;
    }
    io_store_eflags(eflags);    // 复原中断许可标志
    return;
}

// 绘制实心矩形
void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1) {
	int x, y;
	for (y = y0; y <= y1; y++) {
		for (x = x0; x <= x1; x++)
			vram[y * xsize + x] = c;
	}
	return;
}

void init_screen(char *vram, int x, int y) {
    // 设置底色 浅暗蓝
	boxfill8(vram, x, COL8_008484,  0,     0,      x -  1, y - 29);
    // 设置1像素高度的线 亮灰
    boxfill8(vram, x, COL8_C6C6C6,  0,     y - 28, x -  1, y - 28);
	// 设置1像素高度的线 白
    boxfill8(vram, x, COL8_FFFFFF,  0,     y - 27, x -  1, y - 27);
    // 设置底部 task bar 亮灰
	boxfill8(vram, x, COL8_C6C6C6,  0,     y - 26, x -  1, y -  1);
    
    // 绘制左下按钮的顶部线条 白
	boxfill8(vram, x, COL8_FFFFFF,  3,     y - 24, 59,     y - 24);
	// 绘制坐下按钮的左侧线条 白
    boxfill8(vram, x, COL8_FFFFFF,  2,     y - 24,  2,     y -  4);
	// 绘制左下按钮的底部线条 暗灰
    boxfill8(vram, x, COL8_848484,  3,     y -  4, 59,     y -  4);
	// 绘制左下按钮的右侧线条 暗灰
    boxfill8(vram, x, COL8_848484, 59,     y - 23, 59,     y -  5);
	// 绘制左下按钮的底部线条 黑
    boxfill8(vram, x, COL8_000000,  2,     y -  3, 59,     y -  3);
	// 绘制左下按钮的右侧线条 黑
    boxfill8(vram, x, COL8_000000,  2,     y -  3, 59,     y -  3);

    // 绘制右下按钮的顶部线条 暗灰
	boxfill8(vram, x, COL8_848484, x - 47, y - 24, x -  4, y - 24);
    // 绘制右下按钮的左侧线条 暗灰
	boxfill8(vram, x, COL8_848484, x - 47, y - 23, x - 47, y -  4);
	// 绘制右下按钮的底部线条 白
    boxfill8(vram, x, COL8_FFFFFF, x - 47, y -  3, x -  4, y -  3);
	// 绘制右下按钮的右侧线条 白
    boxfill8(vram, x, COL8_FFFFFF, x -  3, y - 24, x -  3, y -  3);
    return;
}

void putfont8(char *vram, int xsize, int x, int y, char c, char *font) {
	int i;
	char *p, d /* data */;
	for (i = 0; i < 16; i++) {
		p = vram + (y + i) * xsize + x;
		d = font[i];
		if ((d & 0x80) != 0) { p[0] = c; }
		if ((d & 0x40) != 0) { p[1] = c; }
		if ((d & 0x20) != 0) { p[2] = c; }
		if ((d & 0x10) != 0) { p[3] = c; }
		if ((d & 0x08) != 0) { p[4] = c; }
		if ((d & 0x04) != 0) { p[5] = c; }
		if ((d & 0x02) != 0) { p[6] = c; }
		if ((d & 0x01) != 0) { p[7] = c; }
	}
	return;
}