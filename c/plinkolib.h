#ifndef __PLINKO_H__
#define __PLINKO_H__

#include "drawinglib.h"

//========================================================
// global constants for the calculation
//========================================================
#define MAXBOUNCES (1<<26)

#define MAXCUPS 50
#define TSAMPLES 25

#define RESULT_NOTHING      0
#define RESULT_COLLISION    1
#define RESULT_WALL_LEFT    2
#define RESULT_WALL_RIGHT   3
#define RESULT_DONE         4

#define EPS 1e-10

#define M_PI 3.14159265358979323846
#define MIN(x,y)  ((x)<(y)?(x):(y))
#define MAX(x,y)  ((x)>(y)?(x):(y))

typedef struct {
    double time_total;
    double xfinal, yfinal;
    int nbounces;
} t_result;

typedef unsigned long long int ullong;
void   ran_seed(long j);
double ran_ran2(void);

//========================================================
/* These are functions that should be called externally */
int trackCollision(double *pos, double *vel, double R, double wall,
        double damp, double *pegs, int npegs, t_result *out);
int trackTrajectory(double *pos, double *vel, double R, double wall,
        double damp, double *pegs, int npegs, t_result *out, int NT, double *traj,
        int constant_interval, double tinterval);
void trackTrajectoryImage(double *pos, double *vel, double R, double wall,
        double damp, double *pegs, int npegs, t_density *density,
        int constant_interval, double tinterval);
void trackTrajectoryImageTwoTone(double *pos, double *vel, double R, double wall,
        double damp, double *pegs, int npegs, t_colorplot *cp,
        int constant_interval, double tinterval);

//========================================================
/* internal use functions only */
double polyeval(double *poly, int deg, double x);
void find_root_pair(double *poly, int deg, double *qpoly,
        double *r1, double *r2);
void find_all_roots(double *poly, int deg, double *roots, int *nroots);
double find_smallest_root(double *poly, int deg);

void build_peg_poly(double *pos, double *vel, double R,
        double *peg, double *poly);

double mymod(double a, double b);
double dot(double *r1, double *r2);
double cross(double *a, double *b);
void position(double *x0, double *v0, double t, double *out);
void velocity(double *v0, double t, double *out);

void build_single_peg(double *pegs, int *npegs, int maxpegs, double x, double y);
void build_hex_grid(double *pegs, int *npegs, int maxpegs, int rows, int cols);
void reflect_vector(double *vec, double *normal, double *out);
void collision_normal(double *pos, double h, double *peg, double *out);
void apply_constraint(double *peg, double R, double *pos, double *norm);

int collides_with_peg(double *pos, double *vel, double R,
        double *peg, double *tcoll);
int earliest_peg_collision(double *pos, double *vel, double R,
        double *pegs, int npegs, double *tcoll, double *peg);
int earliest_peg_collision_parametric(double *pos, double *vel, double R,
        double *pegs, int npegs, double *tcoll, double *peg);
int next_collision(double *pos, double *vel, double R,
        double *pegs, double npegs, double wall, double *tcoll, double *peg);
double zero_cross_time(double *p, double *v);
void create_norm(double *peg, double *pos, double *out);

#endif
