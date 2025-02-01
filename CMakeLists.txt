# ===================================================================
# 0. BASIC PROJECT SETUP AND VERSIONS
# ===================================================================
cmake_minimum_required(VERSION 3.15)
project(probe 
    DESCRIPTION "Environment for rapid prototyping and testing C++ code snippets" 
    LANGUAGES CXX)

# ===================================================================
# 1. ADDITIONAL CONFIGURATIONS
# ===================================================================
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(${CMAKE_MODULE_PATH}/playground.cmake)

# ===================================================================
# 2. PATH AND DIRECTORY CONFIGURATION
# ===================================================================
foreach(DIR IN ITEMS include src)
    if(NOT IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${DIR}")
        message(FATAL_ERROR "Required directory '${DIR}' not found!")
    endif()
endforeach()

# ===================================================================
# 3. TARGET SETUP MODULE
# ===================================================================
setup_playground("${CMAKE_CURRENT_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}/include")
