import os
import copy
import random
import shlex
import numpy as np
from subprocess import check_call
from multiprocessing import Pool

def rand_bin():
    return (random.random() > 0.5)

def rand_float(xmin, xmax):
    return random.random()*(xmax - xmin) + xmin

def rand_log(xmin, xmax):
    t = random.random()*(np.log10(xmax) - np.log10(xmin)) + np.log10(xmin)
    return 10**t

def rand_exp(xmin, xmax, scale=3, right=True):
    t = np.clip(-np.log10(1 - random.random()) * (xmax-xmin)/scale + xmin, xmin, xmax)
    return right and (xmax - t + xmin) or t

def rand_logint(xmin, xmax):
    return int(rand_log(xmin, xmax))

def rand_int(xmin, xmax):
    return random.randint(xmin, xmax)

def concentric(seed, resolution=720, outdir='/dev/shm', svg=False, overwrite=False):
    fn_pgm = os.path.join(outdir, 'concentric-{:04d}.pgm'.format(seed))
    fn_png = os.path.join(outdir, 'concentric-{:04d}.png'.format(seed))
    fn_svg = os.path.join(outdir, 'concentric-{:04d}.svg'.format(seed))

    if not overwrite and any([os.path.exists(f) for f in [fn_pgm, fn_png, fn_svg]]):
        print("Output already exists")
        return

    random.seed(seed)
    g = rand_log(1e-4, 1)
    R = rand_log(1e-3, 0.98)
    d = rand_bin() and 1.0 or rand_exp(0.99, 1.0, scale=12, right=True)
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

    fn = svg and fn_svg or fn_pgm
    cmd = 'plinko exec concentric -- {} -r {} -o {}'
    cmd = shlex.split(cmd.format(params, resolution, fn))
    print(' '.join(cmd))

    cvt = 'convert {} {}'
    cvt = shlex.split(cvt.format(fn, fn_png))

    try:
        print(seed)
        check_call(cmd)

        if not svg:
            check_call(cvt)
    except Exception as e:
        print('{}: {}'.format(seed, e))

def parallel(func, processes=30, jobs=1000, seeds=None):
    pool = Pool(processes)
    jobs = list(range(jobs)) if seeds is None else seeds
    pool.map(func, jobs)

#if __name__ == '__main__':
#    parallel(concentric)
