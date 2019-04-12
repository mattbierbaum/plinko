import os
import numpy as np
import matplotlib.pyplot as pl

def mkdirp(name):
    if not os.path.exists(name):
        os.mkdir(name)

def map_blocks(xbds, ybds, zooms):
    """
    Returns (z, x, y), (x0, y0), (x1, y1)
    for each block in the maps
    """
    for zoom in range(zooms+1):
        divs = 1 << zoom
        xscale = np.diff(xbds) / divs
        yscale = np.diff(ybds) / divs

        for i in range(divs):
            for j in range(divs):
                x0 = xscale * i + xbds[0]
                y0 = ybds[1] - (yscale * (j+1))
                x1 = x0 + xscale
                y1 = y0 + yscale

                yield ((zoom, i, j), (x0, y0), (x1, y1))

def map_line(line, out_folder='./data', lws=[0.005, 0.3], zooms=8):
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
        lws = np.logspace(np.log2(lws[0]), np.log2(lws[1]), base=2, num=zooms)
    else:
        lws = [lws]*zooms

    fig, ax = pl.subplots(figsize=(10, 10))
    axline = ax.plot(x, y, 'k-', lw=lws[0])[0]
    pl.axis('off')
    pl.subplots_adjust(0,0,1,1,0,0)

    for ind, p0, p1 in map_blocks(xbds, ybds, zooms):
        z, x, y = ind
        x0, y0 = p0
        x1, y1 = p1

        print(z, x, y)
        dir_z = os.path.join(out_folder, str(z))
        dir_x = os.path.join(dir_z, str(x))
        out = os.path.join(dir_x, str(y)+'.png')

        mkdirp(dir_z)
        mkdirp(dir_x)

        axline.set_linewidth(lws[z])
        ax.set_xlim([x0, x1])
        ax.set_ylim([y0, y1])
        pl.savefig(out, dpi=25.6)
