#ifndef __DRAWLINGLIB_H__
#define __DRAWLINGLIB_H__

typedef void (*plotter_func)(void *obj, int x, int y, double intensity);

typedef struct {
    int Nx, Ny, N;
    double x0, x1;
    double y0, y1;
} t_boundary;

typedef struct {
    int Nx, Ny, N;
    double x0, x1;
    double y0, y1;

    double *counts;
} t_density;

t_density *density_create(double ppi, double *bds);
void density_savefile(t_density *density, char *prefix);
void density_plot_line(t_density *density, double *x0, double *x1);

typedef struct {
    int Nx, Ny, N;
    double x0, x1;
    double y0, y1;

    double *counts;
    double *color;
} t_colorplot;

t_colorplot *colorplot_create(double ppi, double *bds);
void colorplot_savefile(t_colorplot *cp, char *prefix);
void colorplot_plot_line(t_colorplot *cp, double *x0, double *x1, double *c);
void colorplot_plot_line_aqua(t_colorplot *cp, double *x0, double *x1);
void colorplot_plot_line_black(t_colorplot *cp, double *x0, double *x1);

#endif
