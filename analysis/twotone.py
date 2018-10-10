import matplotlib.pyplot as pl
import re
import glob
import numpy as np

def prefix_twotone(prefix):
    g0 = glob.glob('{}.*color.npy'.format(prefix))[0]
    g1 = glob.glob('{}.*count.npy'.format(prefix))[0]
    return g0, g1

def plot_twotone(prefix, sigma=4, figsize=10):
    re_size = re.compile(r'{}\.(\d+)-(\d+)_([a-z]+).*'.format(prefix))
    f0, f1 = prefix_twotone(prefix)

    width, height, dtype = re_size.search(f0).groups()
    width = int(width)
    height = int(height)
    n_color = np.fromfile(f0, dtype=np.dtype(dtype)).reshape(height, width, 3)
    n_count = np.fromfile(f1, dtype=np.dtype(dtype)).reshape(height, width)

    clip = sigma * n_count[n_count > 0].std()
    n_count = np.clip(n_count, 0, clip)
    n_color = 1 - (1 - n_color)*(n_count / n_count.max())[...,None]

    if width > height:
        height = 10 * height / width
        width = 10
    if height >= width:
        width = 10 * width / height
        height = 10

    fig = pl.figure(figsize=(width, height))
    pl.imshow(n_color, origin='lower')
    pl.xticks([])
    pl.yticks([])
    pl.tight_layout()

def plot_indexed_colors(prefix, sigma=4, figsize=10, maps=['Blues', 'gray_r']):
    re_size = re.compile(r'{}\.(\d+)-(\d+)_([a-z]+).*'.format(prefix))
    f0 = glob.glob('{}.*count.npy'.format(prefix))[0]

    width, height, dtype = re_size.search(f0).groups()
    width = int(width)
    height = int(height)
    n = np.fromfile(f0, dtype=np.dtype(dtype)).reshape(height, width, -1)
    n = np.rollaxis(n, 2)

    clip = sigma * n[n > 0].std()
    n = np.clip(n, 0, clip)
    #n = 1 - (1 - n)*(n / n.max())

    if width > height:
        height = 10 * height / width
        width = 10
    if height >= width:
        width = 10 * width / height
        height = 10

    fig = pl.figure(figsize=(width, height))
    masked = []
    for i, t in enumerate(n):
        tmp = np.ma.masked_array(t, t == 0)
        pl.imshow(tmp, origin='lower', cmap=maps[i], alpha=1.0/len(n))

    pl.xticks([])
    pl.yticks([])
    pl.tight_layout()


