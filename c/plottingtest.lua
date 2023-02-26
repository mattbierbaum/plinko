local plotting = require('plotting')

density = plotting.create_density(0, 1, 2, 3, 1000)
plotting.draw_segment(density, 0, 1.2, 1.9, 2.8)
normed = plotting.eq_hist(density, 10)
plotting.save_csv(density, 'test.bin')
print(density)
