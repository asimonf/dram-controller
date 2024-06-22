from vunit import VUnit
from glob import glob

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv(compile_builtins=False)

# Optionally add VUnit's builtin HDL utilities for checking, logging, communication...
# See http://vunit.github.io/hdl_libraries.html.
vu.add_vhdl_builtins()
vu.add_json4vhdl()
# or
# vu.add_verilog_builtins()

# Create library 'common'
common = vu.add_library('common')
for file in glob('src/lib/**/*.vhd', recursive=True):
    common.add_source_file(file)

default = vu.add_library('default')
for file in glob('src/design/**/*.vhd', recursive=True):
    default.add_source_file(file)
for file in glob('src/testbench/**/*.vhd', recursive=True):
    default.add_source_file(file)

# Run vunit function
vu.main()