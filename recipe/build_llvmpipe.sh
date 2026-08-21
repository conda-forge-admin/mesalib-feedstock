#!/bin/bash

set -ex

# llvmpipe itself lives inside libgallium-${PKG_VERSION}.so, which is shipped by
# mesa-libgallium.  All this package does is register the software rasterizer
# with the DRI loader, by pointing the driver names at the generic loader stub.
# Keeping the registration separate is what lets mesa-libgallium be installed
# on its own, with a hardware driver instead of (or alongside) the software one.
test -f $PREFIX/lib/dri/libdril_dri${SHLIB_EXT}

ln -s libdril_dri${SHLIB_EXT} $PREFIX/lib/dri/swrast_dri${SHLIB_EXT}
ln -s libdril_dri${SHLIB_EXT} $PREFIX/lib/dri/kms_swrast_dri${SHLIB_EXT}
