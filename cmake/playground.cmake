# ===================================================================
# PLAYGROUND MODULE: HANDLES SOURCE FILE CLASSIFICATION AND TARGET SETUP
# ===================================================================

include(${CMAKE_MODULE_PATH}/code_formatting.cmake)

function(setup_playground source_dir include_dir)
    # ===================================================================
    # 1. SOURCE FILE DISCOVERY
    # ===================================================================
    file(GLOB_RECURSE cpp_files LIST_DIRECTORIES false CONFIGURE_DEPENDS "${source_dir}/**.cpp")
    list(REMOVE_DUPLICATES cpp_files)
    list(FILTER cpp_files EXCLUDE REGEX ".*/_.*")

    file(GLOB_RECURSE target_configs LIST_DIRECTORIES false CONFIGURE_DEPENDS "${source_dir}/**.cfg")
    list(FILTER target_configs EXCLUDE REGEX ".*/_.*")

    # ===================================================================
    # 2. MAIN FUNCTION DETECTION
    # ===================================================================
    function(has_main_function file_path result)
        file(READ "${file_path}" content LIMIT 2048)
        string(REGEX MATCH "(int|auto)[ \t\r\n]+main[ \t\r\n]*[({]" found "${content}")
        set(${result} "${found}" PARENT_SCOPE)
    endfunction()

    # ===================================================================
    # 3. SOURCE FILE CLASSIFICATION
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
    # 4. TARGET NAME GENERATION
    # ===================================================================
    function(get_target_name out_var file_path)
        file(RELATIVE_PATH rel_path "${source_dir}" "${file_path}")
        string(REPLACE "/" "_" target_name "${rel_path}")
        get_filename_component(target_name "${target_name}" NAME_WE)
        set(${out_var} "${target_name}" PARENT_SCOPE)
    endfunction()

    # ===================================================================
    # 5. TARGET CONFIGURATION LOADER
    # ===================================================================
    # Function to load definitions from a file with specified scope
    # Parameters:
    #   - TARGET: Name of the target
    #   - SCOPE: Scope (PRIVATE, PUBLIC, INTERFACE)
    #   - FILE: Path to the file with definitions
    function(target_compile_definitions_from_file)
        # Parse function arguments
        cmake_parse_arguments(
            PARSE_ARGV 0 
            ARG 
            "" 
            "TARGET;SCOPE;FILE" 
            ""
        )
        # Check required parameters
        if(NOT ARG_TARGET)
            message(FATAL_ERROR "TARGET is required!")
        endif()
        if(NOT ARG_FILE)
            message(FATAL_ERROR "FILE is required!")
        endif()
        # Check validity of SCOPE
        set(VALID_SCOPES PRIVATE PUBLIC INTERFACE)
        if(NOT ARG_SCOPE)
            set(ARG_SCOPE PRIVATE)  # Default value
        elseif(NOT ARG_SCOPE IN_LIST VALID_SCOPES)
            message(WARNING "Invalid SCOPE '${ARG_SCOPE}'. Using PRIVATE.")
            set(ARG_SCOPE PRIVATE)
        endif()
        # Read the file if it exists
        if(EXISTS ${ARG_FILE})
            file(STRINGS ${ARG_FILE} LINES)
            foreach(line IN LISTS LINES)
                # Skip empty lines and comments
                if(line MATCHES "^[ \t]*#" OR line STREQUAL "")
                    continue()
                endif()
                # Parse key and value
                string(REGEX MATCH "([^=]+)=(.*)" _ ${line})
                set(key ${CMAKE_MATCH_1})
                set(value ${CMAKE_MATCH_2})
                string(STRIP "${key}" key)
                string(STRIP "${value}" value)
                # Add definition with specified scope
                target_compile_definitions(
                    ${ARG_TARGET} 
                    ${ARG_SCOPE} 
                    -D${key}=${value}
                )
            endforeach()
        else()
            message(WARNING "File ${ARG_FILE} not found!")
        endif()
    endfunction()

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
    # 6. LIBRARY CREATION
    # ===================================================================
    set(lib_targets "")

    foreach(lib_file IN LISTS lib_sources)
        get_target_name(target_name "${lib_file}")
        
        if(TARGET "${target_name}")
            message(FATAL_ERROR "Target conflict: ${target_name} already exists!")
        endif()
        
        add_library("${target_name}" STATIC "${lib_file}")
        target_compile_features("${target_name}" PUBLIC cxx_std_20)
        target_include_directories("${target_name}" PUBLIC ${include_dir})
        list(APPEND lib_targets "${target_name}")
        load_target_config("${target_name}" "${lib_file}" "cfg")
        format_target_sources("${target_name}")
    endforeach()

    # ===================================================================
    # 7. EXECUTABLE CREATION
    # ===================================================================
    foreach(exec_file IN LISTS exec_sources)
        get_target_name(target_name "${exec_file}")
        
        if(TARGET "${target_name}")
            message(FATAL_ERROR "Target conflict: ${target_name} already exists!")
        endif()
        
        add_executable("${target_name}" "${exec_file}")
        target_compile_features("${target_name}" PUBLIC cxx_std_20)
        target_include_directories("${target_name}" PUBLIC "${include_dir}")
        
        if(lib_targets)
            target_link_libraries("${target_name}" PRIVATE "$<TARGET_OBJECTS:${lib_targets}>")
        endif()

        load_target_config("${target_name}" "${exec_file}" "cfg")
        format_target_sources("${target_name}")
    endforeach()

    # ===================================================================
    # 8. FINAL CHECKS
    # ===================================================================
    if(NOT cpp_files)
        message(WARNING "No source files found in: ${source_dir}")
    endif()

    if(NOT exec_sources AND cpp_files)
        list(LENGTH cpp_files NUM_FILES)
        message(WARNING "Found ${NUM_FILES} files but no main() functions!")
    endif()
endfunction()
