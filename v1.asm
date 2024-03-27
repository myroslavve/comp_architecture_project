.model small
.stack 100h

.data
    oneChar       db  0
    ASCNull       EQU 0                ; ASCII null character
    subString     db  255 dup(0), 0    ; substring to find, given in args
    string        db  255 dup(0), 0    ; string to search
    count         db  100 dup(0)       ; array to store count of substring by line
    line_indices  db  100 dup(0)       ; array to store line indices of count array
    current_index db  0                ; index of line in count array
    subStringLen  db  0                ; length of substring

.code
main proc
    ; set up data segment
                    mov   ax, @data
                    mov   ds, ax
    ; read argument
                    call  ReadArgument
    ; move data segment to es
                    mov   ax, @data
                    mov   es, ax
    ; read file
                    call  ReadFile
    ; fill line_indices array
                    call  FillIndices
    ; print result
                    call  PrintResult
    ; end program
                    mov   ah, 4Ch                        ; DOS function 4Ch: terminate program
                    int   21h                            ; Call the DOS interrupt
main endp

    ;---------------------------------------------------------------
    ; ReadFile      Read a file and count occurrences of a substring
    ;---------------------------------------------------------------
    ; Input:
    ;       none
    ; Output:
    ;       none
    ; Registers:
    ;       ax, bx, cx, dx
    ;---------------------------------------------------------------
ReadFile proc
    ; read file line by line and call CountOccurences after each line
    read_next:      
                    mov   ah, 3Fh
                    mov   bx, 0h                         ; stdin handle
                    mov   cx, 1                          ; 1 byte to read
                    mov   dx, offset oneChar             ; read to ds:dx
                    int   21h                            ; cx = number of bytes read

    ; check if end of line reached (CR or LF)
                    cmp   oneChar, 0Dh                   ; check if CR reached
                    je    end_line                       ; jump to end_line if CR reached
                    cmp   oneChar, 0Ah                   ; check if LF reached
                    je    end_line                       ; jump to end_line if LF reached

    ; check if end of file (EOF) reached
                    cmp   ax, 0                          ; check if EOF reached
                    je    end_read                       ; jump to end_read if EOF reached
    
    continue_read:  
    ; print the character
                    mov   ah, 02h                        ; DOS function 2: display character
                    mov   dl, oneChar                    ; character to print
                    int   21h                            ; Call the DOS interrupt
    ; push char to str
                    mov   al, oneChar
                    mov   di, offset string
                    call  StrPush

                    jmp   read_next                      ; jump back to read_next to read the next character

    end_line:       
                    mov   si, offset subString
                    mov   di, offset string
                    call  CountOccurences
                    inc   current_index                  ; increment current_index

    ; Check if next symbol is LF
                    mov   ah, 3Fh
                    mov   bx, 0h                         ; stdin handle
                    mov   cx, 1                          ; 1 byte to read
                    mov   dx, offset oneChar             ; read to ds:dx
                    int   21h                            ; cx = number of bytes read

                    cmp   oneChar, 0Ah                   ; check if LF reached
                    je    read_next                      ; jump to read_next if LF

                    jmp   continue_read                  ; jump to continue_read if not LF

    end_read:       
                    mov   si, offset subString
                    mov   di, offset string
                    call  CountOccurences

                    ret                                  ; Return to caller
ReadFile endp

    ;---------------------------------------------------------------
    ; ReadArgument  Read the argument from the command line
    ;---------------------------------------------------------------
    ; Input:
    ;       none
    ; Output:
    ;       none
    ; Registers:
    ;       ax, bx, cx, dx
    ;---------------------------------------------------------------
ReadArgument proc
    ; es = PSP
    ; copy param
                    xor   ch,ch
                    mov   cl, es:[80h]                   ; at offset 80h length of "args"
    ; length of substring is length of args - 1
                    mov   subStringLen, cl
                    dec   subStringLen
    write_char:     
                    test  cl, cl
                    jz    write_end
                    mov   si, 81h                        ; at offest 81h first char of "args"
                    add   si, cx
    ; skip cr
                    cmp   byte ptr es:[si], 0Dh
                    je    dec_cx_and_jump
    ; print the character
                    mov   ah, 02h
                    mov   dl, es:[si]
                    int   21h
    ; push char to subString
                    mov   al, es:[si]
                    push  es
                    mov   bx, @data
                    mov   es, bx                         ; set es to data segment, for scasb to work
                    mov   di, offset subString
                    call  StrPush
                    pop   es

                    dec   cl
                    jmp   write_char
    write_end:      
                    ret                                  ; Return to caller

    dec_cx_and_jump:
                    dec   cl
                    jmp   write_char
ReadArgument endp

    ;---------------------------------------------------------------
    ; StrLength     Count non-null characters in a string
    ;---------------------------------------------------------------
    ; Input:
    ;       di = address of string (s)
    ; Output:
    ;       cx = number of non-null characters in s
    ; Registers:
    ;       cx
    ;---------------------------------------------------------------
StrLength proc
                    push  ax                             ; Save modified registers
                    push  di

                    xor   al, al                         ; al <- search char (null)
                    mov   cx, 0ffffh                     ; cx <- maximum search depth
                    cld                                  ; Auto-increment di
                    repnz scasb                          ; Scan for al while [di]<>null & cx<>0
                    not   cx                             ; Ones complement of cx
                    dec   cx                             ;  minus 1 equals string length

                    pop   di                             ; Restore registers
                    pop   ax
                    ret                                  ; Return to caller
StrLength endp

    ;---------------------------------------------------------------
    ; StrCompare    Compare two strings
    ;---------------------------------------------------------------
    ; Input:
    ;       si = address of string 1 (s1)
    ;       di = address of string 2 (s2)
    ; Output:
    ;       flags set for conditional jump using jb, jbe,
    ;        je, ja, or jae.
    ; Registers:
    ;       none
    ;---------------------------------------------------------------
StrCompare proc
                    push  ax                             ; Save modified registers
                    push  di
                    push  si
                    cld                                  ; Auto-increment si
@@10:
                    lodsb                                ; al <- [si], si <- si + 1
                    scasb                                ; Compare al and [di]; di <- di + 1
                    jne   @@20                           ; Exit if non-equal chars found
                    or    al, al                         ; Is al=0? (i.e. at end of s1)
                    jne   @@10                           ; If no jump, else exit
@@20:
                    pop   si                             ; Restore registers
                    pop   di
                    pop   ax
                    ret                                  ; Return flags to caller
StrCompare endp

    ;---------------------------------------------------------------
    ; StrPos        Search for position of a substring in a string
    ;---------------------------------------------------------------
    ; Input:
    ;       si = address of substring to find
    ;       di = address of target string to scan
    ; Output:
    ;       if zf = 1 then dx = index of substring
    ;       if zf = 0 then substring was not found
    ;       Note: dx is meaningless if zf = 0
    ; Registers:
    ;       dx
    ;---------------------------------------------------------------
StrPos proc
                    push  ax                             ; Save modified registers
                    push  bx
                    push  cx
                    push  di

                    call  StrLength                      ; Find length of target string
                    mov   ax, cx                         ; Save length(s2) in ax
                    xchg  si, di                         ; Swap si and di
                    call  StrLength                      ; Find length of substring
                    mov   bx, cx                         ; Save length(s1) in bx
                    xchg  si, di                         ; Restore si and di
                    sub   ax, bx                         ; ax = last possible index
                    jb    @@40                           ; Exit if len target < len substring
                    mov   dx, 0ffffh                     ; Initialize dx to -1
@@30:
                    inc   dx                             ; For i = 0 TO last possible index
                    mov   cl, [bx + di]                  ; Save char at s[bx] in cl
                    mov   byte ptr [bx + di], ASCNull    ; Replace char with null
                    call  StrCompare                     ; Compare si to altered di
                    mov   [bx + di], cl                  ; Restore replaced char
                    je    @@40                           ; Jump if match found, dx=index, zf=1
                    inc   di                             ; Else advance target string index
                    cmp   dx, ax                         ; When equal, all positions checked
                    jne   @@30                           ; Continue search unless not found

                    xor   cx, cx                         ; Substring not found.  Reset zf = 0
                    inc   cx                             ;  to indicate no match
@@40:
                    pop   di                             ; Restore registers
                    pop   cx
                    pop   bx
                    pop   ax
                    ret                                  ; Return to caller
StrPos endp

    ;---------------------------------------------------------------
    ; StrPush       Push a character onto the end of a string
    ;---------------------------------------------------------------
    ; Input:
    ;       al = character to push
    ;       di = address of string
    ; Output:
    ;       none
    ; Registers:
    ;       di
    ;---------------------------------------------------------------
StrPush proc
                    push  ax                             ; Save modified registers
                    push  cx
                    push  bx
                    push  di

                    call  StrLength                      ; Find length of string
                    mov   bx, cx                         ; Save length of string in bx
                    mov   [di + bx], al                  ; Push character onto end of string
                    inc   bx                             ; Increment length of string
                    mov   byte ptr [di + bx], ASCNull    ; Null-terminate string

                    pop   di                             ; Restore registers
                    pop   bx
                    pop   cx
                    pop   ax
                    ret                                  ; Return to caller
StrPush endp

    ;---------------------------------------------------------------
    ; CountOccurences    Count occurrences of a substring in a string
    ;---------------------------------------------------------------
    ; Input:
    ;       si = address of substring to find
    ;       di = address of target string to scan
    ; Output:
    ;       cx = number of occurrences of substring in string
    ; Registers:
    ;       cx
    ;---------------------------------------------------------------
CountOccurences proc
                    push  ax                             ; Save modified registers
                    push  bx
                    push  di
                    push  si

                    mov   cx, 0                          ; Initialize count to 0

    ; if substring is empty, return 0
                    mov   al, subStringLen
                    cmp   al, 0
                    jz    @@b0

                    call  StrPos                         ; Find first occurrence of substring
                    jz    @@a0                           ; Jump if substring found
                    jmp   @@b0                           ; Else exit
@@a0:
                    inc   cx                             ; Increment count
                    mov   ax, dx                         ; Save index of substring in ax
                    add   al, subStringLen               ; Move to next character after substring
                    add   di, ax                         ; move di to the next character after the substring
                    call  StrPos                         ; Find next occurrence of substring
                    jz    @@a0                           ; Jump if substring found
@@b0:
                    mov   di, offset count
                    mov   al, current_index
                    xor   ah, ah
                    add   di, ax                         ; Set di to the address of count[current_index]
                    mov   [di], cl                       ; Store count in count array

                    pop   si                             ; Restore registers
                    pop   di
                    pop   bx
                    pop   ax
                    ret                                  ; Return to caller
CountOccurences endp

    ;---------------------------------------------------------------
    ; PrintDecimal    Print a decimal number
    ;---------------------------------------------------------------
    ; Input:
    ;       ax = number to print
    ; Output:
    ;       none
    ; Registers:
    ;       ax, bx, cx, dx
    ;---------------------------------------------------------------
PrintDecimal proc
                    push  ax                             ; Save modified registers
                    push  bx
                    push  cx
                    push  dx

                    mov   bx, 10                         ; Set bx to 10 for division
                    xor   cx, cx                         ; Initialize cx to 0 (digit count)
                    xor   dx, dx                         ; Clear dx (remainder)

@@c0:
                    div   bx                             ; Divide ax by bx, quotient in ax, remainder in dx
                    push  dx                             ; Push remainder onto stack
                    xor   dx, dx                         ; Clear dx
                    inc   cx                             ; Increment digit count
                    test  ax, ax                         ; Check if ax is zero
                    jnz   @@c0                           ; If not zero, continue division

@@d0:
                    pop   dx                             ; Pop remainder from stack
                    add   dl, 30h                        ; Convert remainder to ASCII character
                    mov   ah, 02h                        ; Set ah to 02h for printing character
                    int   21h                            ; Print character
                    loop  @@d0                           ; Loop until all digits are printed

                    pop   dx                             ; Restore registers
                    pop   cx
                    pop   bx
                    pop   ax
                    ret                                  ; Return to caller
PrintDecimal endp

    ;---------------------------------------------------------------
    ; FillIndices    Fill the line_indices array with numbers from 0 - 99
    ;---------------------------------------------------------------
    ; Input:
    ;       none
    ; Output:
    ;       none
    ; Registers:
    ;       ax, bx, cx, dx
    ;---------------------------------------------------------------

FillIndices proc
                    push  ax                             ; Save modified registers
                    push  cx
                    push  di

                    mov   ax, 0                          ; Initialize ax to 0
                    mov   di, offset line_indices        ; Set di to the address of line_indices
                    mov   cx, 99                         ; Set cx to 99

    fill_loop:      
                    mov   [di], ax                       ; Store the value of ax in the current index of line_indices
                    inc   ax                             ; Increment ax
                    inc   di                             ; Increment di
                    loop  fill_loop                      ; Loop until cx becomes zero

                    pop   di                             ; Restore registers
                    pop   cx
                    pop   ax
                    ret
FillIndices endp

    ;---------------------------------------------------------------
    ; PrintResult    Print n lines with the count of the substring and the line index
    ;---------------------------------------------------------------
    ; Input:
    ;       none
    ; Output:
    ;       none
    ; Registers:
    ;       ax, cx, dx
    ;---------------------------------------------------------------
PrintResult proc
                    push  ax                             ; Save modified registers
                    push  cx
                    push  dx
                    push  di
                    push  si

                    mov   cl, current_index              ; Print current_index + 1 lines
                    inc   cx
                    mov   di, offset count               ; Set di to the address of count
                    mov   si, offset line_indices        ; Set si to the address of line_indices
                    
    print_loop:     
    ; Print count of substring
                    mov   al, [di]
                    call  PrintDecimal
    ; Print space
                    mov   dl, 20h
                    mov   ah, 02h
                    int   21h
                    xor   ax, ax                         ; Clear ax
    ; Print line index
                    mov   al, [si]
                    call  PrintDecimal
    ; Print newline
                    mov   dl, 0Dh                        ; carriage return
                    mov   ah, 02h
                    int   21h
                    mov   dl, 0Ah                        ; line feed
                    mov   ah, 02h
                    int   21h
                    xor   ax, ax                         ; Clear ax

                    inc   di                             ; Increment di
                    inc   si                             ; Increment si
                    loop  print_loop                     ; Loop until cx becomes zero

                    pop   si                             ; Restore registers
                    pop   di
                    pop   dx
                    pop   cx
                    pop   ax
                    ret
PrintResult endp

    ;---------------------------------------------------------------
    ; Separators    Private routine to check for blanks, tabs, and crs
    ;---------------------------------------------------------------
    ; Input:
    ;       es:si addresses character to check
    ; Output:
    ;       zf = 1 (je)  = character is a blank, tab, or cr
    ;       zf = 0 (jne) = character is not a separator
    ; Registers:
    ;       al
    ;---------------------------------------------------------------
Separators proc
                    mov   al, es:[si]                    ; Get character at es:si
                    cmp   al, 020h                       ; Is char a blank?
                    je    @@10                           ; Jump if yes
                    cmp   al, 009h                       ; Is char a tab?
                    je    @@10                           ; Jump if yes
                    cmp   al, 00Dh                       ; Is char a cr?
@@10:
                    ret                                  ; Return to caller
Separators endp

end main
