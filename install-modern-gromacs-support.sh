#!/bin/bash
# SSAGES Modern GROMACS Support Installation Script
# This script applies the patch to enable SSAGES compatibility with GROMACS 2024.4+

set -e  # Exit on any error

echo "SSAGES Modern GROMACS Support Installer"
echo "=============================================="

# Check if we're in a SSAGES directory
if [[ ! -f "CMakeLists.txt" ]] || [[ ! -d "hooks/gromacs" ]]; then
    echo "Error: This doesn't appear to be a SSAGES source directory."
    echo "Please run this script from the root of your SSAGES source tree."
    exit 1
fi

# Check if patch file exists
if [[ ! -f "SSAGES-modern-GROMACS-support.patch" ]]; then
    echo "Error: Patch file 'SSAGES-modern-GROMACS-support.patch' not found."
    echo "Please ensure the patch file is in the current directory."
    exit 1
fi

# Check git status
echo "Checking git status..."
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: This is not a git repository. Please use git clone to get SSAGES."
    exit 1
fi

# Warn about uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo " Warning: You have uncommitted changes in your repository."
    echo "The patch will be applied anyway, but you may want to commit or stash your changes first."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted by user."
        exit 1
    fi
fi

# Apply the patch
echo "Applying modern GROMACS support patch..."
if git apply SSAGES-modern-GROMACS-support.patch; then
    echo " Patch applied successfully!"
else
    echo " Error: Failed to apply patch. This might be because:"
    echo "   - The patch has already been applied"
    echo "   - Your SSAGES version is incompatible"
    echo "   - You have conflicting local changes"
    exit 1
fi

# Display next steps
echo ""
echo " SSAGES Modern GROMACS Support installed successfully!"
echo ""
echo " Next Steps:"
echo "1. Ensure you have GROMACS 2024.4+ installed with development headers"
echo "2. Create a build directory: mkdir build && cd build"
echo "3. Configure with: cmake .. -DGROMACS=ON -DUSE_EXTERNAL_GROMACS=ON -DGROMACS_ROOT=/path/to/gromacs"
echo "4. Build with: make -j\$(nproc)"
echo ""
echo " For detailed instructions, see: MODERN-GROMACS-PATCH.md"
echo ""
echo "  To verify your GROMACS installation:"
echo "   gmx --version"
echo "   ls \$GROMACS_ROOT/lib/libgmxapi.so"
echo "   ls \$GROMACS_ROOT/include/gmxapi/gmxapi.h"
