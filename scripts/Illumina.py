#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
You can run it with python script.py input.fastq or python script.py input_1.fastq 
input2.fastq (the files must be uncompressed).

Date: 3 May 2018

@author: rvaser
"""

from __future__ import print_function
import sys

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def parse_file(file_name, read_set):
    line_id = 0
    name = ''
    data = ''
    qual = ''
    valid = False
    with (open(file_name)) as f:
        for line in f:
            if (line_id == 0):
                if (valid):
                    if (len(name) == 0 or len(data) == 0 or len(data) != len(qual)):
                        eprint('File is not in FASTQ format')
                        sys.exit(1)
                    valid = False
                    if (name in read_set):
                        print(name + '_2')
                    else:
                        read_set.add(name)
                        print(name + '_1')
                    print(data)
                    print('+')
                    print(qual)
                name = line.rstrip().split(' ')[0]
                data = ''
                qual = ''
                line_id = 1
            elif (line_id == 1):
                if (line[0] == '+'):
                    line_id = 2
                else:
                    data += line.rstrip()
            elif (line_id == 2):
                qual += line.rstrip()
                if (len(qual) >= len(data)):
                    valid = True
                    line_id = 0

    if (valid):
        if (len(name) == 0 or len(data) == 0 or len(data) != len(qual)):
            eprint(len(name), len(data), len(qual))
            eprint('File is not in FASTQ format')
            sys.exit(1)
        if (name in read_set):
           print(name + '_2')
        else:
           read_set.add(name)
           print(name + '_1')
        print(data)
        print('+')
        print(qual)

if __name__ == '__main__':

    read_set = set()

    if (len(sys.argv) > 1):
        parse_file(sys.argv[1], read_set)
    if (len(sys.argv) > 2):
        parse_file(sys.argv[2], read_set)