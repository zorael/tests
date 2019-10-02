#!/bin/sh

dub build --compiler=ldc && \
    gdb --ex "set confirm off" --ex run --ex bt --ex quit ./tests
