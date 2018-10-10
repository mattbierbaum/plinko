#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "drawinglib.h"

int ipart(double x) { return (int)x; }
double fpart(double x)  { return x - (int)x; }
double rfpart(double x) { return 1 - fpart(x); }

void swap(double *a, double *b){
    double t = *a;
    *a = *b;
    *b = t;
}

void plotter_density(void *obj, int x, int y, double intensity) {
    /* given the integer coordinates x, y plot_density the line */
    t_density *d = (t_density*)obj;
    int ind = x + y*d->Nx;
    if (ind >= d->N)
        return;
    d->counts[ind] += intensity;
}

void plotter_color(void *obj, int x, int y, double intensity, double *color) {
    t_colorplot *cp = (t_colorplot*)obj;
    int ind = x + y*cp->Nx;
    if (ind >= cp->N)
        return;

    cp->counts[ind] += intensity;
    cp->counts[ind] += color[0];
    /*cp->color[3*ind + 0] = intensity*color[0];
    cp->color[3*ind + 1] = intensity*color[1];
    cp->color[3*ind + 2] = intensity*color[2];*/
}

void plotter_color_black(void *obj, int x, int y, double intensity) {
    double c[] = {0.0, 0.0, 0.0};
    plotter_color(obj, x, y, intensity, c);
}

void plotter_color_aqua(void *obj, int x, int y, double intensity) {
    double c[] = {0.4235, 0.7059, 0.9333};
    plotter_color(obj, x, y, intensity, c);
}

void plotter_color_index(void *obj, int x, int y, double intensity, int index) {
    t_colorplot *cp = (t_colorplot*)obj;
    int ind = x + y*cp->Nx;
    if (ind >= cp->N)
        return;

    if (index >= cp->ncolors)
        return;

    cp->counts[cp->ncolors*ind + index] += intensity;
}

void plotter_color_index0(void *obj, int x, int y, double i) {plotter_color_index(obj, x, y, i, 0);}
void plotter_color_index1(void *obj, int x, int y, double i) {plotter_color_index(obj, x, y, i, 1);}
void plotter_color_index2(void *obj, int x, int y, double i) {plotter_color_index(obj, x, y, i, 2);}
void plotter_color_index3(void *obj, int x, int y, double i) {plotter_color_index(obj, x, y, i, 3);}
void plotter_color_index4(void *obj, int x, int y, double i) {plotter_color_index(obj, x, y, i, 4);}
void plotter_color_index5(void *obj, int x, int y, double i) {plotter_color_index(obj, x, y, i, 5);}

t_density *density_create(double ppi, double *bds) {
    t_density *out = (t_density*)malloc(sizeof(t_density));
    out->x0 = bds[0];
    out->y0 = bds[1];
    out->x1 = bds[2];
    out->y1 = bds[3];
    out->Nx = (int)(ppi * (out->x1 - out->x0));
    out->Ny = (int)(ppi * (out->y1 - out->y0));
    out->N = out->Nx * out->Ny;
    out->counts = (double*)malloc(sizeof(double)*out->N);

    memset(out->counts, 0, sizeof(double)*out->N);
    return out;
}

void density_savefile(t_density *density, char *prefix) {
    char filename[2048];
    sprintf(filename, "%s.%i-%i_double.npy", prefix, density->Nx, density->Ny);

    FILE *tfile = fopen(filename, "wb");
    fwrite(density->counts, sizeof(double), density->Nx*density->Ny, tfile);
    fflush(tfile);
    fclose(tfile);
}

t_colorplot *colorplot_create(double ppi, double *bds, int ncolors) {
    t_colorplot *out = (t_colorplot*)malloc(sizeof(t_colorplot));
    out->x0 = bds[0];
    out->y0 = bds[1];
    out->x1 = bds[2];
    out->y1 = bds[3];
    out->Nx = (int)(ppi * (out->x1 - out->x0));
    out->Ny = (int)(ppi * (out->y1 - out->y0));
    out->N = out->Nx * out->Ny;
    out->ncolors = ncolors;
    out->counts = (double*)malloc(sizeof(double)*out->N*out->ncolors);
    //out->color = (double*)malloc(sizeof(double)*out->N*3);

    memset(out->counts, 0, sizeof(double)*out->N);
    //memset(out->color, 0, sizeof(double)*out->N*3);
    return out;
}

void colorplot_savefile(t_colorplot *cp, char *prefix) {
    char filename[2048];

    sprintf(filename, "%s.%i-%i_double_count.npy", prefix, cp->Nx, cp->Ny);
    FILE *tfile = fopen(filename, "wb");
    fwrite(cp->counts, sizeof(double), cp->ncolors*cp->Nx*cp->Ny, tfile);
    fflush(tfile);
    fclose(tfile);

    /*sprintf(filename, "%s.%i-%i_double_color.npy", prefix, cp->Nx, cp->Ny);
    tfile = fopen(filename, "wb");
    fwrite(cp->color, sizeof(double), 3*cp->Nx*cp->Ny, tfile);
    fflush(tfile);
    fclose(tfile);*/
}

void plot_line(void *obj, double *p0, double *p1, plotter_func func) {
    t_boundary *ob = (t_boundary*)obj;
    double x0 = ob->Nx * (p0[0] - ob->x0) / (ob->x1 - ob->x0);
    double y0 = ob->Ny * (p0[1] - ob->y0) / (ob->y1 - ob->y0);
    double x1 = ob->Nx * (p1[0] - ob->x0) / (ob->x1 - ob->x0);
    double y1 = ob->Ny * (p1[1] - ob->y0) / (ob->y1 - ob->y0);

    int steep = fabs(y1 - y0) > fabs(x1 - x0);
    
    if (steep) {
        swap(&x0, &y0);
        swap(&x1, &y1);
    }
    if (x0 > x1) {
        swap(&x0, &x1);
        swap(&y0, &y1);
    }
    
    double dx = x1 - x0;
    double dy = y1 - y0;
    double gradient = dy / dx;
    if (dx == 0.0) {
        gradient = 1.0;
    }

    double xend = round(x0);
    double yend = y0 + gradient * (xend - x0);
    double xgap = rfpart(x0 + 0.5);
    double xpxl1 = xend;
    double ypxl1 = ipart(yend);
    if (steep) {
        func(obj, ypxl1,   xpxl1, rfpart(yend) * xgap);
        func(obj, ypxl1+1, xpxl1,  fpart(yend) * xgap);
    } else {
        func(obj, xpxl1, ypxl1  , rfpart(yend) * xgap);
        func(obj, xpxl1, ypxl1+1,  fpart(yend) * xgap);
    }
    double intery = yend + gradient;
    
    // handle second endpoint
    xend = round(x1);
    yend = y1 + gradient * (xend - x1);
    xgap = fpart(x1 + 0.5);
    double xpxl2 = xend;
    double ypxl2 = ipart(yend);
    if (steep) {
        func(obj, ypxl2  , xpxl2, rfpart(yend) * xgap);
        func(obj, ypxl2+1, xpxl2,  fpart(yend) * xgap);
    } else {
        func(obj, xpxl2, ypxl2,  rfpart(yend) * xgap);
        func(obj, xpxl2, ypxl2+1, fpart(yend) * xgap);
    }
    
    // main loop
    if (steep) {
        for (int x = xpxl1 + 1; x <= xpxl2 - 1; x++) {
            func(obj, ipart(intery)  , x, rfpart(intery));
            func(obj, ipart(intery)+1, x,  fpart(intery));
            intery = intery + gradient;
        }
    } else {
        for (int x = xpxl1 + 1; x <= xpxl2 - 1; x++) {
            func(obj, x, ipart(intery),  rfpart(intery));
            func(obj, x, ipart(intery)+1, fpart(intery));
            intery = intery + gradient;
        }
    }
}

void density_plot_line(t_density *density, double *p0, double *p1) {
    plot_line((void*)density, p0, p1, plotter_density);
}

void colorplot_plot_line_index(t_colorplot *density, double *p0, double *p1, int index) {
    if (index == 0) plot_line((void*)density, p0, p1, plotter_color_index0);
    if (index == 1) plot_line((void*)density, p0, p1, plotter_color_index1);
    if (index == 2) plot_line((void*)density, p0, p1, plotter_color_index2);
    if (index == 3) plot_line((void*)density, p0, p1, plotter_color_index3);
    if (index == 4) plot_line((void*)density, p0, p1, plotter_color_index4);
    if (index == 5) plot_line((void*)density, p0, p1, plotter_color_index5);
}
