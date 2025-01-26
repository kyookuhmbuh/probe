# Probe

CMake template for rapid prototyping and testing C++ code snippets.

## Features
- Auto-detects source files with `main()`
- Creates granular OBJECT libraries
- Integrated Clang-Formatting
- C++20 by default
- Cross-platform support
- **Per-target configuration** via `.cmake` files
- Automatic reconfiguration on file changes

## Usage
### Configure the project and build all targets
```bash
cmake -B build
cmake --build build
```
### Format verification
```bash
cmake --build build --target check-format
```
### Auto-format code
```bash
cmake --build build --target format
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

### Configuration Files (`source/`)
- **`<name>.cmake`**: Per-target configuration.
  - Automatically loaded if a file with the same base name as the source file exists.
  - Example: `app.cpp` → `app.cmake`.
  - Use this to add custom `target_link_libraries`, `target_compile_definitions`, etc.
  - Files and directories starting with `_` are **ignored** (e.g., `_internal.cpp`, `_private/`).

## Example
### Source File (`source/app.cpp`)
```cpp
#include <iostream>

#ifdef MY_CUSTOM_DEFINE
    // ...
#endif

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
```
### Configuration File (`source/app.cmake`)
```cmake
# Link additional libraries
target_link_libraries(${CURRENT_TARGET} 
    PRIVATE 
    Threads::Threads
)

# Add compile definitions
target_compile_definitions(${CURRENT_TARGET}
    PRIVATE
    -DMY_CUSTOM_DEFINE
)
```