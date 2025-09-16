#-------------------------------------------------------
# Script: reg_generator.py
# Description: Generates 'reg_init.mem' to pre-load all 32 RISC-V registers with known, valid values.
# Note: Prevents 'X' (unknown) value propagation while reading an unwritten register in ALU
#-------------------------------------------------------


with open("reg_init.mem", "w") as f:
    # 32 entries (from 0 to 31 inclusive, matching 0x00 to 0x1F)
    for i in range(32):    
        # :08X forces 8-character width, zero-padding, and uppercase hex
        f.write(f"{i:08X}\n")  
