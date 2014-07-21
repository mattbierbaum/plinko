#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/types.h>
#include "plinkolib.h"

int main(int argc, char **argv){
    if (argc != 2){
        printf("Incorrect arguments supplied, must be <filename>\n");
        return 1;
    }

    ran_seed(123123);
    double R = 0.75/2;
    double damp = 1.0;
    double wall = 7;
    char filename[1024];
    strcpy(filename, argv[1]);

    char file_track[1024];
    char file_pegs[1024];
    char file_conf[1024];
    sprintf(file_track, "%s.track", filename);
    sprintf(file_pegs, "%s.pegs", filename);
    sprintf(file_conf, "%s.conf", filename);

    int TIMEPOINTS = 1 << 25;
    int MAXPEGS = 1 << 10;
    int npegs = 0;
    double *pegs = malloc(sizeof(double)*2*MAXPEGS);
    double *bounces = malloc(sizeof(double)*2*TIMEPOINTS);
    t_result *res = malloc(sizeof(t_result));

    double pos[2] = { wall / 2 - 0.213, 10.0 };
    double vel[2] = { 0, 1e-4};

    FILE *file = fopen(file_conf, "w");
    fprintf(file, "radius: %f\n", R);
    fprintf(file, "damp: %f\n", damp);
    fprintf(file, "wall: %f\n", wall);
    fclose(file);

    build_hex_grid(pegs, &npegs, MAXPEGS, 4, 8);

    int prints=0;
    for (int i=0; i<TIMEPOINTS; i++){
        pos[0] = wall/2 - 0.5 + ran_ran2();
        pos[1] = 10.0;
        if (i%10000 == 0){
            FILE *tfile = fopen(file_track, "wb");
            fwrite(bounces, sizeof(double), i, tfile);
            fclose(tfile);
            printf("%i\n", i);
        }
        trackCollision(pos, vel, R, wall, damp, pegs, npegs, res);
        bounces[i] = res->nbounces;
        if ((int)bounces[i] % 30 == 0){
            printf("%f %f | %f %f\n", pos[0], pos[1], vel[0], vel[1]);
            prints++;
            if (prints > 100)
                exit(0);
        }
    }

    file = fopen(file_track, "wb");
    fwrite(bounces, sizeof(double), TIMEPOINTS, file);
    fclose(file);

    file = fopen(file_pegs, "wb");
    fwrite(pegs, sizeof(double), npegs*2, file);
    fclose(file);

    free(bounces);
    return 0;
}
