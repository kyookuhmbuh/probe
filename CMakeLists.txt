# ===================================================================
# 0. BASIC PROJECT SETUP AND VERSIONS
# ===================================================================
cmake_minimum_required(VERSION 3.15)
project(
    probe 
    DESCRIPTION "probe for some cpp stuff"
    LANGUAGES CXX)

# ===================================================================
# 1. ADDITIONAL CONFIGURATIONS
# ===================================================================
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(${CMAKE_MODULE_PATH}/target_compile_definitions_from_file.cmake)
include(${CMAKE_MODULE_PATH}/code_formatting.cmake)

# ===================================================================
# 2. PATH AND DIRECTORY CONFIGURATION
# ===================================================================
# Check for required directories
foreach(DIR IN ITEMS include src)
    if(NOT IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${DIR}")
        message(FATAL_ERROR "Required directory '${DIR}' not found!")
    endif()
endforeach()

# Convert to absolute paths
get_filename_component(INCLUDE_PUBLIC_ABS "${CMAKE_CURRENT_SOURCE_DIR}/include" ABSOLUTE)
get_filename_component(INCLUDE_PRIVATE_ABS "${CMAKE_CURRENT_SOURCE_DIR}/src" ABSOLUTE)

# ===================================================================
# 3. SOURCE FILE DISCOVERY
# ===================================================================
file(GLOB_RECURSE cpp_files 
    LIST_DIRECTORIES false
    CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/**.cpp"
)
list(REMOVE_DUPLICATES cpp_files)
list(FILTER cpp_files EXCLUDE REGEX ".*/_.*")

file(GLOB_RECURSE target_configs 
    LIST_DIRECTORIES false
    CONFIGURE_DEPENDS 
    "${CMAKE_CURRENT_SOURCE_DIR}/src/**.cfg"
)
list(FILTER target_configs EXCLUDE REGEX ".*/_.*")

# ===================================================================
# 4. MAIN FUNCTION DETECTION
# ===================================================================
function(has_main_function file_path result)
    file(READ "${file_path}" content LIMIT 2048)
    string(REGEX MATCH "(int|auto)[ \t\r\n]+main[ \t\r\n]*[({]" found "${content}")
    set(${result} "${found}" PARENT_SCOPE)
endfunction()

# ===================================================================
# 5. SOURCE FILE CLASSIFICATION
# ===================================================================
set(exec_sources "")
set(lib_sources "")

foreach(cpp_file IN LISTS cpp_files)
    has_main_function("${cpp_file}" is_main)
    if(is_main)
        list(APPEND exec_sources "${cpp_file}")
        message(STATUS "Executable source: ${cpp_file}")
    else()
        list(APPEND lib_sources "${cpp_file}")
        message(STATUS "Library source: ${cpp_file}")
    endif()
endforeach()

# ===================================================================
# 6. TARGET NAME GENERATION
# ===================================================================
function(get_target_name out_var file_path)
    file(RELATIVE_PATH rel_path 
        "${CMAKE_CURRENT_SOURCE_DIR}/src" 
        "${file_path}"
    )
    string(REPLACE "/" "_" target_name "${rel_path}")
    get_filename_component(target_name "${target_name}" NAME_WE)
    set(${out_var} "${target_name}" PARENT_SCOPE)
endfunction()

# ===================================================================
# 7. TARGET CONFIGURATION LOADER
# ===================================================================
function(load_target_config target_name source_file config_extension)
    get_filename_component(exec_dir "${source_file}" DIRECTORY)
    get_filename_component(exec_name_we "${source_file}" NAME_WE)
    set(target_config "${exec_dir}/${exec_name_we}.${config_extension}")

    if(EXISTS "${target_config}")
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${target_config}")
        message(STATUS "Loading compile defintions for ${target_name}: ${target_config}")
        target_compile_definitions_from_file(
            TARGET ${target_name} 
            SCOPE PRIVATE 
            FILE "${target_config}")
    endif()
endfunction()

# ===================================================================
# 8. LIBRARY CREATION
# ===================================================================
set(lib_targets "")

foreach(lib_file IN LISTS lib_sources)
    get_target_name(target_name "${lib_file}")
    
    if(TARGET "${target_name}")
        message(FATAL_ERROR "Target conflict: ${target_name} already exists!")
    endif()
    
    add_library("${target_name}" OBJECT "${lib_file}")
    
    target_compile_features("${target_name}" PUBLIC cxx_std_20)
    
    target_include_directories("${target_name}"
        PUBLIC ${INCLUDE_PUBLIC_ABS}
    )

    list(APPEND lib_targets "${target_name}")

    # Loading the config for the target
    load_target_config("${target_name}" "${lib_file}" "cfg")
endforeach()

# ===================================================================
# 9. EXECUTABLE CREATION
# ===================================================================
foreach(exec_file IN LISTS exec_sources)
    get_target_name(target_name "${exec_file}")
    
    if(TARGET "${target_name}")
        message(FATAL_ERROR "Target conflict: ${target_name} already exists!")
    endif()
    
    add_executable("${target_name}" "${exec_file}")
    
    target_compile_features("${target_name}" PUBLIC cxx_std_20)

    target_include_directories("${target_name}"
        PUBLIC "${INCLUDE_PUBLIC_ABS}"
    )
    
    if(lib_targets)
        target_link_libraries("${target_name}" 
            PRIVATE 
            "$<TARGET_OBJECTS:${lib_targets}>"
        )
    endif()

     # Loading the config for the target
     load_target_config("${target_name}" "${exec_file}" "cfg")

     # Format source files of the target
     format_target_sources("${target_name}")
endforeach()

# ===================================================================
# 10. FINAL CHECKS
# ===================================================================
if(NOT cpp_files)
    message(WARNING "No source files found in: ${CMAKE_CURRENT_SOURCE_DIR}/src")
endif()

if(NOT exec_sources AND cpp_files)
    list(LENGTH cpp_files NUM_FILES)
    message(WARNING "Found ${NUM_FILES} files but no main() functions!")
endif()
