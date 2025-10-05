def intt(x: str) -> int:
    """
    Convert binary string into integer, accepting `x` and `z` values.
    """
    try:
        return int(x, 2)
    except ValueError:
        return -1
