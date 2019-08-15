#!/bin/bash

dub build -b release || exit 1
gdb --ex 'run' --ex 'bt' ./fibersegfault
