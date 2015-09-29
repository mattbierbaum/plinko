#include <stdio.h>
#include <math.h>
#include <complex.h>
#include <string.h>
#include "quartic.h"

#define EPSILON 1e-10

//============================================================================
// These functions are helper functions for quartics using Bairstow's method
//============================================================================
void find_root_pair(double *poly, int deg, double *qpoly,
        double *r1, double *r2){
    int i;
    double c,d,g,h,u,v,det,err,vo,uo;
    double rpoly[DEGSIZE];

    u = poly[deg-1] / poly[deg];
    v = poly[deg-2] / poly[deg];

    int nsteps = 0;  err = 10*XTOL;
    while (err > XTOL && nsteps < NMAX){
        qpoly[deg] = qpoly[deg-1] = 0;
        for (i=deg-2; i>=0; i--)
            qpoly[i] = poly[i+2] - u*qpoly[i+1] - v*qpoly[i+2];
        c = poly[1] - u*qpoly[0] - v*qpoly[1];
        d = poly[0] - v*qpoly[0];

        rpoly[deg] = rpoly[deg-1] = 0;
        for (i=deg-2; i>=0; i--)
            rpoly[i] = qpoly[i+2] - u*rpoly[i+1] - v*rpoly[i+2];
        g = qpoly[1] - u*rpoly[0] - v*rpoly[1];
        h = qpoly[0] - v*rpoly[0];

        det = 1.0/(v*g*g + h*(h-u*g));
        uo = u; vo = v;
        u = u - det*(g*d - c*h);
        v = v - det*((g*u-h)*d - g*v*c);

        err = sqrt((u-uo)*(u-uo)/(uo*uo) + (v-vo)*(v-vo)/(vo*vo));
        nsteps++;
    }

    // b^2 - 4*a*c
    double desc = u*u - 4*v;

    // if we have imaginery roots, quit now
    if (desc < 0){
        *r1 = NAN; *r2 = NAN;
        return;
    }

    double sqt = 0.5*sqrt(desc);
    double boa = -0.5*u;

    *r1 = (boa + sqt);
    *r2 = (boa - sqt);
}

void find_all_roots(double *poly, int deg, double *roots, int *nroots){
    int i;
    double r1, r2;
    double temppoly[DEGSIZE];

    *nroots = 0;
    for (i=deg; i>=1; i-=2){
        find_root_pair(poly, i, temppoly, &r1, &r2);
        memcpy(poly, temppoly, sizeof(double)*deg);

        if (isnan(r1) || isnan(r2))
            continue;

        roots[*nroots] = r1; *nroots += 1;
        roots[*nroots] = r2; *nroots += 1;
    }
}

double bairstow_smallest_root(double *poly){
    int i=0, nroots=0;
    double realroots[DEGSIZE];

    find_all_roots(poly, 4, realroots, &nroots);

    // if we didn't find any roots, return a nan (only special number)
    if (nroots == 0) return NAN;

    // otherwise, find the root closest to zero
    double minroot = NAN;
    for (i=0; i<nroots; i++)
        if ((isnan(minroot) || minroot > realroots[i]) && realroots[i] > 0)
            minroot = realroots[i];

    return minroot;
}

//============================================================================
// These functions are helper functions for quartics using Durand-Kerner
//============================================================================
double _Complex qval(double *poly, double _Complex x){
    return poly[0]+x*(poly[1]+x*(poly[2]+x*(poly[3]+x*poly[4])));
}

#define M_PI 3.14159265358979323846
#define MIN(x,y)  ((x)<(y)?(x):(y))
#define MAX(x,y)  ((x)>(y)?(x):(y))

double durand_kerner_smallest_root(double *poly){
    double rad = 1 + MAX(MAX(MAX(fabs(poly[1]), fabs(poly[2])), fabs(poly[3])), fabs(poly[4]));
    double _Complex p = rad * cexp(0*M_PI/2*I)/1;
    double _Complex r = rad * cexp(1*M_PI/2*I)/2;
    double _Complex s = rad * cexp(2*M_PI/2*I)/3;
    double _Complex t = rad * cexp(3*M_PI/2*I)/4;

    double _Complex pn, rn, tn, sn;

    int steps = 0;
    double err = 1e10;

    while (err > RTOL && steps < NMAX){
        steps++;

        pn = p - qval(poly, p) / ((p-r)*(p-s)*(p-t));
        rn = r - qval(poly, r) / ((r-p)*(r-s)*(r-t));
        sn = s - qval(poly, s) / ((s-r)*(s-p)*(s-t));
        tn = t - qval(poly, t) / ((t-r)*(t-s)*(t-p));

        p = pn; r = rn; s = sn; t = tn;

        err = (fabs(qval(poly, p)) + fabs(qval(poly, r))
             + fabs(qval(poly, s)) + fabs(qval(poly, t)))/4;

        //printf("%e | %e %e %e %e\n", err, fabs(qval(poly, p)), fabs(qval(poly, r)), fabs(qval(poly, s)), fabs(qval(poly, t)));
    }

    double smallest = 1e100;
    int hasroot = 0;
    double _Complex rr, roots[DEGSIZE];
    roots[0] = p; roots[1] = r; roots[2] = s; roots[3] = t;

    for (int i=0; i<DEGSIZE; i++){
        rr = roots[i];
        if (fabs(cimag(rr)) < 2*RTOL && creal(rr) > 0 && creal(rr) < smallest){
            smallest = creal(rr); hasroot = 1;
        }
    }

    if (hasroot)
        return smallest;
    return NAN;
}

//============================================================================
// the exact formula due to Ferrari, others (see wiki)
//============================================================================
double quartic_exact1_smallest_root(double *poly){
    double a = poly[4];
    double b = poly[3];
    double c = poly[2];
    double d = poly[1];
    double e = poly[0];
    double _Complex p  = (8*a*c - 3*b*b)/(8*a*a);
    double _Complex q  = (b*b*b - 4*a*b*c + 8*a*a*d)/(8*a*a*a);
    double _Complex D0 = c*c - 3*b*d + 12*a*e;
    double _Complex D1 = 2*c*c*c - 9*b*c*d + 27*b*b*e + 27*a*d*d - 72*a*c*e;
    double _Complex Q  = cpow((D1 + csqrt(D1*D1 - 4*D0*D0*D0))/2, 1./3);
    double _Complex S  = 0.5*csqrt(-2./3*p + 1./(3*a)*(Q + D0/Q));

    double _Complex desc = -(D1*D1 - 4*D0*D0*D0)/27;

    double _Complex x0 = -b/(4*a) - S + 0.5*csqrt(-4*S*S - 2*p + q/S);
    double _Complex x1 = -b/(4*a) - S - 0.5*csqrt(-4*S*S - 2*p + q/S);
    double _Complex x2 = -b/(4*a) + S + 0.5*csqrt(-4*S*S - 2*p - q/S);
    double _Complex x3 = -b/(4*a) + S - 0.5*csqrt(-4*S*S - 2*p - q/S);

    printf("S = %f + %f I\n\n", creal(S), cimag(S));
    printf("Q = %f + %f I\n\n", creal(Q), cimag(Q));
    printf("%f + %f I\n\n", creal(desc), cimag(desc));
    printf("%f + %f I\n", creal(x0), cimag(x0));
    printf("%f + %f I\n", creal(x1), cimag(x1));
    printf("%f + %f I\n", creal(x2), cimag(x2));
    printf("%f + %f I\n", creal(x3), cimag(x3));

    double smallest = 1e100;
    int hasroot = 0;

    if (fabs(cimag(x0)) < EPSILON && creal(x0) > 0 && creal(x0) < smallest){
        smallest = creal(x0); hasroot = 1;
    }
    if (fabs(cimag(x1)) < EPSILON && creal(x1) > 0 && creal(x1) < smallest){
        smallest = creal(x1); hasroot = 1;
    }
    if (fabs(cimag(x2)) < EPSILON && creal(x2) > 0 && creal(x2) < smallest){
        smallest = creal(x2); hasroot = 1;
    }
    if (fabs(cimag(x3)) < EPSILON && creal(x3) > 0 && creal(x3) < smallest){
        smallest = creal(x3); hasroot = 1;
    }

    if (hasroot)
        return smallest;
    return NAN;
}

double quartic_exact2_smallest_root(double *poly){
    double a = poly[4];
    double b = poly[3];
    double c = poly[2];
    double d = poly[1];
    double e = poly[0];

    double A = (8*c*a-3*b*b)/(8*a*a);
    double B = (b*b*b - 4*a*b*c + 8*d*a*a)/(8*a*a*a);
    double C = (-3*b*b*b*b + 256*e*a*a*a - 64*a*a*b*d + 16*a*b*b*c)/(256*a*a*a*a);

    double i = 1.0;
    double j = 5./2*A;
    double k = (2*A*A-C);
    double l = (0.5*A*A*A - 0.5*A*C - 1./8*B*B);

    double D0 = j*j - 3*i*k;
    double D1 = 2*j*j  - 9*i*j*k + 27*i*i*l;
    double _Complex x = cpow( (D1 + csqrt(D1*D1 - 4*D0*D0*D0))/2, 1./3);
    double _Complex y = 1./3 * (j + x + D0/x);

    double _Complex R = csqrt(A + 2*y);

    double _Complex x0 = (+R + csqrt(-(3*A + 2*y + 2*B/R)))/2;
    double _Complex x1 = (+R - csqrt(-(3*A + 2*y + 2*B/R)))/2;
    double _Complex x2 = (-R + csqrt(-(3*A + 2*y - 2*B/R)))/2;
    double _Complex x3 = (-R - csqrt(-(3*A + 2*y - 2*B/R)))/2;

    printf("%f + %f I\n", creal(x0), cimag(x0));
    printf("%f + %f I\n", creal(x1), cimag(x1));
    printf("%f + %f I\n", creal(x2), cimag(x2));
    printf("%f + %f I\n", creal(x3), cimag(x3));

    double smallest = 1e100;
    int hasroot = 0;

    if (fabs(cimag(x0)) < EPSILON && creal(x0) > 0 && creal(x0) < smallest){
        smallest = creal(x0); hasroot = 1;
    }
    if (fabs(cimag(x1)) < EPSILON && creal(x1) > 0 && creal(x1) < smallest){
        smallest = creal(x1); hasroot = 1;
    }
    if (fabs(cimag(x2)) < EPSILON && creal(x2) > 0 && creal(x2) < smallest){
        smallest = creal(x2); hasroot = 1;
    }
    if (fabs(cimag(x3)) < EPSILON && creal(x3) > 0 && creal(x3) < smallest){
        smallest = creal(x3); hasroot = 1;
    }

    if (hasroot)
        return smallest;
    return NAN;
}
