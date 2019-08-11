# cython: language_level=3
from operator import itemgetter

"""
Functions handle simple range operations
Primarily works with data in the form ((int, int),)
for given ((start, end),) coordinates

"""


def reduce_span(list coords_list):
    """ Function will reduce ranges into tuple of non-overlapping ranges

    :param coords_list: [(int, int),]    Tuple/List of start/end coordinates
    :return ((int,int),):
    """
    # Sort coordinates by start value
    cdef list ranges_in_coords = sorted(coords_list, key=itemgetter(0))
    # Will group together matching sections into spans
    # Return list of these spans at end
    # Initialize current span and list to return
    cdef list spans_in_coords = [list(ranges_in_coords[0]), ]
    cdef tuple coords
    for coords in ranges_in_coords[1:]:
        # The start value is within the farthest range of current span
        # and the end value extends past the current span
        if coords[0] <= spans_in_coords[-1][1] < coords[1]:
            spans_in_coords[-1][1] = coords[1]
        # The start value is past the range of the current span
        # Append old span to list to return
        # Reset current span to this new range
        elif coords[0] > spans_in_coords[-1][1]:
            spans_in_coords.append(list(coords))
    return tuple(map(tuple, spans_in_coords))


def gaps(list coords_list, int gap_size=1):
    """ Function will locate uncovered portions between ranges

    :param gap_size: (int)  Return gaps of size or larger
    :param coords_list: [(int, int),]   Tuple/List of start/end coordinates
    :return ((int, int),):
    """
    # Reduce list of coordinates to ranges
    cdef tuple coords_span = reduce_span(coords_list)
    cdef int i
    # Return gaps in between ranges if they are at least the gap size
    return tuple((coords_span[i][1] + 1, coords_span[i + 1][0] - 1) for i in range(len(coords_span) - 1)
                 # Add 1 to difference to include single-unit gaps
                 if (coords_span[i + 1][0] - 1) - (coords_span[i][1] + 1) + 1 >= gap_size)
