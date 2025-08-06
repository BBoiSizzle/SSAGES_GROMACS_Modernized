# List of supported versions of GROMACS
set (SUPPORTED_GROMACS_VERSIONS
      "5.1"  "5.1.0"  "5.1.1"  "5.1.2"  "5.1.3"  "5.1.4"  "5.1.5"
     "2016" "2016.0" "2016.1" "2016.2" "2016.3" "2016.4" "2016.5"
     "2018" "2018.0" "2018.1" "2018.2" "2018.3" "2018.4" "2018.5" "2018.6" "2018.7"
     "2019" "2019.0" "2019.1" "2019.2" "2019.3" "2019.4" "2019.5" "2019.6"
     "2020" "2020.0" "2020.1" "2020.2" "2020.3" "2020.4" "2020.5" "2020.6"
     "2021" "2021.0" "2021.1" "2021.2" "2021.3" "2021.4" "2021.5"
     "2022" "2022.0" "2022.1" "2022.2" "2022.3" "2022.4" "2022.5"
     "2023" "2023.0" "2023.1" "2023.2" "2023.3"
     "2024" "2024.0" "2024.1" "2024.2" "2024.3" "2024.4"
     "2025" "2025.0" "2025.1" "2025.2"
    )

set(GMX_BUILD_OWN_FFTW OFF CACHE BOOL "Let GROMACS build its own libfftw.")
set(USE_EXTERNAL_GROMACS OFF CACHE BOOL "Use existing GROMACS installation instead of building from source.")
set(GMX_GPU "OFF" CACHE STRING "GPU acceleration support (OFF, CUDA, OpenCL, SYCL)")

# Try to find existing GROMACS installation first
if (USE_EXTERNAL_GROMACS OR (NOT GROMACS_SRC AND NOT GROMACS))
    find_package(GROMACS QUIET)
    if (GROMACS_FOUND)
        set(USE_EXTERNAL_GROMACS ON)
        message(STATUS "Found existing GROMACS installation: ${GROMACS_VERSION}")
        
        # Set variables for compatibility
        set(GROMACS_VERSION ${GROMACS_VERSION})
        set(GROMACS_SRC "")
        
        # Modern GROMACS versions (2020+) don't need patching
        if (GROMACS_VERSION VERSION_GREATER_EQUAL "2020")
            set(GMX_PATCH "")
            message(STATUS "Using modern GROMACS (${GROMACS_VERSION}) - no patching required")
        else()
            message(WARNING "Found GROMACS ${GROMACS_VERSION} but patches may be needed for older versions")
        endif()
    endif()
endif()

if (GROMACS_SRC AND NOT USE_EXTERNAL_GROMACS)
    # Get absolute path in case user specified relative path
    if (IS_ABSOLUTE ${GROMACS_SRC})
        get_filename_component(GROMACS_SRC ${GROMACS_SRC} ABSOLUTE)
    else (IS_ABSOLUTE ${GROMACS_SRC})
        get_filename_component(GROMACS_SRC ${PROJECT_BINARY_DIR}/${GROMACS_SRC}
                                ABSOLUTE)
    endif (IS_ABSOLUTE ${GROMACS_SRC})

    # Check if directory GROMACS_SRC exists
    if (NOT EXISTS ${GROMACS_SRC})
        message (FATAL_ERROR "\nERROR: Directory ${GROMACS_SRC} does not exist.")
    endif (NOT EXISTS ${GROMACS_SRC})

    # Check if directory contains GROMACS source files
    # Look for files that exist in different GROMACS versions
    set(GROMACS_MARKER_FILES
        "src/gmxpre.h"                          # Legacy versions
        "src/gromacs/version.h"                 # Modern versions
        "api/legacy/include/gromacs/version.h"  # Very recent versions
        "cmake/gmxVersionInfo.cmake"            # All versions should have this
    )
    
    set(GROMACS_FOUND_MARKER FALSE)
    foreach(MARKER_FILE ${GROMACS_MARKER_FILES})
        if (EXISTS ${GROMACS_SRC}/${MARKER_FILE})
            set(GROMACS_FOUND_MARKER TRUE)
            break()
        endif()
    endforeach()
    
    if (NOT GROMACS_FOUND_MARKER)
        # Check if subdirectory was specified
        foreach(MARKER_FILE ${GROMACS_MARKER_FILES})
            if (EXISTS ${GROMACS_SRC}/${MARKER_FILE})
                get_filename_component (GROMACS_SRC ${GROMACS_SRC}/.. ABSOLUTE)
                set(GROMACS_FOUND_MARKER TRUE)
                break()
            endif()
        endforeach()
        
        if (NOT GROMACS_FOUND_MARKER)
            # Directory does not contain GROMACS source
            message (FATAL_ERROR "\nERROR: Directory ${GROMACS_SRC} does not "
                                    "contain GROMACS source files. Expected one of: "
                                    "${GROMACS_MARKER_FILES}")
        endif()
    endif()

    # Get GROMACS version using multiple methods
    set(GROMACS_VERSION "Version not found")
    
    # Method 1: Try cmake/gmxVersionInfo.cmake (most versions)
    set(GROMACS_VERSION_INFO ${GROMACS_SRC}/cmake/gmxVersionInfo.cmake)
    if (EXISTS ${GROMACS_VERSION_INFO})
        execute_process (
            COMMAND "sed" "-n"
            "s/set(GMX_VERSION_\\(MAJOR\\|MINOR\\|PATCH\\) \\([0-9]\\+\\))/\\2/p"
            "${GROMACS_SRC}/cmake/gmxVersionInfo.cmake"
            COMMAND "sed" "-e" ":a" "-e" "N" "-e" "\$!ba" "-e" "s/\\n/./g"
            OUTPUT_VARIABLE GROMACS_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif()
    
    # Method 2: Try CMakeLists.txt for newer versions (project(Gromacs VERSION x.y.z))
    if(GROMACS_VERSION STREQUAL "Version not found" OR GROMACS_VERSION STREQUAL "")
        if(EXISTS ${GROMACS_SRC}/CMakeLists.txt)
            execute_process(
                COMMAND "grep" "-E" "project\\(Gromacs VERSION" "${GROMACS_SRC}/CMakeLists.txt"
                COMMAND "sed" "s/.*project(Gromacs VERSION \\([0-9][0-9.]*\\).*/\\1/"
                OUTPUT_VARIABLE GROMACS_VERSION
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
        endif()
    endif()
    
    # Method 2b: Try old-style CMakeLists.txt version definitions
    if(GROMACS_VERSION STREQUAL "Version not found" OR GROMACS_VERSION STREQUAL "")
        if(EXISTS ${GROMACS_SRC}/CMakeLists.txt)
            execute_process(
                COMMAND "grep" "-E" "set\\(GMX_VERSION_(MAJOR|MINOR|PATCH)" "${GROMACS_SRC}/CMakeLists.txt"
                COMMAND "sed" "s/.*set(GMX_VERSION_[A-Z]* \\([0-9]*\\).*/\\1/"
                COMMAND "tr" "\\n" "."
                COMMAND "sed" "s/\\.$//g"
                OUTPUT_VARIABLE GROMACS_VERSION
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
        endif()
    endif()
    
    # Method 3: Try version.h files
    if(GROMACS_VERSION STREQUAL "Version not found" OR GROMACS_VERSION STREQUAL "")
        set(VERSION_HEADERS
            "${GROMACS_SRC}/src/gromacs/version.h"
            "${GROMACS_SRC}/api/legacy/include/gromacs/version.h"
        )
        foreach(VERSION_HEADER ${VERSION_HEADERS})
            if(EXISTS ${VERSION_HEADER})
                file(READ ${VERSION_HEADER} VERSION_CONTENT)
                string(REGEX MATCH "#define GMX_VERSION \"([0-9]+\\.[0-9]+[^\"]*)" VERSION_MATCH "${VERSION_CONTENT}")
                if(VERSION_MATCH)
                    set(GROMACS_VERSION ${CMAKE_MATCH_1})
                    break()
                endif()
            endif()
        endforeach()
    endif()
    
    # Fallback for very old versions
    if(GROMACS_VERSION STREQUAL "Version not found" OR GROMACS_VERSION STREQUAL "")
        set(GROMACS_VERSION "legacy")
        message(WARNING "Could not determine GROMACS version, assuming legacy version")
    endif()
    
    message(STATUS "Detected GROMACS version: ${GROMACS_VERSION}")
    
    # Check if GROMACS version is supported (be more permissive for modern versions)
    if (NOT ";${SUPPORTED_GROMACS_VERSIONS};" MATCHES ";${GROMACS_VERSION};" AND GROMACS_VERSION VERSION_LESS "2020")
        message (WARNING "\nWARNING: GROMACS version \"${GROMACS_VERSION}\" may not be fully tested with SSAGES. "
                         "Modern versions (2020+) are supported without patching.")
    endif()

    # Set the appropriate patch.
    if (GROMACS_VERSION MATCHES "^5\\.1(\\.[0-9]+)?$")
        set (GMX_PATCH "gmx_diff_5.1.x.patch")
    elseif (GROMACS_VERSION MATCHES "^2016(\\.[0-9]+)?$")
        set (GMX_PATCH "gmx_diff_2016.x.patch")
    elseif (GROMACS_VERSION MATCHES "^2018(\\.[0-3])?$")
        set (GMX_PATCH "gmx_diff_2018.x.patch")
    elseif (GROMACS_VERSION MATCHES "^2018(\\.[4-9])?$")
        set (GMX_PATCH "gmx_diff_2018.y.patch")
    elseif (GROMACS_VERSION MATCHES "^2019(\\.[0-9])?$")
        set (GMX_PATCH "gmx_diff_2019.x.patch")
    elseif (GROMACS_VERSION VERSION_GREATER_EQUAL "2020")
        set (GMX_PATCH "")
        message (STATUS "GROMACS ${GROMACS_VERSION} detected - modern version, no patch required")
    else ()
        message (WARNING "\nWARNING: Could not find GROMACS version specific patch. "
                           "Attempting not to use one.")
        set (GMX_PATCH "")
    endif ()

    # Check that files to be patched do exist (only if patch is required)
    if (GMX_PATCH AND NOT GMX_PATCH STREQUAL "")
        execute_process (COMMAND "sed" "-n"
                                    "s/^.*gromacs-ssages\\/\\([^t]*\\)\t.*/\\1/p"
                                    "${PROJECT_SOURCE_DIR}/hooks/gromacs/${GMX_PATCH}"
                            COMMAND "sed" "-e" ":a" "-e" "N" "-e" "\$!ba" "-e" "s/\\n/;/g"
                            OUTPUT_VARIABLE GROMACS_FILES_TO_BE_PATCHED
                            OUTPUT_STRIP_TRAILING_WHITESPACE)

        foreach (PATCH_FILE ${GROMACS_FILES_TO_BE_PATCHED})
            if (NOT EXISTS ${GROMACS_SRC}/${PATCH_FILE})
                message (FATAL_ERROR "\nERROR: File ${PATCH_FILE} does not exist.\n"
                                        "This error is probably caused by an unsupported "
                                        "version of GROMACS.")
            endif (NOT EXISTS ${GROMACS_SRC}/${PATCH_FILE})
        endforeach ()
    endif()
elseif (GROMACS AND NOT USE_EXTERNAL_GROMACS)
    set (GROMACS_VERSION ${GROMACS})

    # Strip the trailing ".0" for downloading
    if (GROMACS_VERSION MATCHES "^[0-9\\.]+\\.0$")
        string (REGEX REPLACE "^([0-9\\.]+)\\.0$" "\\1" GROMACS_VERSION ${GROMACS_VERSION})
    endif ()

    # Check if GROMACS version is supported, otherwise use modern default
    if (NOT ";${SUPPORTED_GROMACS_VERSIONS};" MATCHES ";${GROMACS_VERSION};")
        # Default to a recent stable version for better compatibility
        set (GROMACS_VERSION 2024.4)
        message (STATUS "\n-- Using modern default version of GROMACS (${GROMACS_VERSION}).\n-- ")
    endif ()

    # Set the appropriate patch.
    if (GROMACS_VERSION MATCHES "^5\\.1(\\.[0-9]+)?$")
        set (GMX_PATCH "gmx_diff_5.1.x.patch")
    elseif (GROMACS_VERSION MATCHES "^2016(\\.[0-9]+)?$")
        set (GMX_PATCH "gmx_diff_2016.x.patch")
    elseif (GROMACS_VERSION MATCHES "^2018(\\.[0-3])?$")
        set (GMX_PATCH "gmx_diff_2018.x.patch")
    elseif (GROMACS_VERSION MATCHES "^2018(\\.[4-9])?$")
        set (GMX_PATCH "gmx_diff_2018.y.patch")
    elseif (GROMACS_VERSION MATCHES "^2019(\\.[0-9])?$")
        set (GMX_PATCH "gmx_diff_2019.x.patch")
    elseif (GROMACS_VERSION VERSION_GREATER_EQUAL "2020")
        set (GMX_PATCH "")
        message (STATUS "GROMACS ${GROMACS_VERSION} detected - modern version, no patch required")
    else ()
        message (WARNING "\nWARNING: Could not find GROMACS version specific patch. "
                           "Attempting to use modern approach without patching.")
        set (GMX_PATCH "")
    endif ()

    ExternalProject_Add(
        gromacs-download
        DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
        GIT_REPOSITORY https://gitlab.com/gromacs/gromacs.git
        GIT_TAG v${GROMACS_VERSION}
        TIMEOUT 600
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
    )
    set (GROMACS_SRC "${CMAKE_CURRENT_BINARY_DIR}/gromacs-download-prefix/src/gromacs-download")
endif ()

set (GROMACS_SRC ${GROMACS_SRC} PARENT_SCOPE)
set (GROMACS_VERSION ${GROMACS_VERSION} PARENT_SCOPE)
set (MD_ENGINE_VERSION "GROMACS version ${GROMACS_VERSION}" PARENT_SCOPE)

# Set C++ standard based on GROMACS version
if (GROMACS_VERSION VERSION_GREATER_EQUAL "2021")
    set (GROMACS_CXX_STANDARD "c++17")
    message(STATUS "Using C++17 standard for GROMACS ${GROMACS_VERSION}")
else()
    set (GROMACS_CXX_STANDARD "c++11")
endif()

set (GRO_CXX_ARGS "-std=${GROMACS_CXX_STANDARD} -I${PROJECT_SOURCE_DIR}/src -I${PROJECT_SOURCE_DIR}/include -I${CMAKE_CURRENT_SOURCE_DIR}")
set (CUDA_NVCC_FLAGS_LIST
    "-std=${GROMACS_CXX_STANDARD}"
    "-I${PROJECT_SOURCE_DIR}/src"
    "-I${PROJECT_SOURCE_DIR}/include" 
    "-I${CMAKE_CURRENT_SOURCE_DIR}"
)

# Handle GCC version compatibility with CUDA
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER "12.0")
        message(STATUS "GCC ${CMAKE_CXX_COMPILER_VERSION} detected with CUDA - adding compatibility flags")
        list(APPEND CUDA_NVCC_FLAGS_LIST "-allow-unsupported-compiler")
        set(GRO_CXX_ARGS "${GRO_CXX_ARGS} -Wno-error")
    endif()
endif()

# Convert list to semicolon-separated string
string(REPLACE ";" " " CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS_LIST}")

if (GROMACS_VERSION MATCHES "^5\\.1(\\.[0-9]+)?$" OR GROMACS_VERSION MATCHES "^2016(\\.[0-9]+)?$")
    set (GMX_LIBRARIES_ARGS "-DGMX_EXTRA_LIBRARIES=$<TARGET_FILE:libssages>")
else ()
    set (GMX_LIBRARIES_ARGS "-DGMX_COMMON_LIBRARIES=$<TARGET_FILE:libssages>")
endif ()

# If a SIMD level is set, turn off hwloc
if (GMX_SIMD)
    set (GMX_SIMD_FLAGS "-DGMX_HWLOC=OFF;-DGMX_SIMD=${GMX_SIMD}")
endif ()

# Configure patch (only for versions that need it).
if (GMX_PATCH AND NOT GMX_PATCH STREQUAL "")
    configure_file (
        "${CMAKE_CURRENT_SOURCE_DIR}/apply_patch.sh.in"
        "${CMAKE_CURRENT_BINARY_DIR}/apply_patch.sh"
    )
    set(PATCH_STEP "sh ${CMAKE_CURRENT_BINARY_DIR}/apply_patch.sh ${GMX_PATCH}")
else()
    set(PATCH_STEP "")
endif()

# Custom suffix for SSAGES-specific build of GROMACS
set (GMX_SUFFIX "_ssages")

# Only build GROMACS if not using external installation
if (USE_EXTERNAL_GROMACS)
    message(STATUS "Using external GROMACS installation - skipping build step")
else()
    # Add gromacs as external project
    ExternalProject_Add(
        gromacs
        PREFIX ${CMAKE_CURRENT_BINARY_DIR}/gromacs
        DOWNLOAD_COMMAND ""
        SOURCE_DIR ${GROMACS_SRC}
        PATCH_COMMAND ${PATCH_STEP}
        CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
        -DGMX_MPI=ON
        -DGMX_DEFAULT_SUFFIX=OFF -DGMX_BINARY_SUFFIX=${GMX_SUFFIX} -DGMX_LIBS_SUFFIX=${GMX_SUFFIX}
        -DCMAKE_CXX_FLAGS=${GRO_CXX_ARGS}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        ${GMX_LIBRARIES_ARGS}
        -DGMX_DOUBLE=${GMX_DOUBLE}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DGMX_BUILD_OWN_FFTW=${GMX_BUILD_OWN_FFTW}
        ${GMX_SIMD_FLAGS}
        -DGMX_GPU=${GMX_GPU}
        -DCUDA_PROPAGATE_HOST_FLAGS=OFF
        -DCUDA_NVCC_FLAGS=${CUDA_NVCC_FLAGS}
        -DCMAKE_CUDA_HOST_COMPILER=${CMAKE_CXX_COMPILER}
        BUILD_COMMAND $(MAKE)
        BUILD_IN_SOURCE false
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/gromacs
    )

    # Always build gromacs
    ExternalProject_Add_Step(
        gromacs forcebuild
        COMMAND echo "Force build gromacs"
        DEPENDEES configure
        DEPENDERS build
        ALWAYS 1
    )
endif()

# Add source for appropriate package hook.
set(HOOKSRC
    hooks/gromacs/GromacsHook.cpp
    PARENT_SCOPE
)

set(DRIVERSRC
    hooks/gromacs/Driver.cpp
    PARENT_SCOPE
)

# Libraries from the engine to link
include(GNUInstallDirs)
if (USE_EXTERNAL_GROMACS)
    # Use existing GROMACS installation
    # For modern GROMACS 2024.4, need both libgromacs and libgmxapi
    set(ENGINE_LIBRARIES
        "/usr/local/gromacs/lib/libgromacs.so"
        "/usr/local/gromacs/lib/libgmxapi.so"
        "m"  # math library (as per pkg-config)
        PARENT_SCOPE
    )
    message(STATUS "Using GROMACS libraries: libgromacs.so, libgmxapi.so, libm")
else()
    # Use built GROMACS with custom suffix
    if (GROMACS_VERSION VERSION_GREATER_EQUAL "2020")
        # Modern GROMACS versions only have libgromacs
        set(ENGINE_LIBRARIES
            "${CMAKE_BINARY_DIR}/hooks/gromacs/gromacs/${CMAKE_INSTALL_LIBDIR}/libgromacs${GMX_SUFFIX}.so"
            PARENT_SCOPE
        )
    else()
        # Legacy GROMACS versions have separate libmdrun
        set(ENGINE_LIBRARIES
            "${CMAKE_BINARY_DIR}/hooks/gromacs/gromacs/${CMAKE_INSTALL_LIBDIR}/libgromacs${GMX_SUFFIX}.so"
            "${CMAKE_BINARY_DIR}/hooks/gromacs/gromacs/${CMAKE_INSTALL_LIBDIR}/libmdrun.a"
            PARENT_SCOPE
        )
    endif()
endif()

# Function to do post library configuration.
function(CONFIGURE_ENGINE)
    if (USE_EXTERNAL_GROMACS)
        # Use external GROMACS headers and settings
        include_directories(${GROMACS_INCLUDE_DIRS})
        # Explicitly add GROMACS include path for modern API
        include_directories(/usr/local/gromacs/include)
        include_directories(hooks/gromacs/)
        
        message(STATUS "GROMACS include directories: ${GROMACS_INCLUDE_DIRS}")
        message(STATUS "Adding GROMACS include: /usr/local/gromacs/include")
        
        # No dependencies on building GROMACS
        message(STATUS "Using external GROMACS - no build dependencies required")
    else()
        # Use source build approach
        include_directories("${GROMACS_SRC}/src")
        include_directories(hooks/gromacs/)
        if(GROMACS_VERSION MATCHES "^5\\.1(\\.[0-9]+)?$")
            include_directories("${GROMACS_SRC}/src/external/boost")
        endif()
        if (GROMACS AND NOT USE_EXTERNAL_GROMACS)
            add_dependencies(gromacs gromacs-download)
        endif ()
        add_dependencies(gromacs libssages)
        add_dependencies(ssages gromacs)
    endif()
endfunction()
