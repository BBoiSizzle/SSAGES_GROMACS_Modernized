# CUDA/GCC Compatibility Solutions for SSAGES

This document provides solutions for the CUDA/GCC version compatibility issue when building SSAGES with GROMACS.

## Problem

CUDA 12.0 doesn't officially support GCC 13, causing build failures with:
```
error: #error -- unsupported GNU version! gcc versions later than 12 are not supported!
```

## Solutions (Choose One)

### Solution 1: Use GCC 12 (Recommended)

Your system has GCC 12 installed. Use it for the build:

```bash
# Clean any existing build
rm -rf build_test

# Build with GCC 12
export CC=gcc-12
export CXX=g++-12
mkdir build_test && cd build_test
cmake -DGROMACS_SRC=/home/ben/School/GROMACS/gromacs-2024.4 ..
make -j$(nproc)
```

### Solution 2: Force Allow Unsupported Compiler

Use the updated SSAGES build system that automatically adds `-allow-unsupported-compiler`:

```bash
# The updated CMake configuration should handle this automatically
mkdir build_test && cd build_test
cmake -DGROMACS_SRC=/home/ben/School/GROMACS/gromacs-2024.4 ..
make -j$(nproc)
```

If this still fails, you can manually set the flag:
```bash
export CUDAFLAGS="-allow-unsupported-compiler"
cmake -DGROMACS_SRC=/home/ben/School/GROMACS/gromacs-2024.4 ..
```

### Solution 3: Disable CUDA Support

If you don't need GPU acceleration:

```bash
mkdir build_test && cd build_test
cmake -DGROMACS_SRC=/home/ben/School/GROMACS/gromacs-2024.4 -DGMX_GPU=OFF ..
make -j$(nproc)
```

### Solution 4: Use Pre-built GROMACS

If you have GROMACS already installed (built with compatible GCC):

```bash
# Install GROMACS with package manager or use existing installation
cmake -DUSE_EXTERNAL_GROMACS=ON ..
make -j$(nproc)
```

## Testing the Fix

After choosing a solution, verify the build works:

```bash
# Test that SSAGES was built successfully
ls -la ssages
./ssages --help
```

## Recommended Approach

1. **First try Solution 1** (GCC 12) - most reliable
2. **If that fails, try Solution 2** (allow unsupported compiler)
3. **If GPU not needed, use Solution 3** (disable CUDA)

## Notes

- GCC 12 is the last officially supported version for CUDA 12.0
- The `-allow-unsupported-compiler` flag usually works but isn't guaranteed
- CUDA 12.1+ has better GCC 13 support
- Modern GROMACS versions handle CUDA compatibility better

## Updated CMake Configuration

The SSAGES build system now automatically:
- Detects GCC version incompatibilities
- Adds `-allow-unsupported-compiler` when needed
- Sets appropriate compiler flags
- Provides helpful warning messages

This should resolve most CUDA/GCC compatibility issues automatically.
