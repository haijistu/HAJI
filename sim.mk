TOPNAME = ysyxSoCFull

VERILATOR = verilator
VERILATOR_CFLAGS += --build -cc -O3 -j 0  \
										--autoflush --timescale "1ns/1ns" --no-timing \
										-Ivsrc/ -I$(SOC_HOME)/perip/uart16550/rtl -I$(SOC_HOME)/perip/spi/rtl \
										--trace-fst

# IMG = $(abspath ./tests/dummy-riscv32e-ysyxsoc.bin)
IMG = $(abspath ./tests/add-longlong-riscv32e-ysyxsoc.bin)

CPPFLAGS = -I$(abspath ./cppsrc/include) -I$(NEMU_HOME)/tools/capstone/repo/include -DCONFIG_WAVEFORM
LDFLAGS = -lreadline -ldl

VSRCS = $(shell find $(abspath ./vsrc) -name "*.v") $(shell find $(abspath $(SOC_HOME)/perip) -name "*.v") $(SOC_HOME)/build/ysyxSoCFull.v
CPPSRCS = $(shell find $(abspath ./cppsrc) -name "*.cpp")

BUILD_DIR = ./build
BIN = $(BUILD_DIR)/$(TOPNAME)
WAVE_DIR = ./waveform

NPCARGS = $(IMG) # 暂时不考虑diff和ftrace

$(BIN): $(VSRCS) $(CPPSRCS)
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(WAVE_DIR)
	@$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CPPFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(BUILD_DIR) --exe -o $(abspath $(BIN))

sim: $(BIN)
	@echo simulation on ysyxSoC
	@$^ $(NPCARGS)

clean: 
	rm -rf $(BUILD_DIR) $(WAVE_DIR)
