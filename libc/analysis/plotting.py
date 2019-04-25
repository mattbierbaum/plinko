import numpy as np
import scipy as sp
import pylab as pl
import matplotlib
#matplotlib.rcParams['savefig.dpi'] = 300
matplotlib.rcParams['agg.path.chunksize'] = 10000

from matplotlib.collections import LineCollection
import yaml
import os
import time
import re
import glob

def load(base):
    conf = yaml.load(open(base+".conf"))
    pegs = np.fromfile(base+".pegs",  dtype='float')
    pegs = pegs.reshape(pegs.shape[0]//2, 2)

    if os.path.exists(base+'.density'):
        track = np.fromfile(base+".density", dtype='float')
        track = track.reshape(-1, conf['timepoints']+1, 2)
    elif os.path.exists(base+'.track'):
        track = np.fromfile(base+".track", dtype='float')
        track = track.reshape(track.shape[0]//2, 2)

    return conf, track, pegs

def hist(tracks, conf, bins=500):
    bins = (bins*np.array([conf['top']/conf['wall'], 1.0])).astype('int')
    h,_,_ = np.histogram2d(tracks[:,1:,1].flatten(), tracks[:,1:,0].flatten(), bins=bins)
    h[0,0] = 0
    return h

def density_hist(base, bins=500):
    """
    Complete density of all tracks plotted at the same time using a histogram (coarse grained)
    """
    conf, track, pegs = load(base)

    h = hist(track, conf, bins)
    pl.imshow(np.log(h+1), cmap=pl.cm.bone, interpolation='nearest', origin='lower')

def density_hist_movie(base, bins=500, skip=1, frames=500, size=10):
    """
    A movie of the hist2d plots of hte trajectories
    """
    conf, track, pegs = load(base)

    nbins = (bins*np.array([conf['top']/conf['wall'], 1.0])).astype('int')
    bins = [np.linspace(0, conf['top'], nbins[0]),
            np.linspace(0, conf['wall'], nbins[1])]

    fig = pl.figure(figsize=(size,size*conf['top']/conf['wall']))

    for t in range(max(frames, track.shape[1]/skip)):
        tmp = track[:,t*skip+1,:]
        h,_,_ = np.histogram2d(tmp[:,1].flatten(), tmp[:,0].flatten(), bins=bins)
        h[0,0] = 0

        pl.imshow(h, cmap=pl.cm.bone, interpolation='nearest', origin='lower')
        pl.xticks([])
        pl.yticks([])
        pl.tight_layout()
        pl.savefig(base+'-movie-%05d.png' % t)

def tracks_movie(base, skip=1, frames=500, size=10):
    """
    A movie of each particle as a point
    """
    conf, track, pegs = load(base)

    fig = pl.figure(figsize=(size,size*conf['top']/conf['wall']))
    plot = None

    for t in range(1,max(frames, track.shape[1]/skip)):
        tmp = track[:,t*skip,:]
        if not ((tmp[:,0] > 0) & (tmp[:,1] > 0) & (tmp[:,0] < conf['wall']) & (tmp[:,1] < conf['top'])).any():
            continue

        if plot is None:
            plot = pl.plot(tmp[:,0], tmp[:,1], 'k,', alpha=1.0, ms=0.1)[0]
            pl.xticks([])
            pl.yticks([])
            pl.xlim(0,conf['wall'])
            pl.ylim(0,conf['top'])
            pl.tight_layout()
        else:
            plot.set_xdata(tmp[:,0])
            plot.set_ydata(tmp[:,1])
        pl.draw()
        pl.savefig(base+'-movie-%05d.png' % (t-1))

def plot_density(base, thin=False, start=0, size=14, save=False):
    conf, track, pegs = load(base)

    linethick = 2*0.0125 if thin else 0.3
    fig = pl.figure(figsize=(size,size*conf['top']/conf['wall']))

    for i in range(conf['nparticles']):
        if i % int(1e4) == 0:
            print(i)

        l = int(track[i,0,0])
        pl.plot(track[i,1:l-2,0], track[i,1:l-2,1], 'k-', linewidth=linethick, alpha=0.01)

    pl.xlim(0, conf['wall'])
    pl.ylim(0, conf['top'])
    pl.show()
    pl.xticks([])
    pl.yticks([])
    pl.tight_layout()
    return track

def plot_track(base, thin=True, start=0, size=10, save=False, showpegs=True, lw=None):
    conf, track, pegs = load(base)

    linethick = lw if lw else 0.0125 if thin else 0.3

    fig = pl.figure(figsize=(size,size*conf['top']/conf['wall']))

    if showpegs:
        for peg in pegs:
            pl.gca().add_artist(pl.Circle(peg, conf['radius'], ec='w', fc='k', alpha=0.0, lw=0.0))
            pl.gca().add_artist(pl.Circle(peg, conf['radius'], ec='k', fill=False, alpha=0.8, lw=1.0))

    pl.plot(track[:,0], track[:,1], '-', c='k', linewidth=linethick, alpha=0.8)
    pl.xlim(0, conf['wall'])
    pl.ylim(0, conf['top'])
    pl.show()
    pl.xticks([])
    pl.yticks([])
    pl.tight_layout()
    if save:
        pl.savefig(base+".png", dpi=200)

def plot_track_color(base, thin=True, start=0, size=14, save=False):
    conf, track, pegs = load(base)

    fig = pl.figure(figsize=(size,size*conf['top']/conf['wall']))

    track = track[start:]
    x = track[:,0];   y = track[:,1]
    t = np.linspace(0,1,x.shape[0])
    points = np.array([x,y]).transpose().reshape(-1,1,2)
    segs = np.concatenate([points[:-1],points[1:]],axis=1)
    lc = LineCollection(segs, linewidths=0.25, cmap=pl.cm.coolwarm)
    lc.set_array(t)
    pl.gca().add_collection(lc)

    #pl.scatter(x, y, c=np.arange(len(x)),linestyle='-',cmap=pl.cm.coolwarm)
    #pl.plot(track[-1000000:,0], track[-1000000:,1], '-', linewidth=0.0125, alpha=0.8)
    for peg in pegs:
        pl.gca().add_artist(pl.Circle(peg, conf['radius'], color='k', alpha=0.3))
    pl.xlim(0, conf['wall'])
    pl.ylim(0, conf['top'])
    pl.xticks([])
    pl.yticks([])
    pl.tight_layout()
    pl.show()
    if save:
        pl.savefig(base+".png", dpi=200)

def plot_y(base):
    conf, track, pegs = load(base)
    pl.figure(figsize=(6,6))
    pl.plot(track[:,1], lw=1)


# ============================================================================
# plotting functions for densities
# ============================================================================
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


"""
plot_file('small', True)

h = np.fromfile("./stats/real-damped.track", dtype='float')
a = pl.hist(abs(h-3.5), bins=1000, histtype='step', linewidth=0.2)
pl.xlim(0,3.5)
pl.semilogy()

h = np.fromfile("./bounces/test.track", dtype='float')
print yaml.load(open("./bounces/test.conf"))
print h.std()
a = pl.hist(h[h < h.std()/500], bins=400, histtype='step', linewidth=0.3)
"""
