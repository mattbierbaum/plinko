import sys

import numpy as np
import matplotlib.image
import subprocess

def calculate_cdf(image, number_bins=256*256):
    image_histogram, bins = np.histogram(image.flatten(), number_bins, density=True)
    cdf = image_histogram.cumsum()
    cdf = (number_bins-1) * cdf / cdf[-1]
    return cdf, bins

def image_histogram_equalization(image, cdf=None, bins=None, number_bins=256*256):
    if cdf is None:
        image_histogram, bins = np.histogram(image.flatten(), number_bins, density=True)
        cdf = image_histogram.cumsum()
        cdf = (number_bins-1) * cdf / cdf[-1]
    image_equalized = np.interp(image.flatten(), bins[:-1], cdf)
    return image_equalized.reshape(image.shape), cdf

def process_file(prefix):
    csv = np.loadtxt(prefix+'-shape.csv', delimiter=',').astype('int')
    arr = np.fromfile(prefix).astype('double').reshape(csv[2], csv[1], csv[0])
    cdf, bins = calculate_cdf(arr[-1])
    vmax = image_histogram_equalization(arr[-1], cdf=cdf, bins=bins)[0].max()

    for i in range(csv[2]):
        fn_literal = prefix + '-frame-%06d.png'
        fn_movie = prefix+'-out.mp4'
        fn = prefix+'-frame-%06d.png' % i
        data, _ = image_histogram_equalization(arr[i], cdf=cdf, bins=bins)
        matplotlib.image.imsave(fn, data, cmap='gray_r', vmax=vmax)

    cmd = f"ffmpeg -v warning -i {fn_literal} -tune stillimage -pix_fmt yuv420p -c:v libx264 -tune stillimage {fn_movie}"
    subprocess.run(cmd, shell=True)

if __name__ == '__main__':
    process_file(sys.argv[1])