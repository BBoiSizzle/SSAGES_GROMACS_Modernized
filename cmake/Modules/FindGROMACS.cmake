# FindGROMACS.cmake - Find GROMACS installation
# This module supports both modern GROMACS (2020+) and legacy versions
#
# Variables that can be set to help find GROMACS:
#   GROMACS_ROOT          - Root directory of GROMACS installation
#   GROMACS_DIR           - Directory containing GMXConfig.cmake
#
# Variables set by this module:
#   GROMACS_FOUND         - True if GROMACS was found
#   GROMACS_VERSION       - Version of GROMACS found
#   GROMACS_LIBRARIES     - GROMACS libraries to link against
#   GROMACS_INCLUDE_DIRS  - Include directories for GROMACS
#   GROMACS_DEFINITIONS   - Compiler definitions needed

# First try to find GROMACS using its own CMake config
find_package(GROMACS QUIET CONFIG)

if(GROMACS_FOUND)
    # Modern GROMACS provides its own CMake config
    message(STATUS "Found GROMACS using config mode: ${GROMACS_VERSION}")
    
    # Extract version information
    if(NOT GROMACS_VERSION)
        if(DEFINED GMX_VERSION)
            set(GROMACS_VERSION ${GMX_VERSION})
        endif()
    endif()
    
    # Set up library variables for compatibility
    if(TARGET Gromacs::libgromacs)
        set(GROMACS_LIBRARIES Gromacs::libgromacs)
        get_target_property(GROMACS_INCLUDE_DIRS Gromacs::libgromacs INTERFACE_INCLUDE_DIRECTORIES)
    elseif(TARGET libgromacs)
        set(GROMACS_LIBRARIES libgromacs)
        get_target_property(GROMACS_INCLUDE_DIRS libgromacs INTERFACE_INCLUDE_DIRECTORIES)
    endif()
    
else()
    # Fallback: try to find GROMACS manually
    
    # Find GROMACS installation directory
    find_path(GROMACS_ROOT_DIR
        NAMES include/gromacs/version.h include/gromacs/gromacs.h
        PATHS
            ${GROMACS_ROOT}
            $ENV{GROMACS_ROOT}
            $ENV{GMXHOME}
            $ENV{GMX_HOME}
            /usr/local/gromacs
            /opt/gromacs
            /usr/local
            /opt/local
            /usr
        PATH_SUFFIXES gromacs
    )
    
    if(GROMACS_ROOT_DIR)
        # Find include directory
        find_path(GROMACS_INCLUDE_DIR
            NAMES gromacs/version.h gromacs/gromacs.h gmxpre.h
            PATHS ${GROMACS_ROOT_DIR}/include
            NO_DEFAULT_PATH
        )
        
        # Find library
        find_library(GROMACS_LIBRARY
            NAMES libgromacs gromacs libgromacs_mpi gromacs_mpi
            PATHS ${GROMACS_ROOT_DIR}/lib ${GROMACS_ROOT_DIR}/lib64
            NO_DEFAULT_PATH
        )
        
        if(GROMACS_INCLUDE_DIR AND GROMACS_LIBRARY)
            set(GROMACS_FOUND TRUE)
            set(GROMACS_LIBRARIES ${GROMACS_LIBRARY})
            set(GROMACS_INCLUDE_DIRS ${GROMACS_INCLUDE_DIR})
            
            # Try to determine version
            if(EXISTS "${GROMACS_INCLUDE_DIR}/gromacs/version.h")
                file(READ "${GROMACS_INCLUDE_DIR}/gromacs/version.h" _version_file)
                string(REGEX MATCH "#define GMX_VERSION \"([0-9]+\\.[0-9]+[^\"]*)" _version_match "${_version_file}")
                if(_version_match)
                    set(GROMACS_VERSION ${CMAKE_MATCH_1})
                endif()
            endif()
            
            if(NOT GROMACS_VERSION)
                # Try alternative version detection
                execute_process(
                    COMMAND ${GROMACS_ROOT_DIR}/bin/gmx_ssages --version
                    OUTPUT_VARIABLE _gmx_version_output
                    ERROR_QUIET
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                )
                
                if(NOT _gmx_version_output)
                    execute_process(
                        COMMAND ${GROMACS_ROOT_DIR}/bin/gmx --version
                        OUTPUT_VARIABLE _gmx_version_output
                        ERROR_QUIET
                        OUTPUT_STRIP_TRAILING_WHITESPACE
                    )
                endif()
                
                string(REGEX MATCH "GROMACS version:[ ]*([0-9]+\\.[0-9]+[^ ]*)" _version_match "${_gmx_version_output}")
                if(_version_match)
                    set(GROMACS_VERSION ${CMAKE_MATCH_1})
                endif()
            endif()
            
            message(STATUS "Found GROMACS: ${GROMACS_LIBRARY} (version ${GROMACS_VERSION})")
        endif()
    endif()
endif()

# Handle standard find_package arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GROMACS
    REQUIRED_VARS GROMACS_LIBRARIES GROMACS_INCLUDE_DIRS
    VERSION_VAR GROMACS_VERSION
)

# Create imported target for compatibility
if(GROMACS_FOUND AND NOT TARGET GROMACS::GROMACS)
    add_library(GROMACS::GROMACS UNKNOWN IMPORTED)
    set_target_properties(GROMACS::GROMACS PROPERTIES
        IMPORTED_LOCATION "${GROMACS_LIBRARIES}"
        INTERFACE_INCLUDE_DIRECTORIES "${GROMACS_INCLUDE_DIRS}"
    )
endif()

mark_as_advanced(
    GROMACS_ROOT_DIR
    GROMACS_INCLUDE_DIR
    GROMACS_LIBRARY
)