# Copyright 2025 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

VLT ?= verilator
BENDER ?= bender

.PHONY: vlt-compile vlt-clean

VLT_DIR = $(PICOBELLO_ROOT)/target/sim/verilator
VLT_WORK = $(VLT_DIR)/work
VLT_NUM_THREADS ?= 1

VLT_BENDER   = $(COMMON_TARGS) -t verilator -DCOMMON_CELLS_ASSERTS_OFF
VLT_SOURCES  = $(shell $(BENDER) script flist $(VLT_BENDER))
VLT_CC_SOURCES  = $(realpath $(CHS_ROOT))/target/sim/src/elfloader.cpp

VLT_FLAGS    += --timing
VLT_FLAGS    += --timescale 1ns/1ps
VLT_FLAGS    += --trace
VLT_FLAGS    += -Wno-BLKANDNBLK
VLT_FLAGS    += -Wno-LITENDIAN
VLT_FLAGS    += -Wno-CASEINCOMPLETE
VLT_FLAGS    += -Wno-CMPCONST
VLT_FLAGS    += -Wno-WIDTH
VLT_FLAGS    += -Wno-WIDTHCONCAT
VLT_FLAGS    += -Wno-UNSIGNED
VLT_FLAGS    += -Wno-UNOPTFLAT
VLT_FLAGS    += -Wno-fatal
VLT_FLAGS    += --unroll-count 1024
VLT_FLAGS    += --threads $(VLT_NUM_THREADS)

$(VLT_WORK):
	mkdir -p $(VLT_WORK)

$(VLT_WORK)/picobello.vlt: $(VLT_WORK)/picobello_bin.vlt
	@echo "#!/bin/bash" > $@
	@echo '$(VERILATOR_SEPP) $(realpath $<) $$(realpath $$1) $$2' >> $@
	@chmod +x $@

.PHONY: vlt-debug
vlt-debug:
	@echo $(VLT_WORK)

$(VLT_WORK)/verilator.flist: $(VLT_SOURCES) $(VLT_CC_SOURCES) | $(VLT_WORK)
	$(BENDER) script verilator $(VLT_BENDER) > $@

vlt-compile: $(VLT_WORK)/picobello_bin.vlt
$(VLT_WORK)/picobello_bin.vlt: $(VLT_WORK)/verilator.flist
	$(VLT) -f $(VLT_WORK)/verilator.flist \
		$(VLT_FLAGS) --Mdir $(VLT_WORK) \
		-j $(VLT_JOBS) \
		-o $@ --binary --build --top-module picobello_top $(VLT_CC_SOURCES)


vlt-clean:
	rm -rf $(VLT_WORK)
