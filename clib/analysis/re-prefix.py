import os
import sys
import glob

def rename(old, new):
    files = glob.glob('{}.*'.format(old))

    for fn_old in files:
        postfix = '.'.join(fn_old.split('.')[1:])
        fn_new = '{}.{}'.format(new, postfix)

        os.rename(fn_old, fn_new)

if __name__ == '__main__':
    old, new = sys.argv[1], sys.argv[2]
    rename(old, new)
