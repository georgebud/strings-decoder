extern puts
extern printf
extern strlen

%define BAD_ARG_EXIT_CODE -1

section .data
filename: db "./input0.dat", 0
inputlen: dd 2263

fmtstr:            db "Key: %d",0xa, 0
usage:             db "Usage: %s <task-no> (task-no can be 1,2,3,4,5,6)", 10, 0
error_no_file:     db "Error: No input file %s", 10, 0
error_cannot_read: db "Error: Cannot read input file %s", 10, 0

section .text
global main

xor_strings:
	push ebp
	mov ebp, esp
	mov ecx, [ebp + 8]		;ecx = address of input string
	mov eax, [ebp + 12]		;eax = address of key string
	xor edx, edx			;edx = counter for both strings

decode1:
	mov bl, byte[ecx + edx]	;each character from input string
	test bl, bl 			;check if the string is over
	je out1
	xor bl, byte[eax + edx]	;xor with byte from the same position in key string
	mov byte[ecx + edx], bl ;replace decoded byte in string
	inc edx					;counter
	jmp decode1

out1:
	leave
	ret

rolling_xor:
	push ebp
	mov ebp, esp
	mov ecx, [ebp +8]		;ecx = address of input string
	mov eax, [ebp + 12]		;eax = last byte of string
	mov edx, eax			;edx = used for parsing string

decode2:
	cmp edx, ecx			;check if all string was parsed
	je out2	

	dec edx
	mov bl, byte[edx]
	xor bl, byte[eax]
	mov byte[eax], bl 		;replace decoded byte in string
	dec eax
	jmp decode2

out2:
	mov ecx, eax
	leave
	ret

xor_hex_strings:
	push ebp
	mov ebp, esp
	xor ebx, ebx
	xor eax, eax			;eax = counter
	xor edx, edx			;edx = counter
	mov ecx, [ebp + 8]		;ecx = address of input string
	sub esp, 8
	mov edi, 4

decode3:
	mov bl, byte[ecx + edx]	;take first byte
	inc edx
	test bl, bl 			;test if string is over
	je out3

	cmp bl, 97				;check if letter 
	jge letter
	sub bl, '0'				;transform from ASCII code into right number

continue1:
	shl ebx, 4				;multiply with 16
	mov esi, ebx
	xor ebx, ebx

	mov bl, byte[ecx + edx]	;take second byte
	cmp bl, 97
	jge letter2
	sub bl, '0'

continue2:
	add esi, ebx			;esi stores the sum in decimal
	mov ebx, esi
	mov byte[ecx + eax], bl ;replace with formed byte

	inc eax
	inc edx
	xor ebx, ebx
	jmp decode3

letter:
	sub bl, 87				;transform letter into number
	jmp continue1

letter2:
	sub bl, 87
	jmp continue2

out3:
	mov eax, 4
	cmp edi, eax			;check if binary formed message was saved on stack
	je put1

	mov eax, 8
	cmp edi, eax			;check if binary formed key was saved on stack
	je put2

put1:
	mov [ebp - 4], ecx 		;save binary formed message on stack
	jmp continue3			;time to transform key string in binary form

put2:
	mov [ebp - 8], ecx		;save binary formed key on stack
	jmp out4				;ready for XORing strings

continue3:
	mov edi, 8 
	xor eax, eax
	xor ebx, ebx
	xor edx, edx
	mov ecx, [ebp + 12]		;address of key string
	jmp decode3				;repeat procedure

out4:
	mov ecx, [ebp - 4]		;ecx = binary formed message
	mov eax, [ebp - 8]		;eax = binary formed key
	add esp, 8 				;free
	xor ebx, ebx
	xor edx, edx
	xor edi, edi
	jmp decode1				;same as in task1

base32decode:
	; TODO TASK 4
	ret

bruteforce_singlebyte_xor:
	push ebp
	mov ebp, esp
	mov ecx, [ebp + 8]		;ecx = address of input string
	xor edx, edx			;edx = counter
	xor eax, eax			;eax = key
	mov al, 142

decode5:
	mov bl, byte[ecx + edx]
	test bl, bl
	je out5

	xor bl, al
	mov byte[ecx + edx], bl ;replace decoded byte in string
	inc edx
	jmp decode5

out5:
	leave
	ret

decode_vigenere:
	push ebp
	mov ebp, esp
	mov ecx, [ebp + 8]		;ecx = address of input string
	mov eax, [ebp + 12]		;eax = address of key string
	xor edi, edi 			;edi = counter in key string
	xor esi, esi			;esi = counter in message string

decode6:
	mov bl, byte[ecx + esi] ;take byte from message string
	test bl, bl 			;test if message string is over
	je out6

	mov dl, byte[eax + edi] ;take byte from key string
	test dl, dl 			;test if key string is over
	je repeat

continue4:
	sub dl, 97 				;offset
	cmp bl, 97				;check for non-alphabetical characters
	jl non_alpha

continue5:
	sub bl, dl
	cmp bl, 97				;check if alphabet has been exceeded
	jb rotate

continue6:
	mov [ecx + esi], bl 	;replace with decoded byte
	inc esi
	inc edi
	jmp decode6

non_alpha:
	inc esi 				;go over
	mov bl, byte[ecx + esi]
	cmp bl, 97
	jl non_alpha
	jmp continue5			;found a non-alphabetical character

rotate:
	;finding the decoded byte based on offset and some calculations

	add bl, dl
	sub esp, 8

	mov [ebp - 8], eax		;save data
	mov eax, 122
	mov [ebp - 4], eax
	
	sub bl, 96
	sub dl, bl
	sub [ebp - 4], dl

	mov bl, [ebp - 4]
	mov eax, [ebp - 8]

	add esp, 8 				;free
	jmp continue6

repeat:
	xor edi, edi
	mov dl, byte[eax + edi]	;starts again from the beginning
	jmp continue4

out6:
	leave
	ret

main:
	push ebp
	mov ebp, esp
	sub esp, 2300

	; test argc
	mov eax, [ebp + 8]
	cmp eax, 2
	jne exit_bad_arg

	; get task no
	mov ebx, [ebp + 12]
	mov eax, [ebx + 4]
	xor ebx, ebx
	mov bl, [eax]
	sub ebx, '0'
	push ebx

	; verify if task no is in range
	cmp ebx, 1
	jb exit_bad_arg
	cmp ebx, 6
	ja exit_bad_arg

	; create the filename
	lea ecx, [filename + 7]
	add bl, '0'
	mov byte [ecx], bl

	; fd = open("./input{i}.dat", O_RDONLY):
	mov eax, 5
	mov ebx, filename
	xor ecx, ecx
	xor edx, edx
	int 0x80
	cmp eax, 0
	jl exit_no_input

	; read(fd, ebp - 2300, inputlen):
	mov ebx, eax
	mov eax, 3
	lea ecx, [ebp-2300]
	mov edx, [inputlen]
	int 0x80
	cmp eax, 0
	jl exit_cannot_read

	; close(fd):
	mov eax, 6
	int 0x80

	; all input{i}.dat contents are now in ecx (address on stack)
	pop eax
	cmp eax, 1
	je task1
	cmp eax, 2
	je task2
	cmp eax, 3
	je task3
	cmp eax, 4
	je task4
	cmp eax, 5
	je task5
	cmp eax, 6
	je task6
	jmp task_done

task1:
	; TASK 1: Simple XOR between two byte streams

	; DONE: find the address for the string and the key
	; DONE: call the xor_strings function

	xor eax, eax

	push ecx
	call strlen
	pop ecx

	;eax = length of string stored in ecx
	add eax, ecx
	inc eax

	push eax		;eax = address of key string
	push ecx		;ecx = address of input string
	call xor_strings
	add esp, 8

	push ecx
	call puts                   ;print resulting string
	add esp, 4

	jmp task_done

task2:
	; TASK 2: Rolling XOR

	; DONE: call the rolling_xor function

	xor eax, eax

	push ecx
	call strlen
	pop ecx

	;eax = length of string stored in ecx
	add eax, ecx
	dec eax

	push eax		;eax = last byte of string
	push ecx		;ecx = address of input string
	call rolling_xor
	add esp, 8

	push ecx
	call puts
	add esp, 4

	jmp task_done

task3:
	; TASK 3: XORing strings represented as hex strings

	; DONE: find the addresses of both strings
	; DONE: call the xor_hex_strings function

	xor eax, eax

	push ecx
	call strlen
	pop ecx

	add eax, ecx
	inc eax

	push eax		;eax = address of key string
	push ecx		;ecx = address of input string
	call xor_hex_strings
	add esp, 8

	push ecx                     ;print resulting string
	call puts
	add esp, 4

	jmp task_done

task4:
	; TASK 4: decoding a base32-encoded string

	; TODO TASK 4: call the base32decode function
	
	push ecx
	call puts                    ;print resulting string
	pop ecx
	
	jmp task_done

task5:
	; TASK 5: Find the single-byte key used in a XOR encoding

	; DONE: call the bruteforce_singlebyte_xor function
	
	push ecx
	call bruteforce_singlebyte_xor
	pop ecx

	push eax                    ;eax = key value

	push ecx                    ;ecx = decoded string
	call puts					;print resulting string
	pop ecx

	push fmtstr
	call printf                 ;print key value
	add esp, 8

	jmp task_done

task6:
	; TASK 6: decode Vignere cipher

	; DONE: find the addresses for the input string and key
	; DONE: call the decode_vigenere function

	push ecx
	call strlen
	pop ecx

	add eax, ecx
	inc eax

	push eax					;eax = addres of key string
	push ecx                   	;ecx = address of input string 
	call decode_vigenere
	pop ecx
	add esp, 4

	push ecx
	call puts
	add esp, 4

task_done:
	xor eax, eax
	jmp exit

exit_bad_arg:
	mov ebx, [ebp + 12]
	mov ecx , [ebx]
	push ecx
	push usage
	call printf
	add esp, 8
	jmp exit

exit_no_input:
	push filename
	push error_no_file
	call printf
	add esp, 8
	jmp exit

exit_cannot_read:
	push filename
	push error_cannot_read
	call printf
	add esp, 8
	jmp exit

exit:
	mov esp, ebp
	pop ebp
	ret