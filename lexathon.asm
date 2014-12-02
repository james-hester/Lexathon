##########################################################################
# ------------------------------------------------------------------------
#        L       E       X       A       T       H       O       N
# ------------------------------------------------------------------------
#     Joseph Baumgratz    James Hester   Joel Seida   Noah Wallaert
# ------------------------------------------------------------------------
#  __________________________________
# |How to Build and Run this Program|
# ----------------------------------
# The main Lexathon program is contained in two files: lexathon.asm and 
# hashtable.asm. Before running Lexathon, ensure these two files along
# with "hashtable.dat" and the MARS jar itself are all in the same folder.
# Afterwards, build and run this file (not hashtable.asm); Lexathon will run.
#  __________________________
# |Rebuilding the Hash Table|
# --------------------------
# Lexathon uses a hash table structure to quickly look up English words.
# The hash table, located in hashtable.dat, was itself created by a MIPS
# program, contained in hashtable_builder.asm; the hashtable builder uses
# strings in the file dictionary.txt. These must all be nine characters,
# padded with the "`" character. hashtable_builder.asm can be built and run.
# Before doing so, however, ensure it is in the same folder as all afore-
# mentioned files, and delete hashtable.dat.
#
#############################################################################

.eqv WORDS_IN_REGULAR_DICT 74563
.eqv WORDS_IN_NINECHAR_DICT 16692
.eqv COMMAND_SIGIL 33 #ASCII 33 is "!"

.macro push (%reg)
subi $sp, $sp, 4
sw %reg, ($sp)
.end_macro

.macro pop (%reg)
lw %reg, ($sp)
addi $sp, $sp, 4
.end_macro

.data

dictionaryFileName: .asciiz "hashtable.dat"
startingWordsDictionaryFileName: .asciiz "ninechar.txt"
foundwordsFileName: .asciiz "foundwords.txt" 		#used as storage for words found
.align 2
pointerTable: 	.space 4096
.align 2
nineCharArray:	.space 8
userInputBuffer:.space 10
.align 2
bitArray: 	.space 10
.align 2
addressFirstElement:	.space 4
numWordsInHashtable:	.space 4
pointerTableSize: 	.space 4

loadMsg: 	.asciiz "Loading"
boxTopBar: 	.asciiz " /-------------\\\n"
boxBottomBar: 	.asciiz " \\-------------/\n\n"
boxLeftBar: 	.asciiz " |  "
boxSeparator: 	.asciiz "   "
boxRightBar: 	.asciiz "  |\n"
.align 2
pointerToTestPuzzle: .space 5

#data for command function
quit:	.asciiz	"qhrste"
help:	.asciiz "Commands:\n!q - Quit game\n!t - Display current time\n!r - Restart game\n!s - Shuffle game board\n!h - Display help\n!e - End Game\n"
out:	.asciiz	"The command was not found.  Type !h for the list of commands\n"
timemessage1:	.asciiz	"You have "
timemessage2:	.asciiz	" seconds remaining. Current Score: "
newline:	.asciiz "\n"
timeleft:	.word	120	#start with 2 mins
outoftimemsg:	.asciiz "Out of Time: Last entry was not counted!\n"

score:		.word	0	#holds the player's score
points1:	.asciiz	"eEiImMoOpPrRsStT"	#these are used in calculating score
points2:	.asciiz	"aAbBcCdDfFlLnN"
points3:	.asciiz	"gGhHjJkKuUvVwWyY"
points4:	.asciiz	"qQxXzZ"

wordsfound:	.word 0
emptystring: .asciiz ""
readbuffer: .space 10
readbuffert: .space 11
AlreadyGuessedWord: .asciiz "You have already guessed this word, so no Time/Score has been added!\n\n"
GameFinishedMessage: .asciiz "####################################################\nGame Finished! Here is a list of words you found:\n"
PressKeyToCon: .asciiz "Press any key to continue\n"


#data for splash screen
splashscreenfilename: .asciiz "SplashScreen.txt"  #current size < 300 chars

#data for pressanykeytocontinue
backspace: .asciiz "\b \n"

wordInvalidMsg: .asciiz "\nThat's not a valid word!\n\n"
middleLetterUnusedMsg: .asciiz "\nThe middle letter of the puzzle wasn't used!\n\n"


.text

# Set up the hash table and the array of
# nine-character words.
####################################################

la $a0, dictionaryFileName
jal LoadHashTable

#Words with nine characters are a special case: they are used to generate a puzzle.
#Thus, they are kept in their own file, and loaded into a simple array rather than the hashtable.
la $a0, startingWordsDictionaryFileName
jal LoadStringsFromFile
li $a0, WORDS_IN_NINECHAR_DICT
sll $a0, $a0, 2		#4 bytes per pointer * the number of 9-character words (16692)
li $v0, 9
syscall
move $t0, $v0		#Since we'll be incrementing $v0 as we add words, we need to save a pointer
			#to the beginning of the array.
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
sw $t0, ($v1)
####################################################
# The hashtable and array are loaded: the game can start.
startgame:
jal PrintSplashScreen

newRound:
jal GenPuzzle
move $s1, $v0
move $s2, $zero
sw $zero, score		#reset the score to 0
jal ClearFile		#clear FoundWords File
jal SetTime		#set the clock to 120

gameInputLoop:
jal PrintPuzzle	#Print the current puzzle...
li $v0, 8
li $a1, 10
la $a0, userInputBuffer
syscall		#Then, poll user for input.
lb $t0, ($a0)	#Check the first letter of the user's input.
beq $t0, COMMAND_SIGIL, handleCommand	#If it is the command sigil, process the input as a command.
jal CheckWord	#Otherwise, it is a word.
move $t4, $v0	#move returned value from CheckWord into $t4

#Based on the results of CheckWord, either complain to or congratulate the user.
beqz $v0, GILMsg0
beq $v0, 1, GILMsg1
beq $v0, 2, GILMsg2
beq $v0, 3, GILMsg3
GILMsg0:
la $a0, newline
b GILPrintMsg
GILMsg1:
la $a0, wordInvalidMsg
b GILPrintMsg
GILMsg2:
la $a0, middleLetterUnusedMsg
b GILPrintMsg
GILMsg3:
la $a0, wordInvalidMsg	#This case, along with the branch statement, are both unnecessary,
b GILPrintMsg		#but included for clarity.
GILPrintMsg:
li $v0, 4
syscall

jal CheckTime
bnez $t4, noPoints
jal CheckIfAlreadyGuessedWord
bnez $v1, noPointsWithMessage
lw $t0, timeleft	#fetch timeleft from last calculated 
add $t0,$t0,20		#add 20 seconds to the clock
sw $t0, timeleft	#save it as the new timeleft
## to do make a String checker to look through the input and assign a certain score for each letter.
jal ScoreCheck
lw $t0,score
add $t0,$t0,$v1
sw $t0,score
jal AddWordToFile	#if this word was found then add it to the list

b gameInputLoop

noPointsWithMessage:
la $a0, AlreadyGuessedWord
li $v0, 4
syscall
noPoints:

b gameInputLoop

####################################################
# AddWordToFile: adds a word that was found in the dictionary to a list of guessed words
# this is a function so call using jal
# Arguments:
#	userInputBuffer
# Uses registers:
#	$t0, $a0, $v0
# Returns:
#	nothing
####################################################
AddWordToFile:
la $a0, foundwordsFileName
li $a1, 9
li $a2, 0
li $v0, 13
syscall
move $t3, $v0
move $a0, $v0 
la $a1, userInputBuffer
li $a2, 9
li $v0, 15
syscall
move $a0,$t3
li $v0, 16
syscall
lw $t0, wordsfound
addi $t0,$t0,1
sw $t0, wordsfound
jr $ra

ClearFile:
la $a0, foundwordsFileName
li $a1, 1
li $a2, 0
li $v0, 13
syscall
move $t3, $v0
move $a0, $v0 
la $a1, emptystring
li $a2, 0
li $v0, 15
syscall
move $a0,$t3
li $v0, 16
syscall
lw $t0, wordsfound
move $t0,$zero
sw $t0, wordsfound
jr $ra

####################################################
# CheckIfAlreadyGuessedWord: checks if the word typed in has already been guessed
# this is a function so call using jal
# Arguments:
#	userInputBuffer
# Uses registers:
#	$t0, $a0, $v0
# Returns:
#	$v1, (contains a 0 if no match found or a 1 if a match was found)
####################################################
CheckIfAlreadyGuessedWord:
la $a0, foundwordsFileName
li $a1, 0
li $a2, 0
li $v0, 13	#open the file for reading only
syscall

move $t4, $v0
move $t5, $zero

li $v0, 9
lw $t0, wordsfound
mul $t0, $t0, 9
move $a0, $t0
syscall			# Allocate space on the heap to read file from
move $t6, $v0		# Save pointer to heap space
move $a2, $a0

move $a0, $t4 
move $a1, $t6
move $a2, $t0
li $v0, 14		#read from file, and store on heap
syscall
move $t0,$v0

li $v0, 16
move $a0, $t4
syscall			#close Foundwords file

ble $t0,8 FWDone	#if chars read is less then 9 then we are at end of file and should report that no match was found


FindWordLoop:

move $t0,$zero
FWBuildRB:
lb $t1,($t6)	#load character at $t6 the Heap
beqz $t1 FWDone	#if found a 0 on the heap it means we are at end of file, so no match found
sb $t1,readbuffer($t0)
addi $t6,$t6,1
addi $t0,$t0,1
beq $t0, 9 FWDB
j FWBuildRB
FWDB:

sb $zero, readbuffer+9  #insert a null character at end of readbuffer
#addi $t5,$t5,9	#be ready for next word

#it will now compare readbuffer with userInputBuffer
move $t3, $zero
FWLoop:
	lb $t1,userInputBuffer($t3)	#load character at $t3 of UIB
	lb $t2, readbuffer($t3)		#load character at $t3 of RB
	add $t3,$t3,1			#move pointer to next byte
	beq $t1, $zero FWFound		#if newline or null then we have found a match
	beq $t1, 10 FWFound
	beq $t1, 39 FWSpec		#if char is ' then go to special case
	bne $t1, $t2 FindWordLoop	#if the bytes are not equal then this is not the right word, so check next one
	b FWLoop			#check next char
	
FWSpec:			#this solves the case where user types "loans" first and then types in "loan" for a later guess 
beq $t1, $t2 FWFound	#if the bytes are equal than this is a match
b FindWordLoop		#else move to next word	
	
FWFound:
li $v1,1	#a 1 in v1 means the word was found in the list
jr $ra

FWDone:
li $v1,0	#a 0 in v1 means the word was not found in the list
jr $ra


####################################################
# CheckWord: given user's input, check whether:
#	1. All of the characters are in the puzzle, with no duplicates allowed
#	2. The middle character in the puzzle was used
#	3. The input is a valid word
# Arguments:
#	$a0: user input
#	$s1: puzzle
# Uses registers:
#	nearly all of them
# Returns:
#	$v0 is a status code:
#		0: word satisfied all conditions
#		1: word was not in hashtable
#		2: word did not have the middle letter
#		3: word had characters other than those in the puzzle
####################################################
CheckWord:
sw $zero, bitArray	#bitArray has to be cleaned up from the last time it was called.
sw $zero, bitArray+4	#...
sh $zero, bitArray+8	#...done. (4+4+2 = 10 bytes of space)
li $t4, 1		#$t4 holds the value 1, solely for the purpose of storing it in bitArray[n].
move $t5, $a0		#preserve $a0 in $t5; $a0 is manipulated in CWCheckLettersLoop
lw $a1, ($s1)		#$a1: pointer to the puzzle string! (don't forget: $s1 is a pointer to a pointer!)
lb $t6, 4($a1)		#$t6 holds the middle character of the puzzle.

#This loop iterates over the characters in the user's input until it reaches
#a newline or null. (Only strings of nine characters have no newline character.)
#An interior loop, CWFindLetterInPuzzle, iterates FORWARD through the puzzle string
#while counting BACKWARD from 8 to 0; if the character from the input matches a character
#in the puzzle string, a 1 is written to bitArray[counter]. Note, therefore, that
#the order of bitArray is the opposite of the puzzle string; note, too, that this does not matter,
#because only the middle element is of interest after this loop and this would be bitArray[4] in either case.

CWCheckLettersLoop:
lb $t0, ($a0)			#$t0: one character from user's input
beqz $t0, CWLoopSuccess 	#null byte signals the end of a string
beq $t0, 10, CWLoopSuccess	#so does a newline
li $t1, 9			#set up interior loop: $t1 is loop counter
lw $a1, ($s1)			#$a1 now points to the first character of the puzzle string

CWFindLetterInPuzzle:		#The interior loop compares $t0 to each character in the puzzle.
subi $t1, $t1, 1		#It runs from 8 down to 0.
bltz $t1, CWFailLetterNotInPuzzle #If we've looked at all the letters in the puzzle already, then we haven't found $t0: fail.
lb $t2, ($a1)			#Get one character of puzzle in $t2;
addiu $a1, $a1, 1		#look at the next one.
beq $t0, $t6, CWFLIPMidLetter   #If the user's character is the middle character, handle it at CWFLIPMidLetter.
CWFLIPCheckDone:
beq $t0, $t2, CWFLIPDone	#If the two characters are the same, great. We're done with this character.
b CWFindLetterInPuzzle		#Otherwise, we have more characters to look at.
CWFLIPMidLetter:		#If the middle character was in the user's input,
sb $t4, bitArray+9		#toggle the special bit at bitArray[9].
b CWFLIPCheckDone		#We must branch back and find out where the middle character is in the puzzle,
				#toggling its bit; if this were not done, the user could use several of the middle
				#character with no penalty.
CWFLIPDone:

#But what if there are two of the same character in the user's input, or in the puzzle?
#We have to check whether the character CWFindLetterInPuzzle found has already been found on an
#earlier pass. To do this, we refer to the value of bitArray at the position the loop counter
#was at when it "succeeded."

lb $t3, bitArray($t1)		#Put the aforesaid value in $t3.
bnez $t3, CWFindLetterInPuzzle	#The character has already been found if and only if $t3 is not zero.
				#In that case, considering $t1, $a1, and $a0 have not changed, all we have
				#to do to find the next occurrence is branch back to CWFindLetterInPuzzle!
sb $t4, bitArray($t1)		#Otherwise, put the value 1 into bitArray at $t1.
addiu $a0, $a0, 1		#One character has successfully been found.
b CWCheckLettersLoop		#Let's try to find another.

CWLoopSuccess:

lb $t1, bitArray+9		#As previously mentioned, bitArray[9] is 1 iff the middle letter was somewhere in the input, 0 otherwise.
ble $t1, $zero, CWFailNoMidLetter #So, fail if bitArray[9] is 0.

#We are finally ready for the last test: putting the word through the hash table.
#Before we can do this, however, we must pad the word with `s at the end until 
#it is nine characters long, unless, of course, it is already nine characters long.
#(For an explanation of why this is, see hashtable.asm.)
#The good news is that CWCheckLettersLoop has done a lot of heavy lifting for us:
#	$t0 is a newline (if word is less than 9 chars), zero otherwise;
#	$a0 points to that newline or null character;
#	and $t5 points to the beginning of the user input.
#Therefore, the length of the input is simply $a0 - $t5!

li $t4, '`'
beqz $t0, CWFormatInputDone	#User input was nine characters; no padding.
sub $t0, $a0, $t5		#$t0 = length of string (see above)
li $t1, 9			#Number of terminal `s: (9 - $t0);
sub $t0, $t1, $t0		#now $t0 is the number of `s we need.
CWFIInsertPadding:		#(It will be used as a loop counter in this loop.)
sb $t4, ($a0)			#Put a ` into $a0, which, at the beginning of the loop, points to the end of a word.
addi $a0, $a0, 1		#Move to the next letter,
subi $t0, $t0, 1		#and decrease the loop counter.
beqz $t0, CWFormatInputDone	#If we're finished, finish.
b CWFIInsertPadding		#If we're not, insert another `.

CWFormatInputDone:

#At long last, we can check whether our string is in the hash table, 
#and thus whether it is an English word.

move $a0, $t5			#$t5 was never changed in the above loops; it remains a pointer to the user input.
push ($ra)
jal CheckInHashTable		#Save $ra and check the word!
pop ($ra)

#Now, $v0 is either 0 (on success) or 1 (on failure.)
#No further error handling is necessary, so return.

jr $ra

#The following are error conditions branched to by CheckWord, as specified by the header:

CWFailNotWord:
#Unnecessary; checkInHashTable returns 1 in $v0 if input is not in the table.

CWFailNoMidLetter:
li $v0, 2
jr $ra

CWFailLetterNotInPuzzle:
li $v0, 3
jr $ra

####################################################
# handleCommand: handles the command in $a0.
# Supported commands:
#	q: quit
#	h: help
#	r: restart
#	s: shuffle
#	t: display current time
# Note: this is not a function. Don't use "jal handleCommand",
# use "b handleCommand" instead.
####################################################

handleCommand:
li $t4, 0
lb $t0, 1($a0)
la $t1, quit
CheckCommandList:
lb $t2, ($t1)
beqz $t2, notfound
beq $t0, $t2, found
add $t1, $t1, 1
add $t4, $t4, 1
j CheckCommandList
found:
bgt $t4, 0, gzero	
j quitProgram		#quit
gzero:
bgt $t4, 1, gone	
li $v0, 4		#help
la $a0, help
syscall
j HCCommandDone
gone:
bgt $t4, 2, gtwo
j startgame		#restart
gtwo:
bgt $t4, 3, gthree
lw $v1, ($s1)		#shuffle
lb $t4, 4($v1)		#holds the middle char before shuffle
push ($t4)
push ($t0)
li $t0, 8
addu $v1, $v1, $t0
move $t1, $s1
jal GPShuffleLoop
pop ($t4)
li $t1, 0
lb $t5, 4($v1)		#holds the current middle char
beq $t4, $t5, midCharCorrect	#checks to see if it is holding the correct char
findPastMidLoop:		#find the location of the middle char
lb $t0, ($v1)
beq $t4, $t0, midLocated
add $v1, $v1, 1
add $t1, $t1, 1
j findPastMidLoop
midLocated:
sb $t5, ($v1)			#put the wrong mid char in the place where the true mid is
sub $v1, $v1, $t1		#return to pointing to the beginning
sb $t4, 4($v1)			#store true mid at the mid
midCharCorrect:
j HCCommandDone			#print puzzle and continue
gthree:
bgt $t4, 4, gfour
jal printTime
j HCCommandDone
gfour:
bgt $t4, 5, gfive
sw $zero, timeleft		#burn out the clock
j HCCommandDone
gfive:
notfound:
li $v0, 4
la $a0, out
syscall
HCCommandDone:
j gameInputLoop


####################################################
# PrintPuzzle: prints a textual representation of
# the current puzzle, along with the game's status (score and time.)
# For example, if the puzzle is "123456789", 
# /-------------\
# |  1   2   3  |
# |  4   5   6  |
# |  7   8   9  |
# \-------------/
# (score and time information)
# will be printed to the console.
# The appearance of the box can be changed without too much, if any, change
# made to this function, since the parts of the box are stored in strings like
# boxTopBar, boxSeparator, etc. What this function actually prints to the screen is:
# [TB]
# [LB]1[S]2[S]3[RB] (3 times)
# [BB]
# After printing this, printTime is called.
#
# Note: this function does not print newlines. They must be included in [TB], [RB], etc.
# Arguments:
#	$s1: pointer to the puzzle (a nine-char string)
# Uses registers:
#	$a0-1, $v0, $t0
# Returns:
#	nothing
####################################################
PrintPuzzle:
push ($ra)
lw $a1, ($s1)
la $a0, boxTopBar
li $v0, 4
syscall
li $t0, 3
PPBoxLoop:
subiu $t0, $t0, 1
la $a0, boxLeftBar
syscall
jal PPNextChar
la $a0, boxSeparator
li $v0, 4
syscall
jal PPNextChar
la $a0, boxSeparator
li $v0, 4
syscall
jal PPNextChar
la $a0, boxRightBar
li $v0, 4
syscall
bnez $t0, PPBoxLoop
la $a0, boxBottomBar
li $v0, 4
syscall
jal printTime
pop ($ra)
jr $ra
PPNextChar:
lb $a0, ($a1)
li $v0, 11
addiu $a1, $a1, 1
syscall
jr $ra


####################################################
# ScoreCheck: takes the word and calculates a score based on the word
# this is a function so call using jal
# Arguments:
#	userInputBuffer (the string the user has typed in)
# Uses registers:
#	$t0-3
# Returns:
#	$v1 (amount of points earned for this word)
####################################################
ScoreCheck:	#gg ScoreCheck intials are SC just like StringCompare, so it errored at first time cause SCLoop was defined twice
push($ra)
move $v1,$zero
move $t3,$zero
SCKLoop:
	lb $t1,userInputBuffer($t3)	#load character at $a2
	add $t3,$t3,1
	beq $t1,$zero SCKDone
	beq $t1,10 SCKDone
	move $t0,$zero
	SCKP1L:
		lb $t2, points1($t0)
		beq $t2,$zero SCKP1LD
		beq $t2,10 SCKP1LD
		add $t0,$t0,1	
		bne $t1,$t2 SCKP1L
		add $v1,$v1,1
		b SCKLoop
	SCKP1LD:
	move $t0,$zero
	SCKP2L:
		lb $t2, points2($t0)
		beq $t2,$zero SCKP2LD
		beq $t2,10 SCKP2LD
		add $t0,$t0,1	
		bne $t1,$t2 SCKP2L
		add $v1,$v1,2
		b SCKLoop
	SCKP2LD:
	move $t0,$zero
	SCKP3L:
		lb $t2, points3($t0)
		beq $t2,$zero SCKP3LD
		beq $t2,10 SCKP3LD
		add $t0,$t0,1	
		bne $t1,$t2 SCKP3L
		add $v1,$v1,3
		b SCKLoop	
	SCKP3LD:
	move $t0,$zero	
	SCKP4L:
		lb $t2, points4($t0)
		beq $t2,$zero SCKLoop
		beq $t2,10 SCKLoop
		add $t0,$t0,1	
		bne $t1,$t2 SCKP4L
		add $v1,$v1,4
		b SCKLoop			
SCKDone:	
pop($ra)
jr $ra


####################################################
# printTime: displays the time remaining and his/her score to the client
# this is a function so call using jal
# Arguments:
#	none
# Uses registers:
#	$s2 (holds the time from last calculated), $t0, $a0, $v0
# Returns:
#	nothing
####################################################
printTime:
push ($ra)
push ($a0)	#preserve these registers
push ($a1)

jal CheckTime	#check and updates time left

blez $v1, GameFinished	#if out of time you're done

la $a0, timemessage1	#print Time left sentence
li $v0, 4
syscall

la $a0, ($v1)
li $v0, 1
syscall

la $a0, timemessage2
li $v0, 4
syscall

lw $t0,score
la $a0, ($t0)
li $v0, 1
syscall

la $a0, newline
li $v0, 4
syscall

pop ($a1)	#give back
pop ($a0)
pop ($ra)
jr $ra


####################################################
# CheckTime: check if user still has time left
# Will branch to GameFinished if time left is negative or zero
# this is a function so call using jal
# Arguments:
#	none
# Uses registers:
#	$s2 (holds the time from last calculated), $t0, $a0, $v0
# Returns:
#	timeleft in $v1
####################################################
CheckTime:
move $t0,$s2		#move time from last check into t0
li $v0, 30		#get time
syscall
move $s2,$a0		#move caculated time into $s2
sub $a0,$a0,$t0		#subtract current time from previous time to get the difference
div $a0,$a0,1000	#convert milliseconds to seconds, if faster way feel free to change it
lw $t0 timeleft		#fetch timeleft from last caculated 
sub $t0,$t0,$a0		#subtract the difference from the timeleft
sw $t0, timeleft	#save it as the new timeleft
move $v1,$t0		#move timeleft into $v1
jr $ra			

####################################################
# SetTime: resets timer to 120 seconds and sets $s2 to current time
# this is a function so call using jal
# Arguments:
#	none
# Uses registers:
#	$s2, $a0, $v0
# Returns:
#	nothing
####################################################
SetTime:
push ($a0)		#preserve these registars, incase used else where
push ($a1)
li $v0, 30		#syscall 30 is fetch Time
syscall
move $s2,$a0
add $a0,$zero,120	#put 120 seconds on the clock
sw $a0 timeleft		#store the time in the timeleft label
pop ($a1)		#give back values of a0 and a1
pop ($a0)
jr $ra


####################################################
# GenPuzzle: picks a random entry in the array of nine-character words;
# then, scrambles the string, and returns a pointer to it.
# Arguments:
#	none
# Uses registers:
#	$a0, $a1, $v0
# Returns:
#	$v0: a pointer to the string
####################################################
GenPuzzle:
push ($t0)
li $v0, 30	#syscall 30 gets system time as a 64-bit int.
syscall 	#It is placed in $a0 and $a1;
li $v0, 42 	#42 gets a random number in a range,
move $a0, $a1
li $a1, WORDS_IN_NINECHAR_DICT #where $a1 is the upper bound (lower bd. is 0)
subiu $a1, $a1, 1
syscall 		#and $a0 is a random seed!
sll $a0, $a0, 2
la $v1, nineCharArray
lw $v1, ($v1)
addu $a0, $a0, $v1	#a0 points to the random string.
#Now, we will scramble the string.
#NOTE: the string is NOT copied before it is scrambled.
#The original is being scrambled, and this is OK iff (since)
#nothing special happens when the user finds the puzzle's seed.
move $t1, $a0
lw $v1, ($a0)		#$v1 points to the first character of the string
li $t0, 8
addu $v1, $v1, $t0	#now it points to the last character of the string
GPShuffleLoop:
beqz $t0, GPEnd
li $v0, 42 		#Generate random int...
move $a1, $t0		#between 0 and the loop counter.
move $a0, $t1
syscall			#Note: the pointer to the string is used as a random seed
addiu $a0, $a0, 1
subu $v0, $v1, $a0	#$v0 points to a random character in the string
lb $t2, ($v1)
lb $t3, ($v0)
sb $t3, ($v1)
sb $t2, ($v0)
subiu $t0, $t0, 1
subiu $v1, $v1, 1
b GPShuffleLoop
GPEnd:
move $v0, $t1
pop ($t0)
jr $ra


####################################################
# PressKeyToContinue: Pauses program until an alphanumeric key is pressed
# 
# Arguments:
#	none
# Uses registers:
#	$v0
# Returns:
#	Nothing
####################################################
PressKeyToContinue:
li $v0, 12
syscall		# "Pauses" by trying to read a char from the keyboard

li $v0, 4
la $a0, backspace
syscall		# Removes typed char  (Doesn't right now, any ideas how to fix this?)

jr $ra

####################################################
# PrintSplashScreen: Prints out the splah screen and calls PressKeyToContinue
# 
# Arguments:
#	none
# Uses registers:
#	$v0, $a0, $a1, $a2, $t0, $t1
# Returns:
#	Nothing
####################################################
PrintSplashScreen:
li $v0, 13
la $a0, splashscreenfilename
li $a1, 0
syscall			# Open the SplashScreen file
move $t0, $v0		# Save file descriptor

li $v0, 9
li $a0, 300
syscall			# Allocate space on the heap to print from
move $t1, $v0		# Save pointer to heap space

li $v0, 14
move $a0, $t0
move $a1, $t1
li $a2, 300
syscall			# Read up to 250 chars from file into heap

li $v0, 16
move $a0, $t0
syscall			# Close SplashScreen file

li $v0, 4
move $a0, $t1
syscall			# Print file from heap

push ($ra)

jal PressKeyToContinue

pop ($ra)
jr $ra

####################################################
# PrintFinishScreen: Prints out the finish screen and the Words you Found
# 
# Arguments:
#	none
# Uses registers:
#	Alot
# Returns:
#	Nothing
####################################################
PrintFinishScreen:
li $v0, 4
la $a0, GameFinishedMessage
syscall			# Print Finished message


la $a0, foundwordsFileName
li $a1, 0
li $a2, 0
li $v0, 13	#open the file for reading only
syscall

move $t4, $v0
move $t5, $zero

li $v0, 9
lw $t0, wordsfound
mul $t0, $t0, 9
move $a0, $t0
syscall			# Allocate space on the heap to read file from
move $t6, $v0		# Save pointer to heap space
move $a2, $a0

move $a0, $t4 
move $a1, $t6
move $a2, $t0
li $v0, 14		#read from file, and store on heap
syscall
move $t0,$v0

li $v0, 16
move $a0, $t4
syscall			#close Foundwords file

ble $t0,8 PFSDone	#if chars read is less then 9 then we are at end of file and should report nothing was found


PFSLoop:

move $t0,$zero
PFSBuildRB:
lb $t1,($t6)	#load character at $t6 the Heap
beqz $t1 PFSDone	#if found a 0 on the heap it means we are at end of file, so no match found
sb $t1,readbuffert($t0)
addi $t6,$t6,1
addi $t0,$t0,1
beq $t0, 9 PFSDB
j PFSBuildRB
PFSDB:
li $t0, 10
sb $t0, readbuffert+9  #insert a newline character at almost end of readbufferE
sb $zero, readbuffert+10  #insert a null character at end of readbufferE

li $v0, 4
la $a0, readbuffert
syscall			# Print extracted string with padding
j PFSLoop

PFSDone:
li $v0, 4
la $a0, PressKeyToCon
syscall			# Print Key Message
jr $ra


GameFinished:
la $a0, outoftimemsg	#prints that your last guess was not counted cause out of time
li $v0, 4
syscall
jal PrintFinishScreen



jal PressKeyToContinue	# allow time to view the ending screen

b quitProgram		#possible replace this with a branch to New Round

quitProgram: #quit
jal ClearFile
li $v0, 10
syscall

.include "hashtable.asm"
