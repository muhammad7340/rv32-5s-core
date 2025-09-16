#---------------------------------------------------------------------------------------------------
# Script: mem_generator.py
# Description: Generates 'data_mem.mem' to pre-populate 2KB of RAM data memory with incremental 32-bit hex values.
# Note: Provides valid baseline memory targets to test pipeline load/store hardware instructions (e.g., lw, sw).
#---------------------------------------------------------------------------------------------------

with open("data_mem.mem", "w") as f:
    # 256 entries (from 0-512, 2KB = 512 words, each word = 32 bit )
    for i in range(512):  
        # :08x forces 8-character width, zero-padding, and lowercase hex 
        f.write(f"{i:08x}\n")