#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "plinkolib.h"
#include "roots/quartic.h"

/*===========================================================================
 *  Some notes:
 *      - the lattice constant for the pegs is the unit, so it is 1
 *      - there will be a 'neighbor' list of pegs instead of pegs near
 *          ( this will allow us to use very small pegs if we want )
 *      - still thinking about how to add wall friction
 *      - according to PisR, the ratio of the disc to spacing is 3/4
 *=========================================================================*/
void build_peg_poly(double *pos, double *vel, double R, 
        double *peg, double *poly){
    // t^4 (0.25) - t^3 (vy) + t^2 (vx^2 + vy^2 - dy) +
    // t (2*vx*dx + 2*vy*dy) + t^0 (dx^2 + dy^2 - R^2) = 0
    double R2, dx, dy, vx, vy;
    vx = vel[0]; vy = vel[1];
    dx = pos[0]-peg[0];  
    dy = pos[1]-peg[1];  
    R2 = R*R;
        
    poly[4] = 1.0/4;
    poly[3] = -vy;
    poly[2] = vx*vx + vy*vy - dy;
    poly[1] = 2*(vx*dx + vy*dy);
    poly[0] = dx*dx + dy*dy - R2;
}

//============================================================================
// These are helper functions that calculate positions of pegs and 
// the positions of trajectories
//============================================================================
inline double mymod(double a, double b){ return a - b*(int)(a/b) + b*(a<0); }
inline double dot(double *r1, double *r2){ return r1[0]*r2[0] + r1[1]*r2[1]; }
inline double cross(double *a, double *b){ return a[0]*b[1]-a[1]*b[0]; }

inline void position(double *x0, double *v0, double t, double *out){
    out[0] = x0[0] + v0[0]*t;
    out[1] = x0[1] + v0[1]*t - 0.5*t*t;
}

inline void velocity(double *v0, double t, double *out){
    out[0] = v0[0];
    out[1] = v0[1] - t;
}

//============================================================================
// Cup neighborlist generator - finite and infinite sets
//============================================================================
// a square grid of pegs at even grid points
void pegs_between(double *pos, double *pegs, int *npegs){
    int i, j;
    *npegs = 0;
    for (i=-1; i<=1; i++){
        for (j=-1; j<=1; j++){
            pegs[2*(*npegs)+0] = pos[0]-(mymod(pos[0]+1, 2)-1) + 2*i;
            pegs[2*(*npegs)+1] = pos[1]-(mymod(pos[1]+1, 2)-1) + 2*j;
            *npegs += 1;
        }
    }
}

void build_hex_grid(double *pegs, int *npegs, int maxpegs, int rows, int cols){
    *npegs = 0;

    // build the lattice based on the rectangular 2 atom unit cell
    double a = 1.0;
    double rt3 = sqrt(3.0);
    for (int i=0; i<rows; i++){
        for (int j=0; j<cols; j++){
            if (*npegs > maxpegs-2)
                return;

            if (i*a*rt3 >= 1e-10){
                pegs[2*(*npegs)+0] = j*a;
                pegs[2*(*npegs)+1] = i*a*rt3;
                *npegs += 1;
            }

            if (j != cols-1){
                pegs[2*(*npegs)+0] = (j+0.5)*a;
                pegs[2*(*npegs)+1] = (i+0.5)*a*rt3;
                *npegs += 1;
            }
        }
    }
}

void collision_normal(double *pos, double h, double *peg, double *out){
    double t[2];
    t[0] = pos[0] - peg[0];
    t[1] = pos[1] - peg[1];
    
    double theta = atan2(t[1],t[0]);
    double xin = h*cos(theta);
    double yin = h*sin(theta);
  
    out[0] = t[0]-xin;
    out[1] = t[1]-yin;

    double len = sqrt(dot(out,out));
    out[0] /= len;
    out[1] /= len;
}

void reflect_vector(double *vec, double *normal, double *out){
    // v - 2*(v dot n) n
    double ddot = dot(vec, normal);
    out[0] = (vec[0] - 2*ddot*normal[0]);
    out[1] = (vec[1] - 2*ddot*normal[1]);
}


//============================================================================
// finds the collision time for an initial condition
// by finding the roots of a poly and finding the nearest collision
//============================================================================
int collides_with_peg(double *pos, double *vel, double R,
        double *peg, double *tcoll){
    /* 
     * This functions determines whether a particular trajectory collides
     * with the peg specified by h, r, (cx, cy).  It returns:
     *  0 : There was no collision 
     *  1 : There was a collision and it occured at tcoll
     * It does not modify the values of pos, vel; modified tcoll
    */
    double poly[DEGSIZE];
    
    build_peg_poly(pos, vel, R, peg, poly);
    *tcoll = bairstow_smallest_root(poly);
    //*tcoll = durand_kerner_smallest_root(poly);
    //*tcoll = quartic_exact1_smallest_root(poly);
    //*tcoll = quartic_exact2_smallest_root(poly);

    if (isnan(*tcoll))
        return RESULT_NOTHING;
    return RESULT_COLLISION;
}

int earliest_peg_collision(double *pos, double *vel, double R,
        double *pegs, int npegs, double *tcoll, double *peg){
    int i, result, event;
    double tevent;

    event = RESULT_NOTHING;
    tevent = NAN;

    for (i=0; i<npegs; i++){
        result = collides_with_peg(pos, vel, R, &pegs[2*i], tcoll);
        if (result == RESULT_COLLISION){
            if ((isnan(tevent) || tevent > *tcoll) && *tcoll > 0){
                peg[0] = pegs[2*i+0];
                peg[1] = pegs[2*i+1];
                event = result;
                tevent = *tcoll;
            }
        }
    }
    *tcoll = tevent;
    return event;
}

int next_collision(double *pos, double *vel, double R,
        double *pegs, double npegs, double wall, double *tcoll, double *peg){
    int result;
    int event = RESULT_NOTHING;
    double tevent = NAN, twall = 0;

    result = earliest_peg_collision(pos, vel, R, pegs, npegs, tcoll, peg);
    if (result == RESULT_COLLISION){
        if ((isnan(tevent) || tevent > *tcoll) && *tcoll > 0){
            event = result;
            tevent = *tcoll;
        }
    }

    twall = -pos[0] / vel[0];
    if (!isnan(twall) && (isnan(tevent) || tevent > twall) && twall > 0){
        event = RESULT_WALL_LEFT; tevent = twall;
    }

    twall = (wall-pos[0]) / vel[0];
    if (!isnan(twall) && (isnan(tevent) || tevent > twall) && twall > 0){
        event = RESULT_WALL_RIGHT; tevent = twall;
    }

    twall = zero_cross_time(pos, vel);
    if (!isnan(twall) && (isnan(tevent) || tevent > twall) && twall > 0){
        event = RESULT_DONE; tevent = twall;
    }

    *tcoll = tevent;
    return event;
}

double zero_cross_time(double *p, double *v){
    double a = -1./2;
    double b = v[1];
    double c = p[1];
    double desc = b*b - 4*a*c;

    if (desc > 0){
        double t0 = (-b + sqrt(desc))/(2*a);
        double t1 = (-b - sqrt(desc))/(2*a);
        if (t0 > 0){
            if (t1>0) return MIN(t0, t1);
            else      return t0;
        } else {
            if (t1>0) return t1;
            else      return NAN;
        }
    }
    return NAN;
}

void create_norm(double *peg, double *pos, double *out){
    out[0] = pos[0] - peg[0];
    out[1] = pos[1] - peg[1];
    double len = sqrt(dot(out, out));
    out[0] /= len;
    out[1] /= len;
}

int trackCollision(double *pos, double *vel, double R, double wall,
        double damp, double *pegs, int npegs, t_result *out){
    int result;
    int clen = 0;
    double tcoll, vlen;

    double tpos[2], tvel[2], peg[2], norm[2]; 
    memcpy(tpos, pos, sizeof(double)*2);
    memcpy(tvel, vel, sizeof(double)*2);

    peg[0] = peg[1] = 0.0;
    int tbounces = 0;
    while (tbounces < MAXBOUNCES){
        result = next_collision(tpos, tvel, R, pegs, npegs, wall, &tcoll, peg);

        if (result == RESULT_NOTHING) break;
        if (result == RESULT_DONE){
            position(tpos, tvel, tcoll, tpos);
            out->xfinal = tpos[0];
            break;
        }

        // figure out where it hit and what speed
        position(tpos, tvel, tcoll, tpos);
        velocity(tvel, tcoll, tvel);
        vlen = dot(tvel, tvel);

        if (tpos[1] < 0 || vlen < EPS) break;
        if (result == RESULT_WALL_LEFT)  tvel[0] *= -1;
        if (result == RESULT_WALL_RIGHT) tvel[0] *= -1;
        if (result == RESULT_COLLISION){
            create_norm(peg, tpos, norm); 
            reflect_vector(tvel, norm, tvel);
        }

        position(tpos, tvel, EPS, tpos); 
        velocity(tvel, EPS, tvel);
        tvel[0] *= damp;
        tvel[1] *= damp;
        tbounces++;
    }

    out->nbounces = tbounces;
    return 2*clen;
}

int trackTrajectory(double *pos, double *vel, double R, double wall,
        double damp, double *pegs, int npegs, t_result *out, int NT, double *traj,
        int constant_interval, double tinterval){
    int result;
    int clen = 0;
    double tcoll=0.0, vlen=0.0, tlastbounce=0.0, tlastsave=0.0, temp_lastsave=0.0, tint;

    //double timereal = 0.0, timesave = 0.0;

    double tpos[2], tvel[2], peg[2], ttpos[2], norm[2]; 
    memcpy(tpos, pos, sizeof(double)*2);
    memcpy(tvel, vel, sizeof(double)*2);

    peg[0] = peg[1] = 0.0;
    int tbounces = 0;
    while (tbounces < MAXBOUNCES){
        result = next_collision(tpos, tvel, R, pegs, npegs, wall, &tcoll, peg);

        tint = constant_interval ? tinterval : tcoll/TSAMPLES;
        for (double t=tlastsave+tint; t<(tlastbounce+tcoll); t+=tint){
            position(tpos, tvel, t-tlastbounce, ttpos);
            if (NT >= 0 && clen < NT/2-2){
                temp_lastsave = t;
                memcpy(traj+2*clen, ttpos, sizeof(double)*2);
                clen += 1;
            }
        }
        tlastsave = temp_lastsave;

        if (result == RESULT_NOTHING) break;
        if (result == RESULT_DONE)    break;

        // figure out where it hit and what speed
        position(tpos, tvel, tcoll, tpos);
        velocity(tvel, tcoll, tvel);
        vlen = dot(tvel, tvel);

        tlastbounce = tlastbounce + tcoll;

        // react to the collision
        if (tpos[1] < 0 || vlen < EPS) break;
        if (result == RESULT_WALL_LEFT)  tvel[0] *= -1;
        if (result == RESULT_WALL_RIGHT) tvel[0] *= -1;
        if (result == RESULT_COLLISION){
            create_norm(peg, tpos, norm); 
            reflect_vector(tvel, norm, tvel);
            apply_constraint(peg, R, tpos, norm);

            // display the collision normals in the trajectory
            /*if (NT >= 0 && clen < NT/2-6){
                memcpy(ttpos, tpos, sizeof(double)*2);
                ttpos[0] -= R*norm[0]; ttpos[1] -= R*norm[1];
                memcpy(traj+2*clen, tpos, sizeof(double)*2); clen += 1;
                memcpy(traj+2*clen, ttpos, sizeof(double)*2); clen += 1;
                memcpy(traj+2*clen, tpos, sizeof(double)*2); clen += 1;
            }*/
        }

        // if we are not doing constant interval saving, save the hit point
        if (!constant_interval){
            if (NT >= 0 && clen < NT/2-2){
                tlastsave = tlastbounce;
                memcpy(traj+2*clen, tpos, sizeof(double)*2);
                clen += 1;
            }
        }

        position(tpos, tvel, EPS, tpos); 
        velocity(tvel, EPS, tvel);
        tvel[0] *= damp;
        tvel[1] *= damp;
        tbounces++;
    }

    out->nbounces = tbounces;
    return 2*clen;
}

void apply_constraint(double *peg, double R, double *pos, double *norm){
    const double eps = 1e-14;
    double dist = 0.0;
    dist += (pos[0] - peg[0])*(pos[0] - peg[0]);
    dist += (pos[1] - peg[1])*(pos[1] - peg[1]);
    dist = sqrt(dist);

    double excess = dist - R - eps;
    pos[0] -= excess*norm[0];
    pos[1] -= excess*norm[1];
}

ullong vseed;
ullong vran;

void ran_seed(long j){
  vseed = j;  vran = 4101842887655102017LL;
  vran ^= vseed; 
  vran ^= vran >> 21; vran ^= vran << 35; vran ^= vran >> 4;
  vran = vran * 2685821657736338717LL;
}

double ran_ran2(){
    vran ^= vran >> 21; vran ^= vran << 35; vran ^= vran >> 4;
    ullong t = vran * 2685821657736338717LL;
    return 5.42101086242752217e-20*t;
}


