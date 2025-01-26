# Probe

CMake template for rapid prototyping and testing C++ code snippets.

## Features
- Auto-detects source files with `main()`
- Creates granular OBJECT libraries
- Integrated Clang-Formatting
- C++20 by default
- Cross-platform support

## Usage
```bash
cmake -B build
cmake --build build

cmake --build build --target check-format  # Format verification
cmake --build build --target format  # Auto-format code
```

## Project Structure
```
probe/
├─ CMakeLists.txt    # Main config
├─ cmake/            # Custom scripts
├─ include/          # Public headers
└─ source/           # Implementation & private headers
```
