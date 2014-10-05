.eqv WORDS_IN_REGULAR_DICT 75558
.eqv WORDS_IN_NINECHAR_DICT 16692
.eqv LOADING_BAR_UPDATE_FREQ 1500 #1 period printed per X words processed at the "Loading" screen

.data

dictionaryFileName: .asciiz "dictionary.txt"
startingWordsDictionaryFileName: .asciiz "ninechar.txt"
.align 2
pointerTable: .space 4096
.align 2
nineCharArray: .space 8
strbuf: .space 11 #Used during testreadloop -- not permanent!
loadMsg: .asciiz "Loading"

.text

# Set up the hash table and the array of
# nine-character words.
####################################################
la $a0, dictionaryFileName
jal LoadStringsFromFile

li $a0, WORDS_IN_REGULAR_DICT
jal BuildHashTable

#Words with nine characters are a special case: they are used to generate a puzzle.
#Thus, they are kept in their own file, and loaded into a simple array rather than the hashtable.
la $a0, startingWordsDictionaryFileName
jal LoadStringsFromFile
li $a0, WORDS_IN_NINECHAR_DICT
sll $a0, $a0, 2		#4 bytes per pointer * the number of 9-character words (16692)
li $v0, 9
syscall
nineCharStringReadLoop:
lw $a0, ($sp) 		#$a0: pointer to a string being processed.
addiu $sp, $sp, 4 	#Stack pointer must be manually manipulated... 
beqz $a0, NCSRLDone 	#The last entry on the stack generated by LoadStringsFromFile was a word filled with zeroes.
			#On encountering this word, string processing is done ->
sw $a0, ($v0)		#Put the string into the current position in the array.
addiu $v0, $v0, 4	#Increment the current position of the array.
b nineCharStringReadLoop
NCSRLDone:
la $v1, nineCharArray
sw $v0, ($v1)
####################################################
# The hashtable and array are loaded: the game can start.

testreadloop: #Temporary loop for testing the hashtable
li $v0, 8
li $a1, 10
la $a0, strbuf
syscall
jal CheckInHashTable
move $a0, $v0
li $v0, 1
syscall
li $a0, 10
li $v0, 11
syscall
b testreadloop


b quitProgram

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
######################

quitProgram: #quit
li $v0, 10
syscall

.include "fileio.asm"
.include "hashtabl.asm"
