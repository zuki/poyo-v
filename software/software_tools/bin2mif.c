#include    <stdlib.h>
#include    <stdio.h>
#include    <string.h>

#define ROM_DEPTH 4096             // ROM Depth
#define ROM_SIZE  ROM_DEPTH * 4    // ROMサイズ
#define RAM_DEPTH 4096             // RAM Depth
#define RAM_SIZE  RAM_DEPTH * 4    // RAMサイズ

void write_file(FILE *fpr, char *file, int depth, int unit, int size) {
    FILE    *fpw;
    char    buf[256];
    int     c;

    sprintf(buf, "%s.mif", file);
    fpw = fopen(buf, "w");

    fprintf(fpw, "DEPTH = %d;\n", depth);
    fprintf(fpw, "WIDTH = %d;\n", 8 * unit);
    fprintf(fpw, "ADDRESS_RADIX = HEX;\n");
    fprintf(fpw, "DATA_RADIX = HEX;\n");
    fprintf(fpw, "CONTENT\n");
    fprintf(fpw, "BEGIN\n");

    if (size == 0) {
        fprintf(fpw, "%04x : ", 0);
        fprintf(fpw, "%08x;\n", 0);
    } else {
        int pc = 0;
        while ( pc < size ) {
            fprintf(fpw, "%04x : ", pc );
            fread(&c, unit, 1, fpr);
            switch(unit){
                case 1:        fprintf(fpw, "%02x;\n", c); break;
                case 2:        fprintf(fpw, "%04x;\n", c); break;
                case 4:        fprintf(fpw, "%08x;\n", c); break;
            }
            ++pc;
        }
    }

    fprintf(fpw, "END;\n");
    fclose(fpw);

}

int main(int argc, char *argv[]) {

    FILE    *fpr;
    char    buf[256], file[256];
    int     i, c, pc, unit, size, csize, dsize;

    if ( argc == 1 ) {
        fprintf( stderr, "usage: %s [-2|-4] <filename>\n", argv[0] );
        exit(-1);
    }

    if ( !strcmp( argv[1] , "-4" ) ) {
        unit = 4;
        strcpy( file, argv[ 2 ] );
    } else if ( !strcmp( argv[1] , "-2" ) ) {
        unit = 2;
        strcpy( file, argv[ 2 ] );
    } else {
        unit = 1;
        strcpy( file, argv[ 1 ] );
    }

    sprintf(buf, "%s.bin", file );
    fpr = fopen(buf, "r" );
    fseek(fpr, 0L, SEEK_END);
    size = ftell(fpr);
    fseek(fpr, 0L, SEEK_SET);

    if (size > ROM_SIZE) {
        csize = ROM_SIZE / unit;
        dsize = ((size - ROM_SIZE) / unit) + 1;
    } else {
        csize = (size / unit) + 1;
        dsize = 0;
    }
    printf("cize: %d, csize: %d, dsize: %d\n", size, csize, dsize);
    write_file(fpr, "code", ROM_DEPTH, unit, csize);
    if (dsize > 0)
        fseek(fpr, ROM_SIZE, SEEK_SET);
    write_file(fpr, "data", RAM_DEPTH, unit, dsize);

    fclose(fpr);
}
