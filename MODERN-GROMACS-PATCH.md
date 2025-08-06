# SSAGES Modern GROMACS Support Patch

This patch enables SSAGES to build and work with modern GROMACS versions (2024.4+) by updating the integration to use the new gmxapi instead of the deprecated internal APIs.

## What This Patch Provides

### **Modern GROMACS Compatibility**
- Support for GROMACS 2024.4 and newer versions
- Uses the stable, public `gmxapi` instead of deprecated internal APIs
- Maintains backward compatibility with older GROMACS versions (5.1.x, 2016.x, 2018.x, 2019.x, 2020.x, 2021.x, 2022.x, 2023.x)

### **Key Technical Changes**
- **Driver.cpp**: Updated to use `gmxapi::fromTprFile()` and `gmxapi::Context` for modern GROMACS
- **CMakeLists.txt**: Improved GROMACS detection and library linking
- **FindGROMACS.cmake**: New CMake module for better GROMACS installation detection
- **C++17 Support**: Automatic detection and configuration for modern GROMACS requirements

### **Enhanced Build System**
- Better external GROMACS installation support
- Proper linking against both `libgromacs` and `libgmxapi`
- Improved include path detection
- CUDA/GCC compatibility flags

## Prerequisites

### System Requirements
- **GROMACS 2024.4+** installed with development headers
- **CMake 3.5+** 
- **C++ Compiler** with C++17 support (GCC 7+, Clang 5+)
- **MPI** (same requirement as before)

### GROMACS Installation
Your GROMACS installation should include:
- `libgromacs.so` - Core GROMACS library
- `libgmxapi.so` - Modern GROMACS API library 
- Header files in `include/gmxapi/` directory
- `pkgconfig/libgromacs.pc` file

**Verify your GROMACS installation:**
```bash
# Check GROMACS version
gmx --version

# Check for required libraries
ls $GROMACS_ROOT/lib/libgromacs.so
ls $GROMACS_ROOT/lib/libgmxapi.so

# Check for headers
ls $GROMACS_ROOT/include/gmxapi/gmxapi.h
```

## Installation Instructions

### 1. **Download and Apply Patch**

```bash
# Clone SSAGES (if not already done)
git clone https://github.com/SSAGESproject/SSAGES.git
cd SSAGES

# Apply the patch
git apply SSAGES-modern-GROMACS-support.patch

# Or if you have the patch file separately:
patch -p1 < SSAGES-modern-GROMACS-support.patch
```

### 2. **Build with External GROMACS**

```bash
# Create build directory
mkdir build && cd build

# Configure with external GROMACS installation
cmake .. \
  -DGROMACS=ON \
  -DUSE_EXTERNAL_GROMACS=ON \
  -DGROMACS_ROOT=/path/to/your/gromacs/installation

# Build
make -j$(nproc)
```

### 3. **Common GROMACS Installation Paths**

Replace `/path/to/your/gromacs/installation` with your actual GROMACS path:

- **Manual installation**: `/usr/local/gromacs`
- **Package manager**: `/usr` 
- **Module system**: Check with `module show gromacs`
- **Conda**: `$CONDA_PREFIX`

### 4. **Verify Installation**

```bash
# Check that ssages was built successfully
ls -la ssages

# Verify GROMACS libraries are linked
ldd ssages | grep -i gromacs
```

You should see output like:
```
libgmxapi.so.0 => /usr/local/gromacs/lib/libgmxapi.so.0
libgromacs.so.9 => /usr/local/gromacs/lib/libgromacs.so.9
```

## Usage with Modern GROMACS

### Key Changes in Usage
- **TPR File Required**: Modern GROMACS API requires a TPR file (use `-s` flag)
- **Workflow-Based**: Uses GROMACS workflow system instead of direct mdrun calls
- **Same JSON Interface**: SSAGES JSON configuration remains unchanged

### Example JSON Configuration
```json
{
  "input": [
    {
      "walker": 0,
      "args": "-s topol.tpr -deffnm output"
    }
  ],
  "methods": [
    {
      "type": "Umbrella",
      "ksprings": [10.0],
      "centers": [1.0]
    }
  ]
}
```

## Troubleshooting

### Build Issues

**Problem**: `gmxapi/gmxapi.h: No such file or directory`
```bash
# Solution: Check GROMACS installation includes development headers
ls $GROMACS_ROOT/include/gmxapi/
```

**Problem**: `undefined reference to gmxapi::fromTprFile`
```bash
# Solution: Ensure libgmxapi is available and linked
ls $GROMACS_ROOT/lib/libgmxapi.so
```

**Problem**: CMake can't find GROMACS
```bash
# Solution: Set GROMACS_ROOT explicitly
cmake .. -DGROMACS=ON -DUSE_EXTERNAL_GROMACS=ON -DGROMACS_ROOT=/your/gromacs/path
```

### Runtime Issues

**Problem**: "No TPR file specified in arguments"
```bash
# Solution: Ensure your SSAGES JSON includes -s flag with TPR file
"args": "-s your_system.tpr -deffnm output"
```

## What's Different from Legacy GROMACS

| Aspect | Legacy GROMACS (≤2023) | Modern GROMACS (2024.4+) |
|--------|------------------------|---------------------------|
| API | `CommandLineModuleManager` | `gmxapi` |
| Headers | `gromacs/commandline/...` | `gmxapi/...` |
| Libraries | `libgromacs` only | `libgromacs` + `libgmxapi` |
| C++ Standard | C++11/14 | C++17+ |
| Input Method | Command line args | TPR-based workflows |

## Compatibility Matrix

| GROMACS Version | Status | API Used |
|----------------|---------|----------|
| 5.1.x |  Supported | Legacy CommandLineModuleManager |
| 2016.x |  Supported | Legacy CommandLineModuleManager |
| 2018.x |  Supported | Legacy CommandLineModuleManager | 
| 2019.x |  Supported | Legacy CommandLineModuleManager |
| 2020.x-2023.x |  Supported | Legacy CommandLineModuleManager |
| 2024.4+ | Modern gmxapi |

## Contributing

If you encounter issues with this patch or want to contribute improvements:

1. **Report Issues**: Include GROMACS version, compiler version, and full error messages
2. **Test Coverage**: Help test with different GROMACS versions and build configurations
3. **Documentation**: Suggest improvements to installation instructions

## Acknowledgments

This patch was developed to modernize SSAGES for current and future GROMACS versions while maintaining backward compatibility. It enables SSAGES to take advantage of GROMACS 2024.4+ features including improved GPU support.

---
