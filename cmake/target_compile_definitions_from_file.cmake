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