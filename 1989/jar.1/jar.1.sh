#!/usr/bin/env bash
# 'run' jar.1

# run/compile it
rm -f jar.1.o
cc jar.1.c -c
cat jar.1.o | strings
rm -f jar.1.o
