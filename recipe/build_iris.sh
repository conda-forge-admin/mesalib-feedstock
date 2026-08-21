#!/bin/bash

set -ex

# iris (the Intel Gen8+ OpenGL driver) lives inside libgallium-${PKG_VERSION}.so,
# which is shipped by mesa-libgallium.  All this package does is register it with
# the DRI loader, the same way mesa-llvmpipe registers the software rasterizer.
# Installing it next to mesa-libgallium is enough for an application in this
# prefix to pick up this Mesa instead of the system one -- the glvnd vendor
# manifests name libEGL_mesa.so.0 / libGLX_mesa.so.0 by soname, so the loader
# resolves them out of the environment's lib directory.
test -f $PREFIX/lib/dri/libdril_dri${SHLIB_EXT}

ln -s libdril_dri${SHLIB_EXT} $PREFIX/lib/dri/iris_dri${SHLIB_EXT}
