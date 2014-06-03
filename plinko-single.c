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

    double R = 0.75/2;
    char filename[1024];
    strcpy(filename, argv[1]);

    char file_track[1024];
    char file_pegs[1024];
    sprintf(file_track, "%s.track", filename);
    sprintf(file_pegs, "%s.pegs", filename);

    int TIMEPOINTS = 1 << 20;
    int MAXPEGS = 1 << 10;
    int npegs = 0, wall = 8;
    double *pegs = malloc(sizeof(double)*2*MAXPEGS);
    double *bounces = malloc(sizeof(double)*2*TIMEPOINTS);
    t_result *res = malloc(sizeof(t_result));

    double pos[2] = { wall / 2 - 0.213, 10.0 };
    double vel[2] = { 0, 1e-4};

    build_hex_grid(pegs, &npegs, MAXPEGS, 4, 8);

    int clen = trackTrajectory(pos, vel, R, 7, 0.95, 
            pegs, npegs, res, TIMEPOINTS, bounces);
    
    FILE *file = fopen(file_track, "wb");
    fwrite(bounces, sizeof(double), clen, file);
    fclose(file);

    file = fopen(file_pegs, "wb");
    fwrite(pegs, sizeof(double), npegs*2, file);
    fclose(file);

    free(bounces);
    return 0;
}
