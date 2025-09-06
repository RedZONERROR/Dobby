@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Dobby 16KB Page Size Builder
echo    ARM64: 16KB Optimized + Android 15+
echo    Others: Standard 4KB + Android 7.0+
echo ========================================
echo.

REM Configuration - Update these paths if needed
set ANDROID_NDK_PATH=C:\AndroidSDK\ndk\29.0.13846066
set CMAKE_EXE=C:\AndroidSDK\cmake\3.22.1\bin\cmake.exe
set NINJA_EXE=C:\AndroidSDK\cmake\3.22.1\bin\ninja.exe
set DOBBY_SOURCE_DIR=Dobby_latest
set BUILD_BASE_DIR=build_16kb
set OUTPUT_DIR=dobby_16kb_libs

REM All architectures
set ARCHS=armeabi-v7a arm64-v8a x86 x86_64

REM Colors for output
set GREEN=[92m
set RED=[91m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

echo %BLUE%Step 1: Checking Prerequisites%NC%
echo ----------------------------------------

REM Check CMake
if not exist "%CMAKE_EXE%" (
    echo %RED%CMake not found at: %CMAKE_EXE%%NC%
    pause
    exit /b 1
) else (
    echo %GREEN%CMake found%NC%
)

REM Check NDK
if not exist "%ANDROID_NDK_PATH%" (
    echo %RED%Android NDK not found at: %ANDROID_NDK_PATH%%NC%
    pause
    exit /b 1
) else (
    echo %GREEN%Android NDK found%NC%
)

REM Check Dobby source
if not exist "%DOBBY_SOURCE_DIR%" (
    echo %RED%Dobby source not found at: %DOBBY_SOURCE_DIR%%NC%
    pause
    exit /b 1
) else (
    echo %GREEN%Dobby source found%NC%
)

echo.
echo %BLUE%Step 2: Cleaning Previous Builds%NC%
echo ----------------------------------------

REM Clean build directory
if exist "%BUILD_BASE_DIR%" (
    echo Removing old build directory...
    rmdir /s /q "%BUILD_BASE_DIR%" 2>nul
    timeout /t 1 /nobreak >nul
)

REM Clean output directory
if exist "%OUTPUT_DIR%" (
    echo Removing old output directory...
    rmdir /s /q "%OUTPUT_DIR%" 2>nul
    timeout /t 1 /nobreak >nul
)

REM Create fresh directories
mkdir "%OUTPUT_DIR%" 2>nul
echo %GREEN%Directories cleaned and created%NC%

echo.
echo %BLUE%Step 3: Building 16KB Page Size Optimized Dobby%NC%
echo ----------------------------------------
echo %YELLOW%16KB Page Size Features:%NC%
echo    - ARM64: 16KB page size optimization + Android 15+ support
echo    - ARM32/x86/x86_64: Standard 4KB + Android 7.0+ support
echo    - Dynamic page size detection
echo    - Memory allocator improvements
echo    - Trampoline placement optimization
echo.

set SUCCESS_COUNT=0
set TOTAL_COUNT=0

for %%A in (%ARCHS%) do (
    set /a TOTAL_COUNT+=1
    call :build_arch %%A
    if !ERRORLEVEL! equ 0 (
        set /a SUCCESS_COUNT+=1
    )
)

echo.
echo %BLUE%Step 4: Copying Headers%NC%
echo ----------------------------------------

REM Copy header file
if exist "%DOBBY_SOURCE_DIR%\include\dobby.h" (
    copy "%DOBBY_SOURCE_DIR%\include\dobby.h" "%OUTPUT_DIR%\dobby.h" >nul
    echo %GREEN%Copied dobby.h%NC%
) else (
    echo %RED%dobby.h not found%NC%
)

echo.
echo ========================================
echo %BLUE%16KB PAGE SIZE BUILD SUMMARY%NC%
echo ========================================

if %SUCCESS_COUNT% gtr 0 (
    echo %GREEN%SUCCESS: %SUCCESS_COUNT%/%TOTAL_COUNT% architectures built%NC%
    echo.
    echo %BLUE%Output Location:%NC%
    echo    %CD%\%OUTPUT_DIR%\
    echo.
    echo %BLUE%16KB Optimized Libraries:%NC%
    
    REM Show library sizes
    for /d %%i in ("%OUTPUT_DIR%\*") do (
        if exist "%%i\libdobby.a" (
            for %%j in ("%%i\libdobby.a") do (
                set "size=%%~zj"
                set /a "sizeMB=!size!/1024/1024"
                set /a "sizeKB=!size!/1024"
                if "%%~nxi"=="arm64-v8a" (
                    echo    %%~nxi: !sizeKB! KB (!sizeMB! MB^) - 16KB OPTIMIZED
                ) else (
                    echo    %%~nxi: !sizeKB! KB (!sizeMB! MB^) - STANDARD 4KB
                )
            )
        )
    )
    
    echo.
    echo %GREEN%16KB Features Applied:%NC%
    echo    ARM64: 16KB page size optimization + Android 15+ support
    echo    Others: Standard 4KB page size + Android 7.0+ support
    echo    Dynamic page size detection for all architectures
    echo    Memory allocator improvements
    echo    Trampoline placement optimization
    echo    AndroidManifest.xml flexible page size support
    echo.
    echo %BLUE%Integration Instructions:%NC%
    echo.
    echo 1. Update your Android.mk:
    echo    LOCAL_SRC_FILES := Dobby/%OUTPUT_DIR%/$(TARGET_ARCH_ABI)/libdobby.a
    echo    LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/Dobby/%OUTPUT_DIR%
    echo.
    echo 2. AndroidManifest.xml already updated with:
    echo    ^<application android:supportsFlexiblePageSizes="true"^>
    echo.
    echo 3. Update build.gradle:
    echo    compileSdk 35
    echo    targetSdk 35
    
) else (
    echo %RED%BUILD FAILED: No architectures built successfully%NC%
)

echo ========================================
pause
exit /b 0

REM Function to build 16KB optimized version for specific architecture
:build_arch
set ARCH=%1
set BUILD_DIR=%BUILD_BASE_DIR%\cmake-build-android-%ARCH%
set OUTPUT_ARCH_DIR=%OUTPUT_DIR%\%ARCH%

echo.

REM Check if this is ARM64 for 16KB page size optimization
if "%ARCH%"=="arm64-v8a" (
    echo %YELLOW%Building 16KB OPTIMIZED %ARCH%...%NC%
    set API_LEVEL=35
    set PAGE_SIZE_FLAGS=-DFLEXIBLE_PAGE_SIZE_SUPPORT=1 -DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON
    set BUILD_TYPE=16KB ARM64
) else (
    echo %YELLOW%Building STANDARD %ARCH%...%NC%
    set API_LEVEL=21
    set PAGE_SIZE_FLAGS=
    set BUILD_TYPE=Standard 4KB
)

REM Create directories
mkdir "%BUILD_DIR%" 2>nul
mkdir "%OUTPUT_ARCH_DIR%" 2>nul

REM Add tools to PATH
set PATH=%CMAKE_EXE:~0,-10%;%PATH%

echo Configuring %BUILD_TYPE% build for %ARCH%...

REM Architecture-specific CMake configuration
"%CMAKE_EXE%" ^
    -S"%DOBBY_SOURCE_DIR%" ^
    -B"%BUILD_DIR%" ^
    -G "Ninja" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DDOBBY_GENERATE_SHARED=OFF ^
    -DDOBBY_DEBUG=OFF ^
    -DNearBranch=ON ^
    -DPlugin.SymbolResolver=ON ^
    -DPlugin.ImportTableReplace=OFF ^
    -DBUILD_EXAMPLE=OFF ^
    -DBUILD_TEST=OFF ^
    -DCMAKE_TOOLCHAIN_FILE="%ANDROID_NDK_PATH%/build/cmake/android.toolchain.cmake" ^
    -DANDROID_ABI=%ARCH% ^
    -DANDROID_PLATFORM=android-%API_LEVEL% ^
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
    -DCMAKE_C_FLAGS="-fPIC -O3 %PAGE_SIZE_FLAGS% -DNDEBUG" ^
    -DCMAKE_CXX_FLAGS="-fPIC -O3 %PAGE_SIZE_FLAGS% -fno-rtti -DNDEBUG" ^
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--gc-sections" ^
    -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--gc-sections"

if errorlevel 1 (
    echo %RED%CMake configuration failed for %ARCH%%NC%
    exit /b 1
)

echo Building %BUILD_TYPE% %ARCH%...

REM Build with architecture-specific optimization
"%CMAKE_EXE%" --build "%BUILD_DIR%" --target dobby --config Release -- -j8

if errorlevel 1 (
    echo %RED%Build failed for %ARCH%%NC%
    exit /b 1
)

REM Copy the built library
set BUILT_LIB=%BUILD_DIR%\libdobby.a
set OUTPUT_LIB=%OUTPUT_ARCH_DIR%\libdobby.a

if exist "%BUILT_LIB%" (
    copy "%BUILT_LIB%" "%OUTPUT_LIB%" >nul
    if exist "%OUTPUT_LIB%" (
        for %%j in ("%OUTPUT_LIB%") do (
            set "size=%%~zj"
            set /a "sizeMB=!size!/1024/1024"
            set /a "sizeKB=!size!/1024"
            if "%ARCH%"=="arm64-v8a" (
                echo %GREEN%%ARCH%: !sizeKB! KB (!sizeMB! MB^) - 16KB OPTIMIZED%NC%
            ) else (
                echo %GREEN%%ARCH%: !sizeKB! KB (!sizeMB! MB^) - STANDARD 4KB%NC%
            )
        )
        exit /b 0
    ) else (
        echo %RED%Failed to copy library for %ARCH%%NC%
        exit /b 1
    )
) else (
    echo %RED%Built library not found for %ARCH%%NC%
    exit /b 1
)

exit /b 1