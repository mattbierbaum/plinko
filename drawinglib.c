#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "drawinglib.h"

void swap(double *a, double *b){
    double t = *a;
    *a = *b;
    *b = t;
}

void plot(t_density *d, int x, int y, double c) {
    /* given the integer coordinates x, y plot the line */
    int ind = x + y*d->Nx;
    if (ind >= d->N)
        return;
    d->counts[ind] += c;
}
        
// integer part of x
int ipart(double x) { return (int)x; }
//int round(double x) { return ipart(x + 0.5); }

// fractional part of x
double fpart(double x)  { return x - (int)x; }
double rfpart(double x) { return 1 - fpart(x); }

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

void density_plot_line(t_density *density, double *p0, double *p1) {
    double x0 = density->Nx * (p0[0] - density->x0) / (density->x1 - density->x0);
    double y0 = density->Ny * (p0[1] - density->y0) / (density->y1 - density->y0);
    double x1 = density->Nx * (p1[0] - density->x0) / (density->x1 - density->x0);
    double y1 = density->Ny * (p1[1] - density->y0) / (density->y1 - density->y0);

    printf("%f %f %f %f\n", x0, y0, x1, y1);
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
        plot(density, ypxl1,   xpxl1, rfpart(yend) * xgap);
        plot(density, ypxl1+1, xpxl1,  fpart(yend) * xgap);
    } else {
        plot(density, xpxl1, ypxl1  , rfpart(yend) * xgap);
        plot(density, xpxl1, ypxl1+1,  fpart(yend) * xgap);
    }
    double intery = yend + gradient;
    
    // handle second endpoint
    xend = round(x1);
    yend = y1 + gradient * (xend - x1);
    xgap = fpart(x1 + 0.5);
    double xpxl2 = xend;
    double ypxl2 = ipart(yend);
    if (steep) {
        plot(density, ypxl2  , xpxl2, rfpart(yend) * xgap);
        plot(density, ypxl2+1, xpxl2,  fpart(yend) * xgap);
    } else {
        plot(density, xpxl2, ypxl2,  rfpart(yend) * xgap);
        plot(density, xpxl2, ypxl2+1, fpart(yend) * xgap);
    }
    
    // main loop
    if (steep) {
        for (int x = xpxl1 + 1; x < xpxl2 - 1; x++) {
            plot(density, ipart(intery)  , x, rfpart(intery));
            plot(density, ipart(intery)+1, x,  fpart(intery));
            intery = intery + gradient;
        }
    } else {
        for (int x = xpxl1 + 1; x < xpxl2 - 1; x++) {
            plot(density, x, ipart(intery),  rfpart(intery));
            plot(density, x, ipart(intery)+1, fpart(intery));
            intery = intery + gradient;
        }
    }
}
