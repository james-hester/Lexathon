####################################################
# LoadStringsFromFile: loads 9-character
# strings from dictionary file onto the stack.
# Arguments:
#	$a0:	pointer to filename (ASCII, 0-terminated)
# Uses registers:
#	$t0, $a and $v registers
# Returns:
#	nothing
#################################################### 
LoadStringsFromFile:
li $v0, 13
li $a1, 0 #read from file
li $a2, 0 #open file mode: ignored
syscall
move $t0, $v0

li $a1, 0
LSFFfileReadLoop:
addi $sp, $sp, -4
sw $a1, 0($sp)

li $a0, 10
li $v0, 9 #allocate 10 bytes of memory
syscall #v0 contains a pointer to 10 bytes

move $a1, $v0
move $a0, $t0
li $a2, 9
li $v0, 14
syscall

beq $v0, 9, LSFFfileReadLoop

move $a0, $t0
li $v0, 16
syscall

jr $ra

####################################################
# LoadStringsFromFileN: loads exactly 75557 9-character
# strings from dictionary file onto the heap and returns pointer
# to collection of strings.
# Arguments:
#	$a0:	pointer to filename (ASCII, 0-terminated)
# Uses registers:
#	$t0, $a and $v registers
# Returns:
#	$v0:	pointer to the strings
#################################################### 
LoadStringsFromFileN:
li $v0, 13
li $a1, 0 #read from file
li $a2, 0 #open file mode: ignored
syscall
move $t0, $v0

li $a0, 680013
li $v0, 9 #allocate 680013 bytes of memory
syscall #v0 contains a pointer to 680013 bytes


move $a1, $v0
move $a0, $t0
li $a2, 680013
li $v0, 14
syscall

move $a0, $t0
li $v0, 16
syscall

move $v0, $a1

jr $ra
