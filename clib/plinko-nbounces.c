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

    double R = 0.5/2;
    double damp = 0.5;
    double wall = 7.0/2;
    double top = 8.0/2;
    char filename[1024];
    strcpy(filename, argv[1]);

    int POW = 26; // must be even
    int NPARTICLES = 1 << POW;
    int NSIDE = 1 << POW/2;

    int MAXPEGS = 1 << 10;
    int npegs = 0;
    double *pegs = malloc(sizeof(double)*2*MAXPEGS);
    double *times= malloc(sizeof(double)*NPARTICLES);
    t_result *res = malloc(sizeof(t_result));

    double pos[2];
    double vel[2];

    double Lx = 1.0;
    double Ly = 1.0;
    double dx = Lx / NSIDE;
    double dy = Ly / NSIDE;
    double px = wall / 2 - dx * (NSIDE/2 - (108 % NSIDE));
    double py = top      - dy * (NSIDE/2 - (207 / NSIDE));

    Lx = (369 - 108) * dx;
    Ly = (1327 - 207) * dx;
    dx = Lx / NSIDE;
    dy = Ly / NSIDE;

    build_hex_grid(pegs, &npegs, MAXPEGS, 2, 4);

    for (int i=0; i<NPARTICLES; i++) {
        if (i % 10000 == 0)
            printf("%i\n", i);
        pos[0] = px - dx * (NSIDE/2 - (i % NSIDE));
        pos[1] = py - dy * (NSIDE/2 - (i / NSIDE));
        vel[0] = 1e-10;
        vel[1] = 2e-4;
        trackCollision(pos, vel, R, wall, damp, pegs, npegs, res);
        times[i] = res->time_total;
    }

    //==========================================================
    char file_track[1024];
    char file_pegs[1024];
    char file_conf[1024];
    sprintf(file_track, "%s.track", filename);
    sprintf(file_pegs, "%s.pegs", filename);
    sprintf(file_conf, "%s.conf", filename);

    FILE *file = fopen(file_track, "wb");
    fwrite(times, sizeof(double), NPARTICLES, file);
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
    //==========================================================

    free(times);
    return 0;
}
