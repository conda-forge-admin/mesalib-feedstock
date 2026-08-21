#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

MESA_PLATFORMS="x11"

# Every gallium driver named here is compiled into libgallium-${PKG_VERSION}.so,
# which this package ships.  iris (Intel Gen8+) is only useful where Intel GPUs
# exist, and pulling it in costs the CLC toolchain, so keep it to linux-64.
if [[ "${target_platform}" == "linux-64" ]]; then
  GALLIUM_DRIVERS="llvmpipe,iris"
else
  GALLIUM_DRIVERS="llvmpipe"
fi

if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" ]]; then
  if [[ "${CMAKE_CROSSCOMPILING_EMULATOR:-}" == "" ]]; then
    rm $PREFIX/bin/llvm-config
    cp $BUILD_PREFIX/bin/llvm-config $PREFIX/bin/llvm-config
    export LLVM_CONFIG=${PREFIX}/bin/llvm-config
  else
    export LLVM_CONFIG=${BUILD_PREFIX}/bin/llvm-config
  fi
fi

meson setup builddir/ \
  ${MESON_ARGS} \
  -Dplatforms=${MESA_PLATFORMS} \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dgallium-va=disabled \
  -Dgbm=enabled \
  -Dshared-glapi=enabled \
  -Dgallium-drivers=${GALLIUM_DRIVERS} \
  -Degl=enabled \
  -Dglvnd=enabled \
  -Dglx=dri \
  -Dllvm=enabled \
  -Dshared-llvm=enabled \
  -Dlibdir=lib \
  -Dvulkan-drivers= \
  -Dopengl=true \
  -Dglx-direct=true \
  || { cat builddir/meson-logs/meson-log.txt; exit 1; }

ninja -C builddir/ -j ${CPU_COUNT}

ninja -C builddir/ install

# The gallium "megadriver" model: every gallium driver selected above is
# compiled into libgallium-${PKG_VERSION}.so, and each <driver>_dri.so is just
# a symlink to the generic libdril_dri.so loader stub that names which driver
# to pick.  Those symlinks are what actually registers a driver with the DRI
# loader, so they are shipped by the per-driver packages (mesa-llvmpipe, ...)
# rather than by this one.  What is left here is the shared runtime.
rm -f $PREFIX/lib/dri/swrast_dri${SHLIB_EXT}
rm -f $PREFIX/lib/dri/kms_swrast_dri${SHLIB_EXT}
rm -f $PREFIX/lib/dri/iris_dri${SHLIB_EXT}

# 00-iris-defaults.conf stays here: it is inert app-workaround data that only
# has any effect once iris is actually registered, and mesa-iris ships nothing
# but the symlink, so it has no build of its own to take the file from.
