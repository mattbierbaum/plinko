import numpy as np
import scipy as sp
import pylab as pl
import matplotlib
#matplotlib.rcParams['savefig.dpi'] = 2 * matplotlib.rcParams['savefig.dpi']

def plot_file(base):
    track = np.fromfile(base+".track", dtype='float')
    pegs =  np.fromfile(base+".pegs",  dtype='float')
    track = track.reshape(track.shape[0]/2, 2)
    pegs = pegs.reshape(pegs.shape[0]/2, 2)
    
    fig = pl.figure(figsize=(6,6*10./7))
    for peg in pegs:
        pl.gca().add_artist(pl.Circle(peg, 0.75/2, color='k', alpha=0.3))
    pl.plot(track[:,0], track[:,1], '-', linewidth=0.25)
    pl.xlim(0, 7)
    pl.ylim(0, 10)
    pl.show()

"""
plot_file('test2')
h = np.fromfile("./test.track", dtype='float')
a = hist(h, bins=2000, histtype='step')
xlim(0,7)
"""
