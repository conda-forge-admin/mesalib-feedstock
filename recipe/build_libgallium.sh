#!/bin/bash

set -ex

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

MESA_PLATFORMS="x11"

# Every gallium driver named here is compiled into libgallium-${PKG_VERSION}.so,
# which this package ships.  The per-driver packages (mesa-iris, mesa-zink, ...)
# add nothing but the lib/dri symlink that registers one of them with the DRI
# loader, so this list is what decides which of those packages can exist.
#
# Kept off the list on purpose:
#   radeonsi / radv  need libdrm >= 2.4.133; conda-forge is on 2.4.129.
#   nouveau vulkan   (NVK) needs cbindgen, which conda-forge does not package.
#   softpipe         has no lib/dri name of its own -- it shares "swrast" with
#                    llvmpipe and is only reachable via GALLIUM_DRIVER, so it
#                    could not be installed independently anyway.
if [[ "${target_platform}" == "linux-64" ]]; then
  GALLIUM_DRIVERS="llvmpipe,iris,crocus,i915,nouveau,r300,r600,zink,virgl,svga,d3d12"
else
  GALLIUM_DRIVERS="llvmpipe,zink,virgl"
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
  -Dvideo-codecs= \
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

# The gallium "megadriver" model: each <driver>_dri.so is only a symlink to the
# generic libdril_dri.so loader stub, and the symlink's *name* is what tells the
# loader which driver to pick.  Those symlinks are the per-driver packages'
# entire contents, so strip every one of them here and keep the stub.
find $PREFIX/lib/dri -type l -name "*_dri${SHLIB_EXT}" -delete
test -f $PREFIX/lib/dri/libdril_dri${SHLIB_EXT}

# The per-driver drirc snippets stay: they are inert app-workaround data that
# only takes effect once the matching driver is registered, and the per-driver
# packages have no build of their own to take the files from.
