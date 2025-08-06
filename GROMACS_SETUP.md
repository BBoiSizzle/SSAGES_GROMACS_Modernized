# GROMACS Integration with SSAGES

SSAGES now supports modern GROMACS versions (2020+) alongside legacy versions. This document explains how to build SSAGES with different GROMACS installations.

## Quick Start

### Option 1: Use Existing GROMACS Installation (Recommended for Modern Versions)

For GROMACS 2020 and later, you can use an existing installation without patching:

```bash
cmake -DUSE_EXTERNAL_GROMACS=ON /path/to/ssages
make
```

SSAGES will automatically detect your GROMACS installation. You can help CMake find GROMACS by setting:

```bash
cmake -DUSE_EXTERNAL_GROMACS=ON -DGROMACS_ROOT=/path/to/gromacs /path/to/ssages
```

**Note**: This requires that GROMACS was built with:
- `BUILD_SHARED_LIBS=ON` 
- `GMX_MPI=ON` (for multi-walker simulations)
- `GMXAPI=ON` (for GROMACS 2022+, usually default)

### Option 2: Build Specific GROMACS Version

To build a specific version of GROMACS with SSAGES:

```bash
# For modern versions (2020+) - no patching required
cmake -DGROMACS=2024.4 /path/to/ssages
make

# For legacy versions - will use patches
cmake -DGROMACS=2018.6 /path/to/ssages
make
```

### Option 3: Use GROMACS Source Directory

```bash
cmake -DGROMACS_SRC=/path/to/gromacs/source /path/to/ssages
make
```

## Supported GROMACS Versions

### Modern Versions (No Patching Required)
- GROMACS 2020.x - 2025.x
- Built with C++17 standard
- Uses CMake find_package integration
- Compatible with existing installations

### Legacy Versions (Requires Patching)
- GROMACS 5.1.x
- GROMACS 2016.x 
- GROMACS 2018.x
- GROMACS 2019.x
- Built with C++11 standard
- Requires source modification via patches

## Technical Details

### C++ Standard Compatibility
- **GROMACS 2021+**: Requires C++17
- **GROMACS 2020**: Uses C++14
- **GROMACS <2020**: Uses C++11

SSAGES automatically detects and sets the appropriate C++ standard.

### CMake Options

| Option | Description | Default |
|--------|-------------|---------|
| `USE_EXTERNAL_GROMACS` | Use existing GROMACS installation | OFF |
| `GROMACS` | Download and build specific GROMACS version | - |
| `GROMACS_SRC` | Path to GROMACS source directory | - |
| `GROMACS_ROOT` | Path to GROMACS installation | - |
| `GMX_BUILD_OWN_FFTW` | Let GROMACS build its own FFTW | OFF |

### Environment Variables

You can also set these environment variables to help CMake find GROMACS:
- `GROMACS_ROOT` or `GMXHOME` or `GMX_HOME`

## Building Examples

### Modern GROMACS with External Installation
```bash
# Assuming GROMACS is installed in /usr/local/gromacs
export GROMACS_ROOT=/usr/local/gromacs
cmake -DUSE_EXTERNAL_GROMACS=ON /path/to/ssages
make -j$(nproc)
```

### Building Latest GROMACS from Source
```bash
cmake -DGROMACS=2024.4 /path/to/ssages
make -j$(nproc)
```

### Using Pre-existing GROMACS Source
```bash
# If you already have GROMACS source code
cmake -DGROMACS_SRC=/path/to/gromacs-2024.4 /path/to/ssages
make -j$(nproc)
```

## Troubleshooting

### GROMACS Not Found
If CMake cannot find your GROMACS installation:
1. Set `GROMACS_ROOT` environment variable
2. Use `-DGROMACS_ROOT=/path/to/gromacs` option
3. Ensure GROMACS was built with `BUILD_SHARED_LIBS=ON`

### Version Compatibility Issues
- For GROMACS 2020+: Use `USE_EXTERNAL_GROMACS=ON`
- For older versions: Use `GROMACS=version` to download with patches
- Check that your compiler supports the required C++ standard

### Build Errors
- Ensure GROMACS was built with MPI support if you need multi-walker simulations
- For GROMACS 2022+: Ensure `GMXAPI=ON` and `BUILD_SHARED_LIBS=ON`
- Modern GROMACS requires `GMX_BUILD_OWN_FFTW=OFF` for external linking

## Migration from Legacy Setup

If you were previously using SSAGES with older GROMACS versions:

1. **For GROMACS 2020+**: Switch to `USE_EXTERNAL_GROMACS=ON`
2. **Update your build scripts**: Remove manual patching steps
3. **Check C++ standard**: Ensure your compiler supports C++17 for GROMACS 2021+
4. **Verify MPI**: Ensure GROMACS was built with MPI support

This provides a smooth transition path while maintaining backward compatibility with existing GROMACS installations.

## What's New

The updated SSAGES build system now:

1. **Automatically detects GROMACS versions** - No more manual version specification for modern GROMACS
2. **Supports patch-free builds** - GROMACS 2020+ doesn't require source patching
3. **Flexible C++ standards** - Automatically uses C++17 for GROMACS 2021+
4. **Better error messages** - Clear feedback when GROMACS isn't found
5. **External installation support** - Use your existing GROMACS builds

### Version Detection

The build system uses multiple methods to detect GROMACS versions:

1. **Modern versions**: Reads `project(Gromacs VERSION x.y.z)` from CMakeLists.txt
2. **Legacy versions**: Uses gmxVersionInfo.cmake patterns
3. **Header files**: Checks version.h files as fallback
4. **Binary detection**: For installed versions

### Build Output Example

When building with GROMACS 2024.4, you'll see:
```
-- Detected GROMACS version: 2024.4
-- GROMACS 2024.4 detected - modern version, no patch required  
-- Using C++17 standard for GROMACS 2024.4
```

This indicates successful modern GROMACS integration without patching.
