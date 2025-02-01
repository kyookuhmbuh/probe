# Probe

CMake template for rapid prototyping and testing C++ code snippets.

## Features
- Auto-detects source files with `main()`
- Creates granular OBJECT libraries
- Integrated Clang-Formatting
- C++20 by default
- Cross-platform support
- **Per-target compile definitions** via `.cfg` files
- Automatic reconfiguration on file changes
- Automatic code formating before building

## Usage
### Configure the project and build all targets
```bash
cmake -B build
cmake --build build
```

## Project Structure
```
probe/
├─ CMakeLists.txt    # Main CMake configuration
├─ cmake/            # Custom CMake scripts and modules
├─ include/          # Public headers (visible to all targets)
└─ source/           # Implementation & private headers
```

## File Types and Their Roles
### Public Headers (`include/`)
- **`*.h` / `*.hpp`**: Public headers (visible to all targets and external projects).

### Source Files (`source/`)
- **`*.cpp`**: Implementation files.
  - Files containing `main()` are built as **executables**.
  - Files without `main()` are compiled into **OBJECT libraries**.
- **`*.h` / `*.hpp`**: Private headers (visible only within `source/`).
- Files and directories starting with `_` are **ignored** (e.g., `_internal.cpp`, `_private/`).

### Configuration Files (`source/`)
- **`<name>.cfg`**: Per-target compile definitions.
  - Automatically loaded if a file with the same base name as the source file exists.
  - Example: `app.cpp` → `app.cfg`.

## Example
### Source File (`source/app.cpp`)
```cpp
#include <iostream>

int main()
{
#ifdef MY_CUSTOM_DEFINE
  std::cout << "Hello, World!\n";
#endif
  return 0;
}
```
### Configuration File (`source/app.cfg`)
```cfg
MY_CUSTOM_DEFINE=1
```
