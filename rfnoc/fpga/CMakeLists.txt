
# List Makefile.srcs here (which needs to point to the individual blocks!) as
# well as any non-block specific HDL files that should get installed alongside
# the rest of the FPGA/Verilog/VHDL/HDL files. Only list files that are required
# for synthesis, testbench-specific files do not get installed and thus do not
# have to be listed (it won't hurt, it will just clutter your share/ directory).
# Don't list the files in the block subdirectories, though, they will get added
# below.
install(FILES
    Makefile.srcs
    DESTINATION ${PROJECT_DATA_DIR}/fpga
    COMPONENT fpga
)

# Call add_subdirectory() for every subdirectory
SUBDIRLIST(subdirs ${CMAKE_CURRENT_SOURCE_DIR})
foreach(subdir ${subdirs})
    add_subdirectory(${subdir})
endforeach()

