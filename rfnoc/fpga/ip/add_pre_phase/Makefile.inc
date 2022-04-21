# 调用ip编译工具
include $(TOOLS_DIR)/make/viv_ip_builder.mak

# ip core 描述文件路径
LIB_IP_ADD_PRE_PHASE_SRCS = $(IP_BUILD_DIR)/add_pre_phase/add_pre_phase.xci

# ip core 编译输出文件
LIB_IP_ADD_PRE_PHASE_OUTS = $(addprefix $(IP_BUILD_DIR)/add_pre_phase/, \
add_pre_phase.xci.out \
synth/add_pre_phase.vhd \
)

# 这里的IP_BUILD_DIR 指向 <uhd-repo>/fpga/usrp3/top/x300/build-ip/xc7k410tffg900-2
# 其中x300 xc7k410tffg900-2 是根据所使用的USRP平台而改变的
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
$(LIB_IP_ADD_PRE_PHASE_SRCS) $(LIB_IP_ADD_PRE_PHASE_OUTS) : $(RFNOC_FPGA_DIR)/ip/add_pre_phase/add_pre_phase.xci
	$(call BUILD_VIVADO_IP,add_pre_phase,$(ARCH),$(PART_ID),$(RFNOC_FPGA_DIR)/ip,$(IP_BUILD_DIR),0)
