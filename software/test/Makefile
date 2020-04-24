#
# Makefile for c code
#

# 共通初期設定ファイルをインクルード
include ../software_tools/Makefile.inc

# C言語ソースコードファイルを指定
SRC = main.c

SRCS = $(SRC) $(INCLUDE_ROOT)/poyoio.c
OBJS = $(SRCS:.c=.o)

all: code.mif

# オブジェクトファイル生成
%.o: %.c Makefile
	$(CC) $(CFLAGS) -o $@ -c $<

# 下記はアセンブリコードを入力する場合の例
#%.o: %.s Makefile
#	$(CC) $(CFLAGS) -o $@ -c $<

# ELFファイル生成
app.elf: $(OBJS) $(CRTOBJ) Makefile
	$(LD) $(CRTOBJ) $(OBJS) $(LIBC) $(LIBGCC) -T$(LDSCRIPT) $(LDFLAGS) -o app.elf

# バイナリファイル生成
app.bin: app.elf
	$(OBJDUMP) -D $< > app.dump
	$(OBJCOPY) -O binary $< $@

# バイナリファイルから.hex形式ファイルを生成
app.hex: app.bin
	hexdump -v -e '1/4 "%08x" "\n"' $< > app_im.hex
	cp app_im.hex $@
	rm -f app_im.hex

code.mif: app.bin
	$(MIF_CONVERTER) -4 app
	mv code.mif $(FPGA_PROJECT_PATH)/apps/code.mif
	mv data.mif $(FPGA_PROJECT_PATH)/apps/data.mif

# .hex形式ファイルを命令メモリ用ファイルとデータメモリ用ファイルへと分割
code.hex data.hex: app.hex
	$(HEX_CONVERTER) $<

# update the memory files inside the FPGA bitfile
update-mem: all
	cd ${FPGA_PROJECT_PATH} && quartus_cdb ${FPGA_PROJECT} -c ${FPGA_PROJECT_REVISION} --update_mif
	cd ${FPGA_PROJECT_PATH} && quartus_asm --read_settings_files=on --write_settings_files=off ${FPGA_PROJECT} -c ${FPGA_PROJECT_REVISION}

# download the bitfile to your board
download:
	cd ${FPGA_PROJECT_PATH} && quartus_pgm -c "Arrow-USB-Blaster [USB0]" -m jtag -o P\;output_files/${FPGA_PROJECT_REVISION}.sof@1

.PHONY: clean
clean:
	rm $(OBJS) code.hex data.hex data0.hex data1.hex data2.hex data3.hex app.hex app.dump app.bin app.elf crt0.o -f
