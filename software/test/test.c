#include <poyoio.h>


int main() {
    for (int j=0; j < 2; j++) {

        serial_write_str("Hello");

        for (int i=0; i < 2; i++) {
            serial_write_str("Poyo");
        }
        serial_write('\n');

        delay(3000);

    }

    return 0;

}
