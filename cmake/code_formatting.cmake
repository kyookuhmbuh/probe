# Find the clang-format executable
find_program(CLANG_FORMAT_EXE NAMES clang-format)
if(NOT CLANG_FORMAT_EXE)
    message(FATAL_ERROR "clang-format not found!")
endif()

# Function to format source files of a target
function(format_target_sources target_name)
    # Get the list of source files for the target
    get_target_property(sources ${target_name} SOURCES)
    foreach(source IN LISTS sources)
        # Get the absolute path of the source file
        get_filename_component(abs_source ${source} ABSOLUTE)
        # Add a custom command to format the source file before building the target
        add_custom_command(
            TARGET ${target_name}
            PRE_BUILD
            COMMAND "${CLANG_FORMAT_EXE}" --style=file -i "${abs_source}"
            COMMENT "Formatting ${abs_source} with Clang-Format..."
            VERBATIM
        )
    endforeach()

     # Get the list of include directories for the target
    get_target_property(include_dirs ${target_name} INCLUDE_DIRECTORIES)
    if(include_dirs)
        foreach(include_dir IN LISTS include_dirs)
            # Get all header files in the include directory
            file(GLOB_RECURSE header_files 
                "${include_dir}/*.h" 
                "${include_dir}/*.hpp" 
                "${include_dir}/*.hh" 
                "${include_dir}/*.hxx")

            foreach(header_file IN LISTS header_files)
                # Get the absolute path of the header file
                get_filename_component(abs_header_file ${header_file} ABSOLUTE)
                # Add a custom command to format the header file before building the target
                add_custom_command(
                    TARGET ${target_name}
                    PRE_BUILD
                    COMMAND "${CLANG_FORMAT_EXE}" --style=file -i "${abs_header_file}"
                    COMMENT "Formatting ${abs_header_file} with Clang-Format..."
                    VERBATIM
                )
            endforeach()
        endforeach()
    endif()
endfunction()

# # Example usage of the function for a specific target
# add_executable(my_target main.cpp utils.cpp)
# 
# # Call the function to format source files of the target
# format_target_sources(my_target)
