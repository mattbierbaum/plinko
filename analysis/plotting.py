import numpy as np
import scipy as sp
import pylab as pl
import matplotlib
#matplotlib.rcParams['savefig.dpi'] = 2 * matplotlib.rcParams['savefig.dpi']
from matplotlib.collections import LineCollection
import yaml

def density_hist(base):
    conf = yaml.load(open(base+".conf"))
    track = np.fromfile(base+".density", dtype='float')
    pegs =  np.fromfile(base+".pegs",  dtype='float')

    track = track.reshape(-1, conf['timepoints']+1, 2)
    pegs = pegs.reshape(pegs.shape[0]/2, 2)

    h,_,_ = np.histogram2d(t[:,1:,0].flatten(), t[:,1:,1].flatten(), bins=100)
    h[0,0] = 0
    pl.imshow(h, cmap=cm.bone, interpolation='nearest')

def plot_density(base, thin=False, start=0, size=14, save=False):
    conf = yaml.load(open(base+".conf"))
    track = np.fromfile(base+".density", dtype='float')
    pegs =  np.fromfile(base+".pegs",  dtype='float')

    track = track.reshape(-1, conf['timepoints']+1, 2)
    pegs = pegs.reshape(pegs.shape[0]/2, 2)

    linethick = 2*0.0125 if thin else 0.3
    fig = pl.figure(figsize=(size,size*10./conf['wall']))

    for i in xrange(conf['nparticles']):
        l = int(track[i,0,0])
        pl.plot(track[i,1:l-2,0], track[i,1:l-2,1], 'k-', linewidth=linethick, alpha=0.01)

    pl.xlim(0, conf['wall'])
    pl.ylim(0, 10)
    pl.show()
    pl.xticks([])
    pl.yticks([])
    pl.tight_layout()
    return track

def plot_file(base, thin=True, start=0, size=14, save=False):
    conf = yaml.load(open(base+".conf"))
    track = np.fromfile(base+".track", dtype='float')
    pegs =  np.fromfile(base+".pegs",  dtype='float')

    track = track.reshape(track.shape[0]/2, 2)[start:]
    pegs = pegs.reshape(pegs.shape[0]/2, 2)

    linethick = 0.0125 if thin else 0.3

    fig = pl.figure(figsize=(size,size*10./conf['wall']))
    for peg in pegs:
        pl.gca().add_artist(pl.Circle(peg, conf['radius'], color='k', alpha=0.3))

    pl.plot(track[:,0], track[:,1], '-', linewidth=linethick, alpha=0.8)
    pl.xlim(0, conf['wall'])
    pl.ylim(0, 10)
    pl.show()
    pl.xticks([])
    pl.yticks([])
    pl.tight_layout()
    if save:
        pl.savefig(base+".png", dpi=200)

def plot_file_color(base, thin=True, start=0, size=14, save=False):
    conf = yaml.load(open(base+".conf"))
    track = np.fromfile(base+".track", dtype='float')
    pegs =  np.fromfile(base+".pegs",  dtype='float')
    track = track.reshape(track.shape[0]/2, 2)
    pegs = pegs.reshape(pegs.shape[0]/2, 2)

    fig = pl.figure(figsize=(size,size*10./conf['wall']))

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
    pl.ylim(0, 10)
    pl.xticks([])
    pl.yticks([])
    pl.tight_layout()
    pl.show()
    if save:
        pl.savefig(base+".png", dpi=200)

def plot_y(base):
    conf = yaml.load(open(base+".conf"))
    track = np.fromfile(base+".track", dtype='float')
    pegs =  np.fromfile(base+".pegs",  dtype='float')

    track = track.reshape(track.shape[0]/2, 2)#[-100000:]
    pl.figure(figsize=(6,6))
    pl.plot(track[:,1])

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
