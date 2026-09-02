#!/bin/bash

set -ex

# Every gallium driver lives inside libgallium-${PKG_VERSION}.so, shipped by
# mesa-libgallium.  A driver becomes usable when a symlink named after it
# appears in lib/dri next to the generic libdril_dri.so loader stub -- that
# name is the whole registration mechanism.  So each of these packages is
# nothing but its symlinks, and installing one alongside mesa-libgallium is
# what makes that one backing available, and only that one.

case "${PKG_NAME}" in
  mesa-llvmpipe)
    # "swrast" is the DRI name llvmpipe registers under; kms_swrast is the
    # same driver reached through a KMS dumb buffer.
    DRI_NAMES="swrast kms_swrast"
    ;;
  mesa-iris)   DRI_NAMES="iris" ;;      # Intel Gen8+
  mesa-crocus) DRI_NAMES="crocus" ;;    # Intel Gen4-7
  mesa-i915)   DRI_NAMES="i915" ;;      # Intel Gen2-3
  mesa-nouveau) DRI_NAMES="nouveau" ;;  # NVIDIA, open
  mesa-r300)   DRI_NAMES="r300" ;;      # AMD R300-R500
  mesa-r600)   DRI_NAMES="r600" ;;      # AMD R600-Evergreen
  mesa-svga)   DRI_NAMES="vmwgfx" ;;    # VMware guest
  mesa-virgl)  DRI_NAMES="virtio_gpu" ;; # virtio-gpu guest
  mesa-d3d12)  DRI_NAMES="d3d12" ;;     # D3D12, i.e. WSL
  mesa-zink)
    # zink renders GL through whatever Vulkan driver is installed.  Enabling it
    # is also what turns on mesa's "KMS render-only" support, so it owns the
    # display-only KMS device names too -- see with_gallium_kmsro in mesa's
    # meson.build and the dril_drivers table in
    # src/gallium/targets/dril/meson.build.
    DRI_NAMES="zink
      apple armada-drm exynos gm12u320 hdlcd hx8357d ili9163 ili9225 ili9341
      ili9486 imx-drm imx-dcss imx-lcdif ingenic-drm kirin komeda mali-dp mcde
      mediatek meson mi0283qt mxsfb-drm panel-mipi-dbi pl111 rcar-du repaper
      rockchip rzg2l-du ssd130x st7586 st7735r sti stm sun4i-drm udl vkms
      zynqmp-dpsub"
    ;;
  *)
    echo "build_dri_links.sh has no driver name mapping for ${PKG_NAME}" >&2
    exit 1
    ;;
esac

test -f $PREFIX/lib/dri/libdril_dri${SHLIB_EXT}

for name in ${DRI_NAMES}; do
  ln -s libdril_dri${SHLIB_EXT} $PREFIX/lib/dri/${name}_dri${SHLIB_EXT}
done
