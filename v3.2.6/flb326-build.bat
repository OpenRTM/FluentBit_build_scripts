@echo off
@rem この実行で、Releaseビルドのバイナリが、
@rem デフォルト指定で「C:\localFLB」へインストールされる
@rem
@rem Releaseビルドは、build-releaseディレクトリを利用
@rem

set CMAKE_GENERATOR="Visual Studio 16 2019" 
set INSTALL_PREFIX=C:\localFLB
set FLB_VERSION=3.2.6
set FLB_ZIP=v%FLB_VERSION%.zip

@rem vcpkgのインストール先がデフォルト設定のままならば変更不要
set OPENSSL_ROOT_DIR=C:\vcpkg\installed\x64-windows-static

if exist %INSTALL_PREFIX% rmdir /s/q %INSTALL_PREFIX%

@rem パス中の "\" を "/" に変換する
set INSTALL_PREFIX_SLASH=%INSTALL_PREFIX:\=/%

if not exist %FLB_ZIP% (
  powershell wget -O %FLB_ZIP% https://github.com/fluent/fluent-bit/archive/refs/tags/%FLB_ZIP%
  powershell Expand-Archive .\%FLB_ZIP% -DestinationPath .\
)
cd fluent-bit-%FLB_VERSION%

set CMAKE_OPT=-DFLB_TRACE=Off ^
 -DFLB_EXAMPLES=Off ^
 -DFLB_OUT_KAFKA=On ^
 -DCMAKE_INSTALL_PREFIX=%INSTALL_PREFIX_SLASH% ^
 -G %CMAKE_GENERATOR% ^
 -A x64 ..
call :CMAKE_Release
call :COPY_HEADER_FILES
cd ..
exit /b

:CMAKE_Release
if exist build-release rmdir /s/q build-release
mkdir build-release
cd build-release
cmake %CMAKE_OPT%
cmake --build . --verbose --config Release
cmake --install .
cd ..
exit /b

:CMAKE_Debug
if exist build-debug rmdir /s/q build-debug
mkdir build-debug
cd build-debug
cmake %CMAKE_OPT%
cmake --build . --verbose --config Debug
cmake --install . --config Debug
cd ..
exit /b

:COPY_HEADER_FILES
powershell Copy-Item lib\monkey\include\monkey\mk_core\external -destination %INSTALL_PREFIX%\include\monkey\mk_core -recurs
powershell Copy-Item lib\monkey\mk_core\deps\libevent\include\*.h %INSTALL_PREFIX%\include
powershell Copy-Item lib\monkey\mk_core\deps\libevent\include\event2 -destination %INSTALL_PREFIX%\include -recurs
powershell Copy-Item build-release\lib\monkey\mk_core\deps\libevent\include\event2\event-config.h %INSTALL_PREFIX%\include\event2
powershell Copy-Item lib\msgpack-*\include\msgpack.h %INSTALL_PREFIX%\include
powershell Copy-Item lib\msgpack-*\include\msgpack -destination %INSTALL_PREFIX%\include -recurs
powershell Copy-Item lib\mbedtls-*\include\mbedtls -destination %INSTALL_PREFIX%\include -recurs
powershell Copy-Item lib\c-ares-*\include\*.h %INSTALL_PREFIX%\include
powershell Copy-Item build-release\lib\c-ares-*\ares_build.h %INSTALL_PREFIX%\include
powershell Copy-Item build-release\lib\c-ares-*\ares_config.h %INSTALL_PREFIX%\include
powershell Copy-Item lib\cmetrics\include\cmetrics %INSTALL_PREFIX%\include -recurs
powershell Copy-Item lib\cmetrics\include\prometheus_remote_write %INSTALL_PREFIX%\include -recurs
mkdir %INSTALL_PREFIX%\include\mk_core
powershell Copy-Item build-release\lib\monkey\include\monkey\mk_core\mk_core_info.h %INSTALL_PREFIX%\include\mk_core
powershell Copy-Item lib\cfl\include\cfl -destination %INSTALL_PREFIX%\include\cfl -recurs
powershell Copy-Item lib\cfl\lib\xxhash\*.h %INSTALL_PREFIX%\include\cfl
powershell Copy-Item lib\ctraces\include\ctraces -destination %INSTALL_PREFIX%\include\ctraces -recurs
powershell Copy-Item lib\ctraces\lib\mpack\src\mpack -destination %INSTALL_PREFIX%\include\mpack -recurs
mkdir %INSTALL_PREFIX%\lib\fluent-bit
powershell Copy-Item build-release\library\Release\fluent-bit.lib %INSTALL_PREFIX%\lib\fluent-bit
powershell Copy-Item lib\monkey\include\monkey\*.h %INSTALL_PREFIX%\include\monkey
powershell Copy-Item build-release\lib\monkey\include\monkey\mk_info.h %INSTALL_PREFIX%\include\monkey
mkdir %INSTALL_PREFIX%\deps\rbtree
powershell Copy-Item lib\monkey\deps\rbtree\rbtree.h %INSTALL_PREFIX%\deps\rbtree
mkdir %INSTALL_PREFIX%\include\nghttp2
powershell Copy-Item lib\nghttp2\lib\includes\nghttp2\nghttp2.h %INSTALL_PREFIX%\include\nghttp2
powershell Copy-Item build-release\lib\nghttp2\lib\includes\nghttp2\nghttp2ver.h %INSTALL_PREFIX%\include\nghttp2

exit /b
