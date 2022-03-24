# 调用ip编译工具
include $(TOOLS_DIR)/make/viv_ip_builder.mak

# ip core 描述文件路径
LIB_IP_PULSE_SHAPING_FILTER_SRCS = $(IP_BUILD_DIR)/pulse_shaping_filter/pulse_shaping_filter.xci

# ip core 编译输出文件
LIB_IP_PULSE_SHAPING_FILTER_OUTS = $(addprefix $(IP_BUILD_DIR)/pulse_shaping_filter/, \
pulse_shaping_filter.xci.out \
synth/pulse_shaping_filter.vhd \
)

$(info IP_BUILD_DIR in ip folder [${IP_BUILD_DIR}])

# 调用ip编译命令
# -------------------------------------------------------------------
# Usage: BUILD_VIVADO_IP
# Args: $1 = IP_NAME (IP name)
#       $2 = ARCH (zynq, kintex7, etc)
#       $3 = PART_ID (<device>/<package>/<speedgrade>[/<tempgrade>[/<silicon revision>]])
#       $4 = IP_SRC_DIR (Absolute path to the top level ip src dir)
#       $5 = IP_BUILD_DIR (Absolute path to the top level ip build dir)
#       $6 = GENERATE_EXAMPLE (0 or 1)
# Prereqs:
# - TOOLS_DIR must be defined globally
# -------------------------------------------------------------------
$(LIB_IP_PULSE_SHAPING_FILTER_SRCS) $(LIB_IP_PULSE_SHAPING_FILTER_OUTS) : $(RFNOC_FPGA_DIR)/ip/pulse_shaping_filter/pulse_shaping_filter.xci
	$(call BUILD_VIVADO_IP,pulse_shaping_filter,$(ARCH),$(PART_ID),$(RFNOC_FPGA_DIR)/ip,$(IP_BUILD_DIR),0)