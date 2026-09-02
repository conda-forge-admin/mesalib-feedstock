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

@REM Any Vulkan driver on Windows pulls in DirectX-Headers (see meson.build's
@REM "with_any_vk and host_machine.system() == 'windows'"), and meson always
@REM builds it from the vendored subproject because conda-forge's
@REM directx-headers ships no pkg-config file for dependency() to find.  The
@REM subproject then installs ~47 headers plus static libs that belong to the
@REM directx-headers package.  Mesa links what it needs statically, so drop the
@REM installed copies rather than clobber another package's files.
if exist %LIBRARY_PREFIX%\include\directx rmdir /s /q %LIBRARY_PREFIX%\include\directx
if exist %LIBRARY_PREFIX%\include\dxguids rmdir /s /q %LIBRARY_PREFIX%\include\dxguids
if exist %LIBRARY_PREFIX%\include\wsl rmdir /s /q %LIBRARY_PREFIX%\include\wsl
if exist %LIBRARY_PREFIX%\include\composition rmdir /s /q %LIBRARY_PREFIX%\include\composition
if exist %LIBRARY_PREFIX%\lib\libDirectX-Guids.a del %LIBRARY_PREFIX%\lib\libDirectX-Guids.a
if exist %LIBRARY_PREFIX%\lib\libd3dx12-format-properties.a del %LIBRARY_PREFIX%\lib\libd3dx12-format-properties.a
if exist %LIBRARY_PREFIX%\lib\pkgconfig\DirectX-Headers.pc del %LIBRARY_PREFIX%\lib\pkgconfig\DirectX-Headers.pc
