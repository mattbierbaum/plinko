import os
import pandas
import time
import itertools
import multiprocessing
import numpy as np

import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as pl

def mkdirp(name):
    if not os.path.exists(name):
        os.mkdir(name)

def map_blocks_iter(xbds, ybds, zooms):
    """
    Returns (z, x, y), (x0, y0), (x1, y1)
    for each block in the maps
    """
    for zoom in range(zooms+1):
        divs = 1 << zoom
        xscale = float(np.diff(xbds)) / divs
        yscale = float(np.diff(ybds)) / divs

        for i in range(divs):
            for j in range(divs):
                x0 = xscale * i + xbds[0]
                y0 = ybds[1] - (yscale * (j+1))
                x1 = x0 + xscale
                y1 = y0 + yscale
                yield ((zoom, i, j), (x0, y0), (x1, y1))

def map_blocks(xbds, ybds, zooms):
    """
    Returns (z, x, y), (x0, y0), (x1, y1)
    for each block in the maps
    """
    out = None
    for zoom in range(zooms+1):
        divs = 1 << zoom
        xscale = np.diff(xbds) / divs
        yscale = np.diff(ybds) / divs

        ij = np.array(list(itertools.product(range(divs), range(divs))), dtype='float')
        i = ij[:,0]
        j = ij[:,1]
        z = np.array([zoom]*len(i))

        x0 = xscale * i + xbds[0]
        y0 = ybds[1] - (yscale * (j+1))
        x1 = x0 + xscale
        y1 = y0 + yscale

        t = np.vstack([z, i, j, x0, y0, x1, y1])
        if out is None:
            out = t
        else:
            out = np.vstack([out, t])
    return out

def map_line_parallel(filename, N, kwargs):
    proc = [
        multiprocessing.Process(target=_map_line, args=(i, N, filename, kwargs))
        for i in range(N)
    ]

    for p in proc:
        p.start()

    for p in proc:
        p.join()

def _map_line(i, N, filename, kwargs):
    line = pandas.read_csv(filename, delimiter=' ').values[:,:2]
    kwargs.update(regions=(i, N))
    map_line(line, **kwargs)

def map_line(line, out_folder='./data', lws=[0.005, 0.3], zooms=8, minzoom=None, regions=None):
    x = line[:, 0]
    y = line[:, 1]

    xbds = np.array([x.min(), x.max()])
    ybds = np.array([y.min(), y.max()])

    if np.diff(xbds) > np.diff(ybds):
        ybds[1] = ybds[0] + np.diff(xbds)
    elif np.diff(ybds) > np.diff(xbds):
        xbds[1] = xbds[0] + np.diff(ybds)

    mkdirp(out_folder)

    if isinstance(lws, (list, tuple)):
        lws = np.logspace(np.log2(lws[0]), np.log2(lws[1]), base=2, num=zooms+1)
    else:
        lws = [lws]*zooms

    fig, ax = pl.subplots(figsize=(10, 10))
    pl.show()
    axline = ax.plot(x, y, 'k-', lw=lws[0])[0]
    pl.axis('off')
    pl.subplots_adjust(0,0,1,1,0,0)

    rall = map_blocks_iter(xbds, ybds, zooms)
    regions = rall if not regions else itertools.islice(rall, regions[0], None, regions[1])

    for ind, p0, p1 in regions:
        z, x, y = ind
        x0, y0 = p0
        x1, y1 = p1

        if minzoom and z < minzoom:
            continue

        print(z, x, y)
        dir_z = os.path.join(out_folder, str(z))
        dir_x = os.path.join(dir_z, str(x))
        out = os.path.join(dir_x, str(y)+'.jpg')

        mkdirp(dir_z)
        mkdirp(dir_x)

        axline.set_linewidth(lws[z])
        ax.set_xlim([x0, x1])
        ax.set_ylim([y0, y1])
        pl.savefig(out, dpi=25.6)
