#ifndef __DRAWLINGLIB_H__
#define __DRAWLINGLIB_H__

typedef struct {
    int Nx, Ny, N;
    double *counts;

    double x0, x1;
    double y0, y1;
} t_density;

t_density *density_create(double ppi, double *bds);
void density_savefile(t_density *density, char *prefix);
void density_plot_line(t_density *density, double *x0, double *x1);

#endif
