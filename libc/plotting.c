#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define MIN(a, b) ((a < b) ? a : b)
#define MAX(a, b) ((a > b) ? a : b)

typedef unsigned char ubyte;

typedef struct {
    float *data;
    int nx, ny;
    int size;

    float box[4];
    float dpi;
} t_density;

typedef struct {
    unsigned char *data;
    int nx, ny, nc;
    int size;
} t_image;

typedef struct {
    float *data;
    float bounds[2];
    int nbins;
} t_histogram;

/*=================================================================*/
/*=================================================================*/
t_density *_create_density(float box[4], float dpi) {
    t_density *out = (t_density*)malloc(sizeof(t_density));
    float x0 = box[0];
    float y0 = box[1];
    float x1 = box[2];
    float y1 = box[3];
    int nx = (int)((x1 - x0) * dpi);
    int ny = (int)((y1 - y0) * dpi);

    memcpy(out->box, box, sizeof(float)*4);
    out->dpi = dpi;
    out->nx = nx;
    out->ny = ny;
    out->size = nx * ny;
    out->data = (float*)malloc(sizeof(float)*out->size);
    memset(out->data, 0, sizeof(float)*out->size);
    return out;
}

t_image *_create_image(int nx, int ny, int colors) {
    t_image *out = (t_image*)malloc(sizeof(t_image));
    out->nx = nx;
    out->ny = ny;
    out->nc = colors;
    out->size = nx * ny * colors;
    out->data = (ubyte*)malloc(sizeof(ubyte)*out->size);
    memset(out->data, 0, sizeof(float)*out->size);
    return out;
}

t_histogram *_create_histogram(float bounds[2], int nbins) {
    t_histogram *out = (t_histogram*)malloc(sizeof(t_histogram));
    out->nbins = nbins;
    out->data = (float*)malloc(sizeof(float)*out->nbins);
    memcpy(out->bounds, bounds, sizeof(float)*2);
    memset(out->data, 0, sizeof(float)*out->nbins);
    return out;
}

void _free_density(t_density *d) {
    free(d->data);
    free(d);
}

void _free_image(t_image *d) {
    free(d->data);
    free(d);
}

void _free_histogram(t_histogram *d) {
    free(d->data);
    free(d);
}

/*=================================================================*/
/*=================================================================*/
t_histogram *_histogram(t_density *density, int nbins, int docut) {
    int i=0;
    float min = 1e10;
    float max = -1e10;
    float cut = docut ? 1e-15 : -1e10;

    for (i=0; i < density->size; i++) {
        float v = density->data[i];
        if (v < min && v > cut) min = v;
        if (v > max) max = v;
    }

    float bounds[2] = {min, max};
    t_histogram *hist = _create_histogram(bounds, nbins);

    float norm = 1.0 / (max - min);
    for (i=0; i < density->size; i++) {
        float v = density->data[i];
        if (docut && v > min) {
            float r = hist->nbins * (v - min) * norm;
            int n = (int)(MAX(MIN(r, hist->nbins-1), 0));
            hist->data[n] = hist->data[n] + 1;
        }
    }

    return hist;
}

t_histogram *_cdf(t_histogram *hist) {
    int i = 0;
    t_histogram *cdf = _create_histogram(hist->bounds, hist->nbins);
    float total = 0.0;
    float tsum = 0.0;

    for (i=0; i<hist->nbins; i++) {
        tsum += hist->data[i];
    }

    for (i=0; i<hist->nbins; i++) {
        float v = hist->data[i];
        total +=  v;
        cdf->data[i] = total / tsum;
    }

    return cdf;
}

t_density *_eq_hist(t_density *density, int nbins, int docut) {
    int i = 0;
    float min = 1e10;
    float max = -1e10;
    float cut = docut ? 1e-15 : -1e10;

    for (i=0; i < density->size; i++) {
        float v = density->data[i];
        if (v < min && v > cut) min = v;
        if (v > max) max = v;
    }

    t_histogram *hist = _histogram(density, nbins, docut);
    t_histogram *cdf = _cdf(hist);

    float dx = (max - min) / nbins;
    float b0 = min + dx/2 + 0*dx;
    float b1 = min + dx/2 + nbins*dx;

    t_density *out = _create_density(density->box, density->dpi);
    for (i=0; i<density->size; i++) {
        float v = density->data[i];
        if (v <= b0) out->data[i] = 0.0;
        if (v >= b1) out->data[i] = 1.0;
        if (v > b0 && v < b1) {
            int bin = (int)((v - b0)/dx);
            float x1 = min + dx/2 + bin*dx;
            float x2 = min + dx/2 + (bin+1)*dx;
            float y1 = cdf->data[bin];
            float y2 = cdf->data[bin+1];
            out->data[i] = y1 + (y2 - y1)/(x2 - x1) * (v - x1);
        }
    }

    _free_histogram(hist);
    _free_histogram(cdf);
    return out;
}

/*=================================================================*/
/*=================================================================*/
void _swap(float *a, float *b){
    float t = *a;
    *a = *b;
    *b = t;
}

int ipart(x) { return (int)(x); }
int iround(x) { return (int)ipart(x + 0.5); }
float fpart(x) { return x - floor(x); }
float rfpart(x) { return 1 - fpart(x); }

void _plot(t_density *d, int x, int y, float c) {
    printf("%i %i %f\n", x, y, c);
    if (x < 0 || x >= d->nx || y < 0 || y >= d->ny) {
        return;
    }

    int ind = x + y*d->nx;
    d->data[ind] += c;
}

void _plot_line(t_density *d, float x0, float y0, float x1, float y1) {
    int steep = fabs(y1 - y0) > fabs(x1 - x0);
    
    if (steep) {
        _swap(&x0, &y0);
        _swap(&x1, &y1);
    }
    if (x0 > x1) {
        _swap(&x0, &x1);
        _swap(&y0, &y1);
    }
    
    float dx = x1 - x0;
    float dy = y1 - y0;
    float gradient = 1.0*dy / dx;

    printf("%f %f\n", dx, dy);
    if (dx == 0) {
        gradient = 1.0;
    }

    float xend = iround(x0);
    float yend = y0 + gradient * (xend - x0);
    float xgap = rfpart(x0 + 0.5);
    float xpxl1 = xend;
    float ypxl1 = ipart(yend);

    if (steep) {
        _plot(d, ypxl1,   xpxl1, rfpart(yend) * xgap);
        _plot(d, ypxl1+1, xpxl1,  fpart(yend) * xgap);
    } else {
        _plot(d, xpxl1, ypxl1  , rfpart(yend) * xgap);
        _plot(d, xpxl1, ypxl1+1,  fpart(yend) * xgap);
    }

    float intery = yend + gradient;
    
    xend = iround(x1);
    yend = y1 + gradient * (xend - x1);
    xgap = fpart(x1 + 0.5);
    float xpxl2 = xend;
    float ypxl2 = ipart(yend);
    if (steep) {
        _plot(d, ypxl2  , xpxl2, rfpart(yend) * xgap);
        _plot(d, ypxl2+1, xpxl2,  fpart(yend) * xgap);
    } else {
        _plot(d, xpxl2, ypxl2,  rfpart(yend) * xgap);
        _plot(d, xpxl2, ypxl2+1, fpart(yend) * xgap);
    }

    float x = 0;
    printf("%f %f | %f %f\n", x0, x1, xpxl1, xpxl2);
    if (steep) {
        for (x = xpxl1 + 1; x < xpxl2; x++) {
            printf("%f\n", x);
           _plot(d, ipart(intery)  , x, rfpart(intery));
           _plot(d, ipart(intery)+1, x,  fpart(intery));
           intery = intery + gradient;
        }
    } else {
        for (x = xpxl1 + 1; x < xpxl2; x++) {
            printf("%f\n", x);
           _plot(d, x, ipart(intery),  rfpart(intery));
           _plot(d, x, ipart(intery)+1, fpart(intery));
           intery = intery + gradient;
        }
    }
}

void _draw_segment(t_density *d, float seg[4]) {
    float x0 = d->box[0];
    float y0 = d->box[1];
    float x1 = d->box[2];
    float y1 = d->box[3];

    float sx0 = d->nx * (seg[0] - x0) / (x1 - x0);
    float sy0 = d->ny * (seg[1] - y0) / (y1 - y0);
    float sx1 = d->nx * (seg[2] - x0) / (x1 - x0);
    float sy1 = d->ny * (seg[3] - y0) / (y1 - y0);
    _plot_line(d, sx0, sy0, sx1, sy1);
}

void _draw_point(t_density *d, float x, float y) {
    float sx = d->dpi * (x - d->box[0]);
    float sy = d->dpi * (y - d->box[1]);
    _plot(d, sx, sy, 1);
}

/*=================================================================*/
/*=================================================================*/
static int create_density(lua_State *L) {
    float x0 = (float)luaL_checknumber(L, 1);
    float y0 = (float)luaL_checknumber(L, 2);
    float x1 = (float)luaL_checknumber(L, 3);
    float y1 = (float)luaL_checknumber(L, 4);
    float dpi = (float)luaL_checknumber(L, 5);
    float box[4] = {x0, y0, x1, y1};

    t_density *out = _create_density(box, dpi);
    lua_pushlightuserdata(L, (void*)out);

    return 1;
}

static int eq_hist(lua_State *L) {
    /* Arguments: (t_density, nbins)  Returns: t_density */
    if (!lua_islightuserdata(L, 1)) {
        printf("Argument 1 is not c-pointer\n");
        return 0;
    }

    t_density *density = (t_density*)lua_topointer(L, 1);
    int nbins = (int)luaL_checknumber(L, 2);

    t_density *hist = _eq_hist(density, nbins, 1);
    lua_pushlightuserdata(L, (void*)hist);

    return 1;
}

static int save_bin(lua_State *L) {
    /* Arguments: (t_density, filename)  Returns: N/A */
    t_density *density = (t_density*)lua_topointer(L, 1);
    const char *fn = luaL_checkstring(L, 2);

    FILE *file = fopen(fn, "wb");
    fwrite(density->data, sizeof(float), density->size, file);
    fclose(file);
    return 1;
}

static int save_csv(lua_State *L) {
    /* Arguments: (t_density, filename)  Returns: N/A */
    t_density *density = (t_density*)lua_topointer(L, 1);
    const char *fn = luaL_checkstring(L, 2);

    int i, j;
    FILE *file = fopen(fn, "w");
    for (j=0; j<density->ny; j++) {
        for (i=0; i<density->nx; i++) {
            fprintf(file, "%f ", density->data[i+density->nx*j]);
        }
        fprintf(file, "\n");
    }
    fclose(file);
    return 1;
}

static int draw_segment(lua_State *L) {
    t_density *density = (t_density*)lua_topointer(L, 1);
    float x0 = (float)luaL_checknumber(L, 2);
    float y0 = (float)luaL_checknumber(L, 3);
    float x1 = (float)luaL_checknumber(L, 4);
    float y1 = (float)luaL_checknumber(L, 5);
    float seg[4] = {x0, y0, x1, y1};

    _draw_segment(density, seg);
    return 1;
}

static int draw_point(lua_State *L) {
    t_density *density = (t_density*)lua_topointer(L, 1);
    float x = (float)luaL_checknumber(L, 2);
    float y = (float)luaL_checknumber(L, 3);
    _draw_point(density, x, y);
    return 1;
}

/*=================================================================*/
/*=================================================================*/
static const luaL_Reg plotting[] = {
    {"create_density", create_density},
    {"eq_hist", eq_hist},
    /*{"normalize", normalize},*/
    {"draw_segment", draw_segment},
    {"draw_point", draw_point},
    {"save_csv", save_csv},
    {"save_bin", save_bin},
    {NULL, NULL}
};

#if LUA_VERSION_NUM >= 502
int luaopen_plotting(lua_State *L) {
    luaL_newlib(L, plotting);
    return 1;
}
#else
extern int luaopen_plotting(lua_State *L) {
    luaL_openlib(L, "plotting", plotting, 0);
    return 1;
}
#endif
