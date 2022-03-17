
# Reminder: This won't auto-update when you add a file, you need to re-run CMake
# to re-generate the glob. Or, you add the files directly into the install()
# statement below.
file(GLOB yml_files "*.yml")
# List all header files here (UHD and GNU Radio)
install(
    FILES
    ${yml_files}
    DESTINATION share/uhd/rfnoc/blocks
    COMPONENT blocks
)

