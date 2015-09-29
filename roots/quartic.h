#ifndef __QUARTIC_H__
#define __QUARTIC_H__

#define DEG     4
#define DEGSIZE 5
#define XTOL    1e-14
#define RTOL    1e-14
#define NMAX    (1<<10)

double qvalr(double *poly, double x);
double quartic_exact1_smallest_root(double *poly);
double quartic_exact2_smallest_root(double *poly);
double bairstow_smallest_root(double *poly);
double durand_kerner_smallest_root(double *poly);

#endif
