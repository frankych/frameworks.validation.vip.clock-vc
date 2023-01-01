MAKEFLAGS += -L # Use the latest mtime between SYMLINKS and target

SYMLINKS := $(WORKAREA)/subip/vip/uvm
PYTHON_LIB_OBJ := $(WORKAREA)/src/dpi/cdie_libsv_adapter.so
CDIE_PY_SOURCE = /p/cth/rtl/proj_tools/pydoh_root/mtl/cdie_vc/2022.ww46.01

ifndef VIP_ROOT
VIP_ROOT=$(WORKAREA)
endif

ifndef SO_OUTPUT_DIR
SO_OUTPUT_DIR = $(WORKAREA)/src/dpi
endif

all: $(SYMLINKS) build_so vcssim dvt

$(SYMLINKS) : filelists/val/vip.list
	moab update

build_so: Makefile
	make -f $(VIP_ROOT)/src/dpi/Makefile TARGET=$(SO_OUTPUT_DIR) VC_ROOT=$(VIP_ROOT) CDIE_PY_SOURCE=$(CDIE_PY_SOURCE) GCC_PATH=/usr/intel/pkgs/gcc/4.7.2 SOCS_VC_COLLATERAL_PATH=/p/cth/rtl/proj_tools/socs_vc_py_source/2021.ww46.01/

vcssim : $(SYMLINKS)
	make -f $(WORKAREA)/verif/vcssim/Makefile vcssim

dvt: $(SYMLINKS)
	make -f $(WORKAREA)/verif/vcssim/Makefile dvt

clean:
	rm -rf subip/ output/ regression/ $(PYTHON_LIB_OBJ)

elab_only: remove_simv vcssim

regress:
	simregress -net -notify -P zsc10_normal -C 'SLES12&&4G' -Q /ddg/mtl/val/intg/rpm/normal -l reglist/cdie_pm_vc/level0.list -dut cdie_pm_vc -blocking -passrate '100%'

remove_simv:
	rm -rf output/cdie_pm_vc/vcssim/model/*

release:
	$(eval version=$(shell /p/hdk/pu_tu/prd/proj_bin/ddgcth/latest/git tag --sort=creatordate | tail -n 1))
	/p/cth/rtl/proj_tools/proj_binx/xhdk74/latest/crt install -type rtl_proj_tools -tool cdie_pm_vc -src $(WORKAREA) -version $(version) -includedotgitinrelease -updatelink latest
