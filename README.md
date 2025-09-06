# Dobby

A lightweight hooking framework for runtime code manipulation.

## Features

- Multi-platform support (Android, iOS, macOS, Linux)
- Multi-architecture (ARM64, ARM32, x86, x86_64)
- 16KB page size optimization for Android 15+
- Function hooking and code patching
- Symbol resolution

## Usage

```cpp
#include "dobby.h"

// Hook a function
void* target = dlsym(RTLD_DEFAULT, "target_function");
DobbyHook(target, (void*)hook_function, (void**)&original_function);

// Patch code
uint8_t patch[] = {0x90, 0x90}; // NOP
DobbyCodePatch(patch_addr, patch, sizeof(patch));
```

## Build

```bash
cmake -B build
cmake --build build
```

## Credits

Based on the original Dobby framework with contributions from:
- [frida-gum](https://github.com/frida/frida-gum)
- [minhook](https://github.com/TsudaKageyu/minhook)
- [substrate](https://github.com/jevinskie/substrate)
- [v8](https://github.com/v8/v8)
- [dart](https://github.com/dart-lang/sdk)
- [vixl](https://git.linaro.org/arm/vixl.git)