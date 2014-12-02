####################################################
# LoadHashTable: load the hash table into memory.
# For a discussion of the hash table format, see
# hashtable_builder.asm.
# Arguments:
#	$a0:	pointer to filename (ASCII, 0-terminated)
# Uses registers:
#	all of them
# Returns:
#	$s0:	the hash table
#################################################### 
LoadHashTable:
li $v0, 13
li $a1, 0 	#read from file
li $a2, 0 	#open file mode: ignored
syscall
move $t0, $v0	#we need the file reference to read from the file later

la $a1, addressFirstElement	#Read from the file...
move $a0, $t0	#(file reference is in $t0)
li $a2, 4
li $v0, 14
syscall

la $a1, numWordsInHashtable
li $v0, 14
syscall

la $a1, pointerTableSize
li $v0, 14
syscall

li $t1, 18
lw $t2, numWordsInHashtable
mul $a2, $t1, $t2
lw $t1, pointerTableSize
add $a2, $a2, $t1

move $a0, $a2
li $v0, 9 
syscall
move $s0, $v0

move $t3, $a2

move $a0, $t0
move $a1, $s0
move $a2, $t3
li $v0, 14
syscall

lw $a0, addressFirstElement
subu $t0, $s0, $a0
beqz $t0, LHEnd

#$t0 is the difference
#$t1 is the number of bytes we have to fix
#$t2 is a copy of $s0 we increment through the loop
#$t3 is the loop counter
#$t4 is the current address being corrected

lw $t2, numWordsInHashtable
sll $t2, $t2, 3
lw $t1, pointerTableSize
add $t1, $t1, $t2

srl $t1, $t1, 2


#subtract the difference
li $t3, 0
move $t2, $s0
LHCorrectAddressesLoop:
lw $t4, ($t2)
beqz $t4, LHWordDone

add $t4, $t4, $t0


sw $t4, ($t2)
LHWordDone:
addi $t2, $t2, 4
addi $t3, $t3, 1
beq $t1, $t3, LHEnd
b LHCorrectAddressesLoop
LHEnd:
jr $ra

######################
# CheckInHashTable: is string in hash table?
# $a0: string
# $v0: 0 if string is in hash table, 1 otherwise
#####################
CheckInHashTable:
move $t7, $ra
jal HashFunc
move $ra, $t7
sll $v0, $v0, 2
add $v0, $v0, $s0
lw $t0, ($v0)
beqz $t0, CIHTFail #no entry in the pointer table for hash($a0): a0 is not in table ->
CIHTLoop:
lw $a1, ($t0)
move $t7, $ra
move $t6, $t0
jal StringCmp
move $t0, $t6
move $ra, $t7
beqz $v0, CIHTSuccess
lw $t1, 4($t0)
beqz $t1, CIHTFail
move $t0, $t1
b CIHTLoop
CIHTSuccess:
li $v0, 0
jr $ra
CIHTFail:
li $v0, 1
jr $ra

####################################################
# HashFunc: given 9-character string, produces
# a value corresponding to that string
# between 0 and 1023.
# Arguments:
#	$a0:	pointer to string (ASCII, exactly 9 characters)
# Uses registers:
#	$t0-$t3, $v0
# Returns:
#	$v0: hash
#################################################### 
HashFunc:
li $v0, 0
li $t2, 0
li $t3, 9
move $t0, $a0
HFloop:
addi $t2, $t2, 1
lb $t1, ($t0)
subi $t3, $t3, 1
beqz $t3, HFend
subu $t1, $t1, 96 #converts ASCII char to 0 = '`', 1 = 'a', ...
mulu $t1, $t1, $t2
addu $v0, $v0, $t1
addi $t0, $t0, 1
j HFloop
HFend:
li $t2, 1024
divu $v0, $t2
mfhi $v0
jr $ra 

####################################################
# StringCmp: compares two 9-character strings.
# Arguments:
#	$a0, a1:	pointers to strings (ASCII, exactly 9 characters)
# Uses registers:
#	$t0-$t4, $v0
# Returns:
#	$v0: 0 if the strings are equal.
#            1 otherwise.
####################################################
StringCmp:
li $t4, 9
li $v0, 1
move $t0, $a0
move $t1, $a1
SCLoop:
lb $t2, ($t0)
lb $t3, ($t1)
bne $t2, $t3, SCLoopEnd
subi $t4, $t4, 1
beqz $t4, SCLoopEndSuccess
addi $t0, $t0, 1
addi $t1, $t1, 1
b SCLoop
SCLoopEndSuccess:
li $v0, 0
SCLoopEnd:
jr $ra

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
