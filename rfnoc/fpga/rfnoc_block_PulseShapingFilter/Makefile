
#-------------------------------------------------
# Top-of-Makefile
#-------------------------------------------------
# Define BASE_DIR to point to the "top" dir. Note:
# UHD_FPGA_DIR must be passed into this Makefile.
ifndef UHD_FPGA_DIR
$(error "UHD_FPGA_DIR is not set! Must point to UHD FPGA repository!")
endif
BASE_DIR = $(UHD_FPGA_DIR)/usrp3/top
# Include viv_sim_preample after defining BASE_DIR
include $(BASE_DIR)/../tools/make/viv_sim_preamble.mak

#-------------------------------------------------
# Design Specific
#-------------------------------------------------

# Add Out-of-tree IP
OOT_FPGA_DIR = $(dir $(abspath $(firstword $(MAKEFILE_LIST))))/../
include $(OOT_FPGA_DIR)/ip/pulse_shaping_filter/Makefile.inc

# Include makefiles and sources for the DUT and its
# dependencies.
include $(BASE_DIR)/../lib/rfnoc/core/Makefile.srcs
include $(BASE_DIR)/../lib/rfnoc/utils/Makefile.srcs
include Makefile.srcs

DESIGN_SRCS += $(abspath $(RFNOC_CORE_SRCS) $(RFNOC_UTIL_SRCS) $(RFNOC_OOT_SRCS) $(LIB_IP_PULSE_SHAPING_FILTER_SRCS) )

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
$(info IP_BUILD_DIR [${IP_BUILD_DIR}])
SIM_TOP = rfnoc_block_PulseShapingFilter_tb
SIM_SRCS = $(abspath rfnoc_block_PulseShapingFilter_tb.sv) \
$(abspath $(IP_BUILD_DIR)/pulse_shaping_filter/sim/pulse_shaping_filter.vhd) \
#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak

