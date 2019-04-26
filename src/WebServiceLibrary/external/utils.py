import random


def generate_id():
    """ Generates a random ID 
    
    Generates a random ID based on the input string and current time and outputs a string in the
    format AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE whereby each character is a hex.    
    """


    _random = '%030x' % random.randrange(16**32)

    return '{0}-{1}-{2}-{3}-{4}'.format(_random[:8],
                                        _random[8:12],
                                        _random[12:16],
                                        _random[16:20],
                                        _random[20:])


