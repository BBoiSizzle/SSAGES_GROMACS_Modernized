# SSAGES Modern GROMACS Support - Distribution Package

This package enables **SSAGES** to build and work with **modern GROMACS versions (2024.4+)** by updating the integration to use the stable `gmxapi` instead of deprecated internal APIs.

##  Package Contents

- **`SSAGES-modern-GROMACS-support.patch`** - The main patch file
- **`MODERN-GROMACS-PATCH.md`** - Comprehensive documentation and troubleshooting guide 
- **`install-modern-gromacs-support.sh`** - Automated installation script
- **`DISTRIBUTION-README.md`** - This file

##  Quick Start

### Prerequisites
- SSAGES source code (git clone from https://github.com/SSAGESproject/SSAGES.git)
- GROMACS 2024.4+ installed with development headers
- CMake 3.5+, C++ compiler with C++17 support

### Installation (Easy Way)
```bash
# 1. Copy patch files to your SSAGES source directory
cp SSAGES-modern-GROMACS-support.patch /path/to/SSAGES/
cp MODERN-GROMACS-PATCH.md /path/to/SSAGES/
cp install-modern-gromacs-support.sh /path/to/SSAGES/

# 2. Go to SSAGES directory and run installer
cd /path/to/SSAGES/
./install-modern-gromacs-support.sh

# 3. Build SSAGES
mkdir build && cd build
cmake .. -DGROMACS=ON -DUSE_EXTERNAL_GROMACS=ON -DGROMACS_ROOT=/path/to/gromacs
make -j$(nproc)
```

### Manual Installation
```bash
# Apply patch manually
cd /path/to/SSAGES/
git apply SSAGES-modern-GROMACS-support.patch

# Build as above
mkdir build && cd build
cmake .. -DGROMACS=ON -DUSE_EXTERNAL_GROMACS=ON -DGROMACS_ROOT=/path/to/gromacs
make -j$(nproc)
```

Why do this upgrade?

GROMACS 2024.4+ Support - Use latest GROMACS features and performance improvements
Backward Compatibility - Still works with older GROMACS versions (5.1.x - 2023.x)
Modern API - Uses stable, public `gmxapi` instead of deprecated internal APIs
GPU Enablement? - Still working on it, but setting up for atleast partial GPU acceleration
Future Proof - Probably compatible with upcoming GROMACS releases

Technical Details

The patch modifies these key files:
''hooks/gromacs/Driver.cpp` - Updates GROMACS integration to use modern gmxapi
''hooks/gromacs/CMakeLists.txt` - Improves build system and library linking
''cmake/Modules/FindGROMACS.cmake` - New module for better GROMACS detection
''CMakeLists.txt` - Minor build system improvements

## Full Documentation

See **`MODERN-GROMACS-PATCH.md`** for:
- Detailed installation instructions
- Troubleshooting guide
- Usage examples
- Compatibility matrix
- Technical details

## Support

If you encounter issues:

1. **Check Prerequisites**: Ensure GROMACS 2024.4+ is properly installed
2. **Read Documentation**: See `MODERN-GROMACS-PATCH.md` for troubleshooting
3. **Verify Installation**: 
   ```bash
   gmx --version  # Should show 2024.4+
   ls $GROMACS_ROOT/lib/libgmxapi.so  # Should exist
   ls $GROMACS_ROOT/include/gmxapi/gmxapi.h  # Should exist
   ```

##  Version Info

- **Patch Version**: 1.0
- **SSAGES Compatibility**: release-0.9.3 branch
- **GROMACS Support**: 2024.4+ (with backward compatibility)
- **Generated**: August 2025 with a ton of Claude Code assistance


