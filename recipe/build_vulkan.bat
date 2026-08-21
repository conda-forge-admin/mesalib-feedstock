@echo on

echo MESON_ARGS are %MESON_ARGS%

@REM One Vulkan ICD per package: each statically links the Vulkan runtime it
@REM needs, so there is nothing to share between them and no reason to ship
@REM them together.  lavapipe is the software rasterizer; dzn (Dozen) runs
@REM Vulkan on top of D3D12, so it is hardware-backed and belongs in its own
@REM package rather than riding along inside mesa-lavapipe.
if "%PKG_NAME%"=="mesa-lavapipe" set VULKAN_DRIVERS=swrast
if "%PKG_NAME%"=="mesa-dzn" set VULKAN_DRIVERS=microsoft-experimental
if "%VULKAN_DRIVERS%"=="" (
  echo build_vulkan.bat has no vulkan-drivers mapping for %PKG_NAME%
  exit 1
)

@REM hmaarrfk - 2026/03
@REM I'm not sure why something is looking for this lib file
copy %LIBRARY_PREFIX%\lib\zstd.lib %LIBRARY_PREFIX%\lib\zstd.dll.lib

meson setup builddir ^
  %MESON_ARGS% ^
  -Dplatforms=windows ^
  -Dgles1=disabled ^
  -Dgles2=disabled ^
  -Dgallium-va=disabled ^
  -Dgbm=disabled ^
  -Dshared-glapi=enabled ^
  -Dgallium-drivers= ^
  -Degl=disabled ^
  -Dglx=disabled ^
  -Dllvm=enabled ^
  -Dvulkan-drivers=%VULKAN_DRIVERS% ^
  -Dopengl=true ^
  -Dglx-direct=false
if %ERRORLEVEL% neq 0 exit 1

@REM As of Aug 2025, LLVM doesn't not have support for shared libs on Windows
@REM See https://github.com/conda-forge/llvmdev-feedstock/issues/237
@REM -Dshared-llvm=enabled ^

meson compile -C builddir
if %ERRORLEVEL% neq 0 exit 1

ninja -C builddir install
if %ERRORLEVEL% neq 0 exit 1

@REM hmaarrfk - 2026/03
@REM I'm not sure why something is looking for this lib file
@REM Removed so it doesn't get included as part of the final package
del %LIBRARY_PREFIX%\lib\zstd.dll.lib
