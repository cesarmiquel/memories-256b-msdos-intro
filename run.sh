#!/bin/bash

nasm memories-test.asm -fbin -o test.com
dosbox -conf dosbox-0.74-3.conf test.com
