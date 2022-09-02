#!/bin/bash

sudo ./build.sh  BOARD=orangepizero2 BRANCH=current BUILD_OPT=image RELEASE=bullseye BUILD_MINIMAL=yes BUILD_DESKTOP=no KERNEL_CONFIGURE=no COMPRESS_OUTPUTIMAGE=sha,gpg,img
