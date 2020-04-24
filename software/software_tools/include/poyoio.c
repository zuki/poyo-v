#include <poyoio.h>


void digital_write(int pin, int vol) {

    volatile char* output_addr = GPO_WRADDR;
    volatile int* input_addr = GPO_RDADDR;

    // 0ビット目は0ピンの状態、1ビット目は1ピンの状態というように値を格納しているので、
    // ピンの値に応じたビットのみを変更する
    if (vol == 1) {
        *output_addr = (*input_addr | (1 << pin));
    } else if (vol == 0) {
        *output_addr = (*input_addr & ~(1 << pin));
    }
}


int digital_read(int pin) {

    volatile int* input_addr = GPI_ADDR;
    int vol;

    // 0ビット目は0ピンの状態、1ビット目は1ピンの状態というように値を格納しているので、
    // ピンの値に応じて特定ビットを読み出す
    vol = (*input_addr >> pin) & 1;

    return vol;
}


void serial_write(char c) {

    volatile char* output_addr = UART_TX_ADDR;

    delay(UART_TX_DELAY_TIME);
    *output_addr = c;
}

void serial_write_len(char *s) {
  int l = 0;
  while(*s++)
    l += 1;
  serial_write_int(l);
}

void serial_write_str(char *s) {
    while(*s) {
      serial_write(*s++);
    }
}

void serial_write_int(int n) {
    int i;
    char c;

    for (i = 28; i >= 0; i -= 4) {
        c = ((n >> i) & 0x0f);
        if (c >= 10) {
            // ASCIIコードのA-F
            c = c - 10 + 'A';
        } else {
            // ASCIIコードの0-9
            c += '0';
        }
        serial_write(c);
    }
}


char serial_read() {

    volatile int* input_addr = UART_RX_ADDR;
    char c;

    c = *input_addr;

    return c;
}


void delay(unsigned int time) {

    volatile unsigned int* input_addr = HARDWARE_COUNTER_ADDR;
    unsigned int start_cycle = *input_addr;

    while (time > 0) {
        while ((*input_addr - start_cycle) >= HARDWARE_COUNT_FOR_ONE_MSEC) {
            time--;
            start_cycle += HARDWARE_COUNT_FOR_ONE_MSEC;
        }
        if (*input_addr < start_cycle) {
            start_cycle = *input_addr;
        }
    }
}
