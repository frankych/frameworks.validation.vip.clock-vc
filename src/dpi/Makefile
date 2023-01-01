# NOTE: you must set $MODEL_ROOT
#
# MODEL_ROOT or VC_ROOT - Path to the root of the VC
# ONECFG_arch      - platform name, usually em64t_SLES12
# TARGET    - Where generated so file will be copied

# Set architecture and compilation type.
#
# NOTE:  If you are building a 32-bit client on a 64-bit host,
# you should add a rule to force ARCH to i386_linux26 if sysname
# evaluates to x86-64_linux26.

VC_NAME = cdie

ifndef DUT
DUT = $(VC_NAME)_clk_vc
endif

ifndef VC_ROOT
VC_ROOT = $(MODEL_ROOT)
endif

AGENT_NAME = sv_adapter

ifndef VCS_HOME
VCS_HOME    = $(shell cth_query -tool crb params vcssim_vcs_path -resolve)
endif
VCS_LIB     = $(VCS_HOME)/linux64/lib
VCS_DPI_INC = $(VCS_HOME)/include/

ifndef GCC_PATH
GCC_PATH    := $(shell cth_query -tool crb params gcc_path -resolve)
endif
CXX         := $(GCC_PATH)/bin/g++

ifndef VC_PYDOH_INFRA_MODEL_PATH
VC_PYDOH_INFRA_MODEL_PATH = $(shell realpath $(WORKAREA)/subip/vip/vc_sv_pydoh_infra)
endif

VC_PYDOH_INFRA_SO_PATH = $(VC_PYDOH_INFRA_MODEL_PATH)/src/verif/dpi
VC_PYDOH_INFRA_DPI_HEADER_PATH = $(VC_PYDOH_INFRA_SO_PATH)
VC_PYDOH_INFRA_HEADER_PATH = $(VC_PYDOH_INFRA_MODEL_PATH)/src/verif/dpi/common

PYTHON_HEADERS = /usr/intel/pkgs/python3/3.7.4/include/python3.7m
PYTHON_SO_FILE_DIRECTORY_PATH = /usr/intel/pkgs/python3/3.7.4/lib
VC_PYDOH_INFRA_HEADER    = $(VC_PYDOH_INFRA_SO_PATH)/common/sv_adapter_common.h

SOURCE      = $(VC_ROOT)/src/dpi
SV_SOURCE   = $(VC_ROOT)/verif/tb

SOURCES    = $(SOURCE)/sv_adapter/sv_adapter.cpp
HEADERS    = $(VC_PYDOH_INFRA_HEADER)

LIBS_TO_LINK = -lsv_pydoh_infra
RUNTIME_PATH_LINKS = $(PYTHON_SO_FILE_DIRECTORY_PATH):$(VC_PYDOH_INFRA_SO_PATH)

TARGET_SHLIB = $(TARGET)/$(VC_NAME)_lib$(AGENT_NAME).so

## Compile flags
CFLAGS          += -fPIC
CFLAGS          += -O3
CFLAGS          += -DVCSSIM
ifeq ($(ARCH),i386_linux26)
        CFLAGS          += -m32
else
        CFLAGS          += -m64
endif

$(AGENT_NAME): install $(TARGET_SHLIB)

install:
	mkdir -p $(TARGET)
	env >make.env

$(TARGET_SHLIB) : $(SOURCES) $(HEADERS) $(VC_PYDOH_INFRA_SO_PATH)/libsv_pydoh_infra.so $(CDIE_VC_COLLATERAL_PATH) $(VC_ROOT)/Makefile
	$(CXX) -DUSE_SIM=1 -shared -o $@ $(SOURCES) $(CFLAGS) -std=c++11 \
	-I$(VCS_DPI_INC) -I. -I$(SOURCE) -I$(SV_SOURCE) -I$(PYTHON_HEADERS) -I$(VC_PYDOH_INFRA_HEADER_PATH) \
    -I$(VC_PYDOH_INFRA_DPI_HEADER_PATH) \
    -D 'PYTHON_PATH="'/usr/intel/pkgs/python3/3.7.4/bin/python3.7m'"' -D 'CDIE_VC_COLLATERAL_PATH="'$(CDIE_PY_SOURCE)'"' -D 'SOCS_VC_COLLATERAL_PATH="'$(SOCS_VC_COLLATERAL_PATH)'"' \
    -L$(UTILS)/lib/$(TYPE)/$(ARCH) -L$(PYTHON_SO_FILE_DIRECTORY_PATH) -lpython3.7m -L$(VC_PYDOH_INFRA_SO_PATH) $(LIBS_TO_LINK) \
    -Wl,-rpath,$(RUNTIME_PATH_LINKS)

all: $(TARGET_SHLIB)

clean:
	rm -rf $(TARGET_SHLIB)
