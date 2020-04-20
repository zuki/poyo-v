#include <poyoio.h>

void utest(char *exp, int expected, int actual) {
  serial_write_str(exp);
  if (expected == actual) {
    serial_write_str("ok\n");
  } else {
    serial_write_str("bad: expected ");
    serial_write_int(expected);
    serial_write_str(", but get ");
    serial_write_int(actual);
    serial_write_str("\n");
  }
}

int main(void) {
  int x, y, z, t, i;
  char c;

  x = 20;
  y = 10;
  z = 3;

  t = (x - y) * z;
  utest("(20-10)*3\n", 30, t);


  t = (y - x) * z;
  utest("(10-20)*3\n", -30, t);

  t = (x - y) / z;
  utest("(20-10)/3\n", 3, t);

  t = (x - y) % z;
  utest("(20-10)%3\n", 1, t);

  t = (y - x) / z;
  utest("((10-20)/3\n", -3, t);

  t = (y - x) % z;
  utest("(10-20)%3\n", -1, t);

  while(1);

  return 0;
}
