.data
# DONOTMODIFYTHISLINE
frameBuffer: .space 0x80000 # 512 wide X 256 high pixels
w: .word 100 # width (needs to be less than or equal to 512).
h: .word 0 # height (needs to be less than or equal to 256).
l: .word 40 # length 
bgcol: .word 0xD2B48C # Background color
# DONOTMODIFYTHISLINE
# Your variables go BELOW here only (and above .text)
.text
la $s4,frameBuffer # $t0 <-- frameBuffer base address
lw $s3, bgcol # $s3 <-- bgcol 
li $t2, 0 # $t2<-- 1 (our counter for drawing the background.)
lw $s0, w # $s0 <-- w (width)
lw $s1, h # $s1 <-- h (height)
lw $s2, l # $s2 <-- l (length)

inputValidation: # checking if the input dimension values are valid cases.
	li $t7, 1 # will use as a boolean value based on output below. (1 = valid, 0 = not valid)
	li $t6, 512 # $t6 <-- 512
CheckWidth:
	ble $s0, 512, CheckWidthGreaterthanCap # if w <= 512, branch to CheckHeight
	li $t7, 0 # if did not jump to CheckHeight, $t7 = 0 ( not valid dimension )
CheckWidthGreaterthanCap: # Check if the width is greater than the cap width of 60
	lw $s0, w
	bgt $s0, 60, CheckWidthEven # If width input is greater than 60, its a valid input.
	li $t7, 0 # if did not jump to CheckWidthEven, $t7 = 0 ( not valid dimension )
CheckWidthEven: # check if the width is even so the flask can be centered. check by returning least significant bit value of w.
	andi $t1, $s0, 1 # $t1 <-- getting the least significant bit for the value of the width.
	beq $t1, 0, CheckHeight # if 0, that means the width is even. else odd.
	li $t7, 0 # width is not even.
CheckHeight:
	ble $s1, 256, CheckLength # if h is <= 256, valid and jump to CheckLength
	li $t7, 0 # if did not branch to CheckLength, $t7 = 0 ( not valid dimension )
CheckLength:
	ble $s2, $t6, CheckHeightplusLength # if length <= $t6, 
	li $t7, 0 # if did not branch to drawBackground, $t7 = 0 ( not valid dimension )
CheckHeightplusLength: # checking if the height + length is even.
	lw $s1, h
	lw $s2, l
	add $t1, $s1, $s2 # $t1 <-- h + l
	andi $t1, $t1, 1 # $t1 <-- getting the least significant bit for the value of the width.
	beq $t1, 0, CheckHeightplusLength2 # if 0, that means even. else odd.
	li $t7, 0 # width is not even.
CheckHeightplusLength2: # checking if the height and length is greater than one so there is something to draw. this means either can be 0 but one needs to be greater.
	add $t1, $s1, $s2 #Add the height and length
	bge $t1, 1, drawBackground # checking if height plus length is greater than or equal to 1.
	li $t7, 0 # if did not jump, not a valid case and not greater or equal to 1.

CheckHeightOrLengthZero: # checking if either the height or the length is set to 0.	
bgt $s1, $zero, checkLength #if height is greater than 0, its valid.
add $s1, $zero, $s2 # if didnt jump to check width. its not greater than 0.
checkLength:
bgt $s2, $zero, drawBackground #if length is greater than 0, its valid.
add $s2, $zero, $s1 # if didnt jump, its not valid.


drawBackground: # setting the background color at each pixel.
	beq $t2, 131072,checkBool # while $t2 != to the last pixel memory address.
	sll $t3, $t2, 2 # $t3 <-- ( (2^2 = 4) * $t2 ) (example.. 1 (counter) = 1 * 4, 2 (counter) = 2 * 4).
	add $t3, $t3, $s4 # $t3 <- $t3 (offset) + $t0 (frame buffer) 
	sw $s3, 0($t3) # add color to current pixel after calculating frame buffer address + offset
	addi $t2, $t2, 1 # $t2 <-- increment counter
	j drawBackground #looping again.
	
	
checkBool: # Checking if validation cases passed. if a dimension is not valid, the program will exit with only the background drawn.
beq $t7, $zero, Finished # branch to finished.


centerWidth: # Getting the coordinates for centering the width 
	li $t0, 512
	lw $s0, w # $s0 <-- w
	sub $t0, $t0, $s0 # $t0 <-- 512 - w
	srl $t0, $t0, 1 # $t0 <-- (512 - w) / 2^1 which has the center of the WIDTH of the display (y)s
	#now center the cap width (60) onto the given width inputted plus the middle width calculated before.
	addi $t7, $s0, -60
	srl $t7, $t7, 1 # divide by 2
	add $t0, $t0, $t7 #now move the cap to the center of the w.

getStartingHeight: # getting the amount of rows down to start the cap.
lw $s0, w # load width
lw $s1, l # load length
lw $s2, h # load height
bne $s2, 0, continue # checking id height is set to 0. if it is, se the height to length.
add $s2, $s1, $zero # setting the height to the length since height input is 0.
continue: # checcking the length is 0.
lw $s1, l
bne $s1, 0, continue4 # checking if length is set to 0. if it is, set the length to the height.
add $s1, $s2, $zero # setting the length to height since length input was 0.
continue4:
addi $t7, $s0, -48 # getting the difference between width and 48 ex 112
srl $t7, $t7, 1 # shift right logical which effectively divides by 2, which is height of trapezoid. ex 56
addi $t7, $t7, 64 # height of trapezoid + cap + body under cap
add $t7, $t7, $s2 # adding the input height
add $t7, $t7, $s1 # adding the input length, now we got the entire height of the flask. ex 230
bgt $t7, 256, Finished # if the flask height is greater than 256, it is not valid and end the program.
andi $t3, $t7, 1 # $t1 <-- getting the least significant bit for the height of the flask.
beq $t3, 1, Finished # if 1, flask entire height is not valid centerable height so branch to exit the program.
li $t3, 256 # display max height
sub $t7 $t3, $t7 # difference in 256 - height of bottle. ex 26
srl $t7, $t7, 1 # divide by 2, and now you have the starting HEIGHT coordinate (x). 13 + 230 + 13 = start 13 rows under.

li $t2, 0 # $t2 <-- 0 (counter for how many times we looped)
li $t3, 0 # $t3 <-- 0 ( used to store product of loop)
	
#loop formula to get the center of the screen top = w (half ) * 4
multiplying: # x coordiate * bytes to get the address of the center top
	beq $t2, $t0, updateOffset1 #once count reaches x coordinate, we have muliplied everything
	addi $t2, $t2, 1 # incrementing amount we have looped.
	addi $t3, $t3, 4
	j multiplying # loop again.

updateOffset1: #updating offset to move to the middle of the screen.
add $s5, $s4, $t3 # offset stored to the middle of the screen.

li $t2, 0 # $t2 <-- 0 (counter for how many times we looped)
li $t3, 0 # $t3 <-- 0 ( used to store product of loop)

# loop formula to get the starting height.
multiplying2: # getting the starting height
	beq $t2, $t7, updateOffset2 #once count reaches y coordinate, we have muliplied everything
	addi $t2, $t2, 1 # incrementing amount we have looped.
	addi $t3, $t3, 2048 # moving rows
	j multiplying2 # loop again.

updateOffset2: # updating offset to move to the middle of the screen.
add $s5, $s5, $t3 # offset stored to the middle of the screen with starting row. start building the cap.


DrawCap: #drawing the trueblue cap. $s5 is set to the starting point of the cap. cap is 60 x 32
li $t9, 0x0073cf # $t1 (bgcol) <-- setting to true blue color.

li $t7, 0 # $t0 <-- 0 (counter which will keep track of the amount of rows filled, aka height).
li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row, width).

j drawCol1 # beginning to draw the row.
	
row1: # jumping to the next row.
	addi $t7, $t7,1 # keeping track of rows filled.
	beq $t7, 32, DrawFlaskBody # if $t0 = 32, all rows have been filled, jump to the next shape,
	li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row).
	
drawCol1:
	beq $t4, 60, row1 # if $t4 = w, all pixels for this row have been filled, so jump to next row.
	# drawing the liquid color to the current pixel.
	sll $t3, $t7, 9 # $t3 <-- $t0 * 512 (2^9 = 512). This will help get the address of the row we are currently. (1 = 512, 2 = 1024..)
	add $t3, $t3, $t4 # $t3 <-- $t3 + $t4 (current row and pixel)
	sll $t3, $t3, 2 # $t3 <-- $t3 * 4 (each pixel is 4 bytes long).
	add $t3, $t3, $s5 # going to the center of the screen.
	sw $t9, 0($t3) # setting the color to the current pixel and offset which starts at half of the screen,
	addi $t4, $t4, 1 # $t4 < $t4 + 1 (keeping tracking of the amount of pixels filled).
	j drawCol1 # continue to fill out each pixel.
	
DrawFlaskBody: #begin drawing the flask body which is 32 rows, 48 width below and starts drawing 6 bytes to the right.

moveSix: #updating $s5
addi $s5, $s5, 24 # moving to 6 bytes to right so flask body is centered and have the cap overhand by 6 pixels.

li $t2, 0 # $t2 <-- 0 (counter for how many times we looped)
li $t3, 0 # $t3 <-- 0 ( used to store product of loop)

# loop formula to get the starting height.
multiplying3: # getting the starting height
	beq $t2, 32, updateOffset3 #once count reaches y coordinate, we have muliplied everything
	addi $t2, $t2, 1 # incrementing amount we have looped.
	addi $t3, $t3, 2048 # moving rows
	j multiplying3 # loop again.

updateOffset3:
add $s5, $s5, $t3 # offset for flask body now starts 6 bytes to the side, 32 rows under for height building.


li $t7, 0 # $t0 <-- 0 (counter which will keep track of the amount of rows filled, aka height).
li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row, width).

lw $s3, bgcol # $s3 <-- bgcol
srl $t9, $s3, 1 # shift right logical which effectively divides the color by 2 to get color for flask.

j drawCol2 # beginning to draw the row.
	
row2: # jumping to the next row.
	addi $t7, $t7,1 # keeping track of rows filled.
	beq $t7, 32, DrawTrapezoid # if $t0 = 32, all rows have been filled, jump to the next shape,
	li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row).
	
drawCol2:
	beq $t4, 48, row2 # if $t4 = w, all pixels for this row have been filled, so jump to next row.
	# drawing the liquid color to the current pixel.
	sll $t3, $t7, 9 # $t3 <-- $t0 * 512 (2^9 = 512). This will help get the address of the row we are currently. (1 = 512, 2 = 1024..)
	add $t3, $t3, $t4 # $t3 <-- $t3 + $t4 (current row and pixel)
	sll $t3, $t3, 2 # $t3 <-- $t3 * 4 (each pixel is 4 bytes long).
	add $t3, $t3, $s5 # going to the center of the screen.
	sw $t9, 0($t3) # setting the color to the current pixel and offset which starts at half of the screen,
	addi $t4, $t4, 1 # $t4 < $t4 + 1 (keeping tracking of the amount of pixels filled).
	j drawCol2 # continue to fill out each pixel.


DrawTrapezoid: #trapezoid starts 32 rows below and has a height of (w - 48) / 2

li $t2, 0 # $t2 <-- 0 (counter for how many times we looped)
li $t3, 0 # $t3 <-- 0 ( used to store product of loop)

# loop formula to get the starting height.
multiplying4: # getting the starting height
	beq $t2, 32, updateOffset4 #once count reaches y coordinate, we have muliplied everything
	addi $t2, $t2, 1 # incrementing amount we have looped.
	addi $t3, $t3, 2048 # moving rows
	j multiplying4 # loop again.
	
updateOffset4:
	add $s5, $s5, $t3 # offset now starts 32 rows below body of flask.
	
trapezoidHeight: # calc trapezoid height (w - 48 ) / 2
lw $s0, w # $s0 <-- load the width.
srl $t9, $s3, 1 # shift right logical which effectively divides the color by 2 to get color for flask. 

addi $s6, $s0, -48 # getting the difference between width and 48
srl $s6, $s6, 1 # shift right logical which effectively divides by 2, which is height of trapezoid.

li $t0, 0 # $t0 <-- 0 (counter which will keep track of the amount of rows filled, aka height).
li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row, width).
li $t7, 48 # starts at 48 and will keep incrementing by 2 for the size of each row under it.
add $t2, $s6, $zero #storing height of trapezoid / bytes to the side.

j drawCol3 # beginning to draw the row.

row3: # jumping to the next row.
	addi $t0, $t0,1 # keeping track of rows filled ( height)
	addi $t7 , $t7, 2 # increment row size from (48 to 50 example) 
	sll, $t5, $t2, 2 # getting the amount of bytes to move by for the next row.
	addi $s5, $s5, -4
	li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row).
	beq $t0, $s6, DrawFlaskHeight # if $t0 = height of trapezoid, all rows have been filled, jump to the next shape, flask.
drawCol3:
	beq $t4, $t7, row3 # if $t4 = w, all pixels for this row have been filled, so jump to next row.
	# drawing the liquid color to the current pixel.
	sll $t3, $t0, 9 # $t3 <-- $t0 * 512 (2^9 = 512). This will help get the address of the row we are currently. (1 = 512, 2 = 1024..)
	add $t3, $t3, $t4 # $t3 <-- $t3 + $t4 (current row and pixel)
	sll $t3, $t3, 2 # $t3 <-- $t3 * 4 (each pixel is 4 bytes long).
	add $t3, $t3, $s5 # $t3 <-- $t3 + $s4 (adding the frame buffer base address).
	sw $t9, 0($t3) # setting the color to the current pixel and offset which starts at half of the screen,
	addi $t4, $t4, 1 # $t4 < $t4 + 1 (keeping tracking of the amount of pixels filled).
	j drawCol3 # continue to fill out each pixel

DrawFlaskHeight: #drawing the flask section that utlizes height. move offset height of the trapezoid downward.

li $t5, 0 # $t2 <-- 0 (counter for how many times we looped)
li $t3, 0 # $t3 <-- 0 ( used to store product of loop)
lw $s1, h # $s1 <-- load height.

# loop formula to get the starting height.
multiplying5: # getting the starting height
	beq $t5, $s6, updateOffset5 #once count reaches y coordinate, we have muliplied everything
	addi $t5, $t5, 1 # incrementing amount we have looped.
	addi $t3, $t3, 2048 # moving rows
	j multiplying5 # loop again.
	
updateOffset5:
	add $s5, $s5, $t3 # offset now starts height of the flask
	
lw $s1, h # $s1 <-- h loading the height.

bne $s1, 0, continue2 # checking if height is set to 0. if it is, set the height to length and also change to liquid color, else continue without modification to h.

lw $s3, bgcol # will set to liquid color.
srl $t6, $s3, 16 # get the red component of bgcol by shifting by 16 bits
andi $t7, $s3, 0x00FF00 # extract green hex value to mix.
andi $t8, $s3, 0x0000FF # extract blue from bgcol.
sll $t5, $t8, 16 # blue goes to red.
srl $t5, $t5, 16 # blue goes back with its modified value.
sll $t1, $t6, 0 # red goes to blue position.
or $t0, $t5, $t7 # #green and blue are masked together
or $t9, $t1, $t0 # t9 now has the liquid color after shifting bytes. red is masked with the result of green and blue mask.

lw $s2, l # $s2 <-- length
add $s1, $s2, $zero # height is set to length.

continue2:
#COUNTERS FOR LOOPING 
	li $t0, 0 # $t0 <-- 0 (counter which will keep track of the amount of rows filled, aka height).
	li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row, width).
	
j drawCol4 # beginning to draw the row.
	
row4: # jumping to the next row.
	addi $t0, $t0,1 # keeping track of rows filled.
	beq $t0, $s1, DrawLiquid # if $t0 = h, all rows have been filled, jump to the next shape, liquid
	li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row).
	
drawCol4:
	beq $t4, $s0, row4 # if $t4 = w, all pixels for this row have been filled, so jump to next row.
	# drawing the liquid color to the current pixel.
	sll $t3, $t0, 9 # $t3 <-- $t0 * 512 (2^9 = 512). This will help get the address of the row we are currently. (1 = 512, 2 = 1024..)
	add $t3, $t3, $t4 # $t3 <-- $t3 + $t4 (current row and pixel)
	sll $t3, $t3, 2 # $t3 <-- $t3 * 4 
	add $t3, $t3, $s5 # $t3 <-- $t3 + $s4 (adding the frame buffer base address with the row modified.
	sw $t9, 0($t3) # setting the color to the current pixel and offset which starts at half of the screen,
	addi $t4, $t4, 1 # $t4 < $t4 + 1 (keeping tracking of the amount of pixels filled).
	j drawCol4 # continue to fill out each pixel.

DrawLiquid: # begin drawing the liquid.
lw $s3, bgcol # $t3 <-- bgcol

li $t0, 0 # counter that will loop h times
li $t4, 0 # keep track of offset value ro update

bne $s1, 0, getOffset6 # checking id height is set to 0. if it is, se the height to length.
lw $s2, l # load the length.
add $s1, $s2, $zero # setting the height to the length.

#Set offset to below the flask 
getOffset6:
	beq $t0, $s1, updateOffset6 #Loop until we calculate an offset that will draw the liquid under the flask. (loop until h reached)
	addi $t0, $t0, 1 #increment times we loop
	addi $t4, $t4, 2048 # incrementing by 2048 which is the amount of bytes per row ( 512 * 4)
	j getOffset6
	
updateOffset6:
	add $s5, $s5, $t4 # offset now starts height of the flask below
	
liquidColor: # getting the color for the liquid which is the blue and red components swapped.
lw $s3, bgcol # will set to liquid color.
srl $t6, $s3, 16 # get the red component of bgcol by shifting by 16 bits
andi $t7, $s3, 0x00FF00 # extract green component from bgcol.
andi $t8, $s3, 0x0000FF # extract blue component from bgcol.
sll $t5, $t8, 16 # blue goes to red by shifting to the left
srl $t5, $t5, 16 # blue returns to its location with its updated value
sll $t1, $t6, 0 # red goes to blue position.
or $t0, $t5, $t7 # blue and green masked together
or $t9, $t1, $t0 # t9 now has the liquid color after shifting and bit masking. masking blue and green with red.

lw $s2, l # $s2 <-- length
bne $s2, 0, Counters7 # checking if length is not set to 0. 
lw $s1, h # load the height
add $s2, $s1, $zero # setting the length to height.
lw $s3, bgcol # load bgcol
srl $t9, $s3, 1 # shift right logical which effectively divides the color by 2 to get color for flask.

Counters7:
	li $t0, 0 # $t0 <-- 0 (counter which will keep track of the amount of rows filled, aka height).
	li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row, width).

j drawCol5 # beginning to draw the row.
	
row5: # jumping to the next row.
	addi $t0, $t0,1 # keeping track of rows filled.
	beq $t0, $s2, Finished # if $t0 = l, all rows have been filled, jump to the next shape, flask.
	li $t4, 0 # $t4 <-- 0  (counter which will be used to keep track of amount of pixels filled at row).
	
drawCol5:
	beq $t4, $s0, row5 # if $t4 = w, all pixels for this row have been filled, so jump to next row.
	# drawing the liquid color to the current pixel.
	sll $t3, $t0, 9 # $t3 <-- $t0 * 512 (2^9 = 512). This will help get the address of the row we are currently. (1 = 512, 2 = 1024..)
	add $t3, $t3, $t4 # $t3 <-- $t3 + $t4 (current row and pixel)
	sll $t3, $t3, 2 # $t3 <-- $t3 * 4 each pixel is 4 bytes long.
	add $t3, $t3, $s5 # $t3 <-- $t3 + $s4 ( adding to the frame buffer with modified row and location in the width. )
	sw $t9, 0($t3) # setting the color to the current pixel and offset which starts at half of the screen,
	addi $t4, $t4, 1 # $t4 < $t4 + 1 (keeping tracking of the amount of pixels filled).
	j drawCol5 # continue to fill out each pixel

Finished:
li $v0,10 # exit code
syscall # exit to OS
