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
    int clen = 0;
    double R = 0.75/2;
    double damp = 0.9;
    double wall = 14;

    int MAXPEGS = 1 << 10;
    int NPARTICLES = 1 << 10;
    int TIMEPOINTS = 1 << 11;

    char filename[1024];
    char file_track[1024];
    char file_pegs[1024];
    char file_conf[1024];
    strcpy(filename, argv[1]);
    sprintf(file_track, "%s.density", filename);
    sprintf(file_pegs, "%s.pegs", filename);
    sprintf(file_conf, "%s.conf", filename);

    int npegs = 0;
    double *pegs = malloc(sizeof(double)*2*MAXPEGS);
    double *bounces = malloc(sizeof(double)*2*TIMEPOINTS);
    t_result *res = malloc(sizeof(t_result));

    build_hex_grid(pegs, &npegs, MAXPEGS, 4, 16);

    FILE *file = fopen(file_conf, "w");
    fprintf(file, "radius: %f\n", R);
    fprintf(file, "damp: %f\n", damp);
    fprintf(file, "wall: %f\n", wall);
    fprintf(file, "nparticles: %i\n", NPARTICLES);
    fprintf(file, "timepoints: %i\n", TIMEPOINTS);
    fclose(file);

    file = fopen(file_pegs, "wb");
    fwrite(pegs, sizeof(double), npegs*2, file);
    fclose(file);

    double pos[2] = { wall / 2, 10.0 };
    double vel[2] = { 0, 1e-4 };
    double len[2] = { 0, 0 };

    for (int i=0; i<NPARTICLES; i++){
        pos[0] = wall/2 - 0.5 + ran_ran2();
        pos[1] = 10.0;
        vel[0] = 0.0;
        vel[1] = 1e-4;

        if (i % 100 == 0) printf("%i\n", i);

        for (int j=0; j<2*TIMEPOINTS; j++)
            bounces[j] = 0.0;

        clen = trackTrajectory(pos, vel, R, wall, damp,
            pegs, npegs, res, TIMEPOINTS, bounces, 1, 0.10);

        len[0] = len[1] = (double)clen/2;

        FILE *tfile = fopen(file_track, "ab");
        fwrite(len, sizeof(double), 2, tfile);
        fwrite(bounces, sizeof(double), 2*TIMEPOINTS, tfile);
        fflush(tfile);
        fclose(tfile);
    }

    free(bounces);
    return 0;
}
