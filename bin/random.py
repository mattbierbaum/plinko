import os
import copy
import random
import shlex
import numpy as np
from subprocess import check_call

def rand_bin():
    return (random.random() > 0.5)

def rand_float(xmin, xmax):
    return random.random()*(xmax - xmin) + xmin

def rand_log(xmin, xmax):
    t = random.random()*(np.log10(xmax) - np.log10(xmin)) + np.log10(xmin)
    return 10**t

def rand_logint(xmin, xmax):
    return int(rand_log(xmin, xmax))

def rand_int(xmin, xmax):
    return random.randint(xmin, xmax)

def concentric(seed):
    random.seed(seed)

    g = rand_log(1e-4, 1)
    R = rand_log(1e-3, 0.98)
    d = rand_bin() and 1.0 or rand_log(0.3, 1)
    t = rand_logint(1e4, 3e7)
    N = rand_logint(2, 1e4)
    H = rand_logint(1, 100)
    offset = rand_float(0, 2*np.pi)
    rand = rand_float(0, 2*np.pi)

    p = '{},{}'.format(rand_float(0, 1), rand_float(0, 1))
    v = '{},{}'.format(rand_float(0, 1), rand_float(0, 1))

    values = copy.deepcopy(locals())
    params = ' '.join([
        '{}{} {}'.format('-'*np.clip(len(i), 1, 2), i, values[i])
        for i in (list('gRdtNHpv') + ['offset', 'rand'])
    ])

    cmd = 'plinko exec concentric -- {} -r 720 -o concentric-{:04d}.pgm'
    cmd = shlex.split(cmd.format(params, seed))

    check_call(cmd)
