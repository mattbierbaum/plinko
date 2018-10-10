#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/types.h>
#include "plinkolib.h"
#include "drawinglib.h"

int main(int argc, char **argv){
    if (argc != 2){
        printf("Incorrect arguments supplied, must be <filename>\n");
        return 1;
    }

    ran_seed(123123);
    //int clen = 0;
    double R = 0.75/2; double damp = 0.80;
    double wall = 14;
    double top = 10.0;

    int MAXPEGS = 1 << 10;
    int NPARTICLES = 1 << 13;
    int TIMEPOINTS = 1 << 11;

    char filename[1024];
    char file_pegs[1024];
    char file_conf[1024];
    strcpy(filename, argv[1]);
    sprintf(file_pegs, "%s.pegs", filename);
    sprintf(file_conf, "%s.conf", filename);

    int npegs = 0;
    double *pegs = malloc(sizeof(double)*2*MAXPEGS);

    build_hex_grid(pegs, &npegs, MAXPEGS, 4, 16);

    FILE *file = fopen(file_conf, "w");
    fprintf(file, "radius: %f\n", R);
    fprintf(file, "damp: %f\n", damp);
    fprintf(file, "wall: %f\n", wall);
    fprintf(file, "top: %f\n", top);
    fprintf(file, "nparticles: %i\n", NPARTICLES);
    fprintf(file, "timepoints: %i\n", TIMEPOINTS);
    fclose(file);

    file = fopen(file_pegs, "wb");
    fwrite(pegs, sizeof(double), npegs*2, file);
    fclose(file);

    double pos[2] = { wall / 2, 10.0 };
    double vel[2] = { 0, 1e-4 };

    double ppi = 200;
    double bds[] = {0.0, 0.0, wall, top};
    t_colorplot *cp = colorplot_create(ppi, bds);

    for (int i=0; i<NPARTICLES; i++){
        pos[0] = wall/2 - 0.5 + ((double)i/NPARTICLES); //ran_ran2();
        pos[1] = top - 1e-3;
        vel[0] = 0.0;
        vel[1] = -1e-4;

        if (i % 100 == 0) printf("%i\n", i);

        trackTrajectoryImageTwoTone(pos, vel, R, wall, damp, pegs, npegs, cp, 1, 0.10);
    }
    colorplot_savefile(cp, filename);

    return 0;
}
