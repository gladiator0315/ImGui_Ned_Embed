@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ===== Settings =====
set "GEN=Visual Studio 17 2022"
set "ARCH=x64"
set "CONFIG=Release"
set "NED_PATH=ned"
set "LOG=build_log.txt"

:: ===== Sanity Checks =====
if not exist "CMakeLists.txt" (
    echo [ERROR] Run this from the project root.
    exit /b 1
)

if not exist "%NED_PATH%\CMakeLists.txt" (
    echo [ERROR] Missing submodule folder: %NED_PATH%
    exit /b 1
)

set "LUAU_SRC=%CD%\%NED_PATH%\servers\luau-lsp\current\win-x64\luau-lsp.exe"
if not exist "%LUAU_SRC%" (
    echo [ERROR] Bundled Luau server missing:
    echo         %LUAU_SRC%
    echo         Put luau-lsp.exe there or fix the copy path in CMake.
    exit /b 1
)

:: ===== Clean & Configure =====
if exist "build" rmdir /s /q "build"
mkdir "build"
cd "build" || (
    echo [ERROR] Failed to enter build directory.
    exit /b 1
)

@echo off
echo === CMake Configure ===

powershell -NoProfile -Command ^
  "cmake -G 'Visual Studio 17 2022' -A x64 -DCMAKE_TOOLCHAIN_FILE='%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake' -DNED_USE_LSP_STUBS=OFF .. 2>&1 | Tee-Object -FilePath '%LOG%' -Append; exit $LASTEXITCODE"


if %ERRORLEVEL% neq 0 (
    echo [CONFIGURE ERROR]
    exit /b 1
)

:: ===== Build =====
echo === Build %CONFIG% ===
powershell -NoProfile -Command ^
  "cmake --build . --config '%CONFIG%' -- /m /v:m 2>&1 | Tee-Object -FilePath '%LOG%' -Append; exit $LASTEXITCODE"

:: ===== Verify Luau LSP Copy =====
set "OUT=%CD%\%CONFIG%\servers\luau-lsp\current\win-x64\luau-lsp.exe"
if not exist "%OUT%" (
    echo [ERROR] Post-build copy of luau-lsp.exe missing:
    echo         %OUT%
    echo         Check the add_custom_command in your CMakeLists for target ImGuiDemo/ned.
    echo Full log: %CD%\%LOG%
    exit /b 1
)

endlocal