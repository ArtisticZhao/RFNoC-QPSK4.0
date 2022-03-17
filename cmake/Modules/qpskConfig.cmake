INCLUDE(FindPkgConfig)
PKG_CHECK_MODULES(PC_QPSK qpsk)

FIND_PATH(
    QPSK_INCLUDE_DIRS
    NAMES qpsk/api.h
    HINTS $ENV{QPSK_DIR}/include
        ${PC_QPSK_INCLUDEDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/include
          /usr/local/include
          /usr/include
)

FIND_LIBRARY(
    QPSK_LIBRARIES
    NAMES gnuradio-qpsk
    HINTS $ENV{QPSK_DIR}/lib
        ${PC_QPSK_LIBDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/lib
          ${CMAKE_INSTALL_PREFIX}/lib64
          /usr/local/lib
          /usr/local/lib64
          /usr/lib
          /usr/lib64
)

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(QPSK DEFAULT_MSG QPSK_LIBRARIES QPSK_INCLUDE_DIRS)
MARK_AS_ADVANCED(QPSK_LIBRARIES QPSK_INCLUDE_DIRS)

