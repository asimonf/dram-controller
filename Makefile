# vhdl files
LIB = $(wildcard lib/**/*.vhd lib/*.vhd)
FILES = $(wildcard src/**/*.vhd src/*.vhd)

# testbench
TESTBENCHPATH = $(wildcard testbench/**/${TESTBENCH}*.vhd testbench/${TESTBENCH}*.vhd)
WORKDIR = work

# GHDL CONFIG
GHDL_CMD = ghdl
GHDL_FLAGS = --std=08 --ieee=synopsys --warn-no-vital-generic --workdir=$(WORKDIR)

STOP_TIME = 1ms
# Simulation break condition
# GHDL_SIM_OPT = --assert-level=error
GHDL_SIM_OPT = --stop-time=$(STOP_TIME)

# WAVEFORM_VIEWER = flatpak run io.github.gtkwave.GTKWave
WAVEFORM_VIEWER = gtkwave

.PHONY: clean

all: clean make run view

reload: make run

make:
	@mkdir -p $(WORKDIR)

ifeq ($(LIB),)
	$(warning No library files found. Ignoring...)
else
	@$(GHDL_CMD) -a $(GHDL_FLAGS) $(LIB)
endif

ifeq ($(FILES),)
	@$(warning No source files found!)
	@exit 1
endif
	
	@$(GHDL_CMD) -a $(GHDL_FLAGS) $(FILES)

ifeq ($(strip $(TESTBENCH)),)
	@echo "TESTBENCH not set. Use TESTBENCH=<value> to set it."
	@exit 1
endif

ifneq ($(TESTBENCHPATH),)	
	@$(GHDL_CMD) -a $(GHDL_FLAGS) $(TESTBENCHPATH)
	@$(GHDL_CMD) -e $(GHDL_FLAGS) $(basename $(notdir $(TESTBENCHPATH)))
else
	@$(warning No source files found!)
endif

run:
	@$(GHDL_CMD) -r $(GHDL_FLAGS) $(basename $(notdir $(TESTBENCHPATH))) --vcd=$(WORKDIR)/$(basename $(notdir $(TESTBENCHPATH))).vcd $(GHDL_SIM_OPT)

view:
	@$(WAVEFORM_VIEWER) --dump=$(WORKDIR)/$(basename $(notdir $(TESTBENCHPATH))).vcd

clean:
	@rm -rf $(WORKDIR)
