addi x1, x0, 5         
addi x3, x0, 100        
lw   x12, 0(x3)        
addi  x2, x0, 5        
sub  x4, x2, x1        
or   x5, x3, x4 
addi x6, x6, 1
add  x7, x7, x6 
beq  x1, x2, target                      
and  x8, x8, x7 
or   x9, x9, x8

target:
add   x10, x10, x9
sub   x11, x11, x10
addi  x12, x12, 1
sw    x12, 0(x3)        
addi  x1, x0, 5
andi  x2, x0, 10
ori   x3, x0, 1
xori  x4, x0, 10
srli  x5, x0, 1
add   x6, x1, x2
or    x7, x3, x4
add   x8, x1, x5
sub   x9, x3, x3

lui   x10, 0x0          
auipc x11, 0x0          
sw    x2, 0(x8)         
lw    x12, 0(x3)        
jal   x13, Jump            
addi  x2, x0, 1         
jalr  x14, x5, 0
Jump:
addi  x2, x0, 2
addi  x3, x0, 3
addi  x4, x0, 4
addi  x5, x0, 5

