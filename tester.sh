#!/bin/bash

dub build -b release-debug || exit 1
gdb --ex 'run' --ex 'bt' ./fibersegfault
