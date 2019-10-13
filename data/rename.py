#! /usr/bin/env python3

import argparse, os

parser = argparse.ArgumentParser(description='Cleans CSV file names.')
parser.add_argument("file", nargs='+')
args = parser.parse_args()

for filename in args.file:
    path_to, name = os.path.split(filename)

    name = name.replace('Data - _', '')
    name = name.replace('_.csv', '.csv')
    new_filename = os.path.join(path_to, name)

    os.rename(filename, new_filename)
