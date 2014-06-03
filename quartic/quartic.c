#include <stdio.h>
#include <math.h>
#include <complex.h>

#define EPSILON 1e-10

double quartic_smallest_root(double *poly){
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

/*double quartic_smallest_root(double *poly){
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
}*/
