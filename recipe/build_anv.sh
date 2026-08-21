#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

# anv, the Intel Vulkan driver.  Unlike the gallium drivers this is a
# self-contained ICD -- libvulkan_intel.so statically links the Vulkan runtime
# it needs -- so it gets its own meson configuration rather than sharing
# libgallium.  LLVM is required even though anv does not use it at runtime:
# the Intel drivers compile their internal OpenCL C kernels with mesa-clc at
# build time, which needs clang and the SPIR-V/LLVM translator.
meson setup builddir/ \
  ${MESON_ARGS} \
  -Dplatforms=x11 \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dgallium-va=disabled \
  -Dgbm=disabled \
  -Dshared-glapi=enabled \
  -Dgallium-drivers= \
  -Degl=disabled \
  -Dglx=disabled \
  -Dllvm=enabled \
  -Dshared-llvm=enabled \
  -Dlibdir=lib \
  -Dvulkan-drivers=intel \
  -Dopengl=true \
  -Dglx-direct=false \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install
