PIC16C57
========

Implementation of PIC16C57 in Verilog.


Synthesizer: Xilinx ISE 14.5 (XST)

Simulator  : ModelSim SE-64 10.1c


proj_name.xst:
```Shell
set -tmpdir xst/projnav.tmp
set -xsthdpdir xst
run
-ifn _proj.prj
-ofn PIC16C57
-ofmt NGC
-p xc7a100t-csg324-3
-top PIC16C57
-opt_mode Speed
-opt_level 1
-power NO
-iuc NO
-keep_hierarchy Yes
-netlist_hierarchy As_Optimized
-rtlview NO
-glob_opt AllClockNets
-read_cores YES
-write_timing_constraints NO
-cross_clock_analysis NO
-hierarchy_separator /
-bus_delimiter <>
-case Maintain
-slice_utilization_ratio 100
-bram_utilization_ratio 100
-dsp_utilization_ratio 100
-lc Auto
-reduce_control_sets Auto
-fsm_extract YES
-fsm_encoding User
-safe_implementation No
-fsm_style LUT
-ram_extract Yes
-ram_style Auto
-rom_extract Yes
-shreg_extract YES
-rom_style Auto
-auto_bram_packing NO
-resource_sharing YES
-async_to_sync NO
-shreg_min_size 2
-use_dsp48 Auto
-iobuf YES
-max_fanout 100000
-bufg 32
-register_duplication YES
-register_balancing No
-optimize_primitives NO
-use_clock_enable Auto
-use_sync_set Auto
-use_sync_reset Auto
-iob Auto
-equivalent_register_removal YES
-slice_utilization_ratio_maxmargin 5
```


synthesize:
```Shell
xst -ifn $(PROJECT_FILE_NAME).xst -ofn $(TOP_MODULE_NAME).syr
```


translate:
```Shell
ngdbuild -dd _ngo -nt timestamp -p xc7a100t-csg324-3 $(TOP_MODULE_NAME).ngc $(TOP_MODULE_NAME).ngd
```


map:
```Shell
map -p xc7a100t-csg324-3 -w -logic_opt on -ol high -t 1 -xt 0 -register_duplication off -mt 2 -ir off -pr off -lc off -detail -power off -o $(TOP_MODULE_NAME)_map.ncd $(TOP_MODULE_NAME).ngd $(TOP_MODULE_NAME).pcf
```


PAR:
```Shell
par -w -x -ol high -mt 2 $(TOP_MODULE_NAME)_map.ncd $(TOP_MODULE_NAME).ncd $(TOP_MODULE_NAME).pcf
```


post par timing generation:
```Shell
trce -v 3 -s 3 -n 3 -fastpaths -xml $(TOP_MODULE_NAME).twx $(TOP_MODULE_NAME).ncd -o $(TOP_MODULE_NAME).twr $(TOP_MODULE_NAME).pcf
```


post par simulation model generation:
```Shell
netgen -insert_glbl true -w -dir netgen/translate -ofmt verilog -sim $(TOP_MODULE_NAME).ngd $(TOP_MODULE_NAME)_translate.v
```


compile VPI
```Shell
bash compilePLI.sh
```


timing simulation
```Shell
vlib work
vlog netgen/par/$(TOP_MODULE_NAME)_timesim.v
vlog $(TB_NAME).v
vlog $XILINX_ISE_PATH/14.5/ISE_DS/ISE/verilog/src/glbl.v
vsim -voptargs=\"+acc\" -t 1ps -pli edgeVPI.so +maxdelays -L simprims_ver -L secureip -lib work work.$(TB_NAME) glbl
run -all
```
