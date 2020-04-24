#include <poyoio.h>

int main() {
    //serial_write_str("a");
    //serial_write('\n');

    for (int j=0; j < 2; j++) {
        serial_write_str("Hello");
        for (int i=0; i < 2; i++) {
            serial_write_str(" Poyo");
        }
        serial_write('\n');
    }

    while(1);

    return 0;

}
