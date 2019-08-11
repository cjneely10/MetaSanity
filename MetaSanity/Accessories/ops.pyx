# cython: language_level=3

import os
from itertools import chain, islice


def get_prefix(path):
    """ Function for returning prefix from path

    :param path:
    :return:
    """
    return os.path.splitext(os.path.basename(str(path)))[0]


def chunk(iterable, int n):
    """ For parsing very large files

    :param n: (int) Chunk size
    :param iterable: (iter)	File iterable
    """
    iterable = iter(iterable)
    while True:
        yield chain([next(iterable)], islice(iterable, n - 1))
