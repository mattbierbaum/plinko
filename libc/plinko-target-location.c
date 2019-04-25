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

    double R = 0.5;
    double damp = 1.0;
    double wall = 7.0;
    double top = 6.5;
    char filename[1024];
    strcpy(filename, argv[1]);

    char file_track[1024];
    char file_pegs[1024];
    char file_conf[1024];
    sprintf(file_track, "%s.track", filename);
    sprintf(file_pegs, "%s.pegs", filename);
    sprintf(file_conf, "%s.conf", filename);

    int TIMEPOINTS = 1 << 26;
    int MAXPEGS = 1 << 10;
    int npegs = 0;
    double *pegs = malloc(sizeof(double)*2*MAXPEGS);
    double *bounces = malloc(sizeof(double)*2*TIMEPOINTS);
    t_result *res = malloc(sizeof(t_result));

    double pos[2] = { wall / 3. + 1e-3, 10.0 };
    double vel[2] = { 0, 1e-4};

    pos[0] = 3.201; //M_PI+.12;
    pos[1] = 6.0; //top;
    vel[0] = 1e-10;
    vel[1] = 2e-4;

    build_hex_grid(pegs, &npegs, MAXPEGS, 4, 8);

    int clen = trackTrajectory(pos, vel, R, wall, damp,
            pegs, npegs, res, TIMEPOINTS, bounces, 0, 0.008);

    FILE *file = fopen(file_track, "wb");
    fwrite(bounces, sizeof(double), clen, file);
    fclose(file);

    file = fopen(file_pegs, "wb");
    fwrite(pegs, sizeof(double), npegs*2, file);
    fclose(file);

    file = fopen(file_conf, "w");
    fprintf(file, "radius: %f\n", R);
    fprintf(file, "damp: %f\n", damp);
    fprintf(file, "wall: %f\n", wall);
    fprintf(file, "top: %f\n", top);
    fclose(file);

    free(bounces);
    return 0;
}
