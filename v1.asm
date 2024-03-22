.model small
.stack 100h

.data
    oneChar   db  0
    ASCNull   EQU 0        ; ASCII null character
    subString db  "", 0    ; substring to find, given in args
    string    db  "", 0    ; string to search

.code
main proc
    read_next:      
                    mov   ah, 3Fh
                    mov   bx, 0h                         ; stdin handle
                    mov   cx, 1                          ; 1 byte to read
                    mov   dx, offset oneChar             ; read to ds:dx
                    int   21h                            ; cx = number of bytes read

    ; check if end of file (EOF) reached
                    cmp   ax, 0                          ; check if EOF reached
                    je    end_read                       ; jump to end_read if EOF reached

    ; print the character
                    mov   ah, 02h                        ; DOS function 2: display character
                    mov   dl, oneChar                    ; character to print
                    int   21h                            ; Call the DOS interrupt
    ; push char to str
                    mov   al, oneChar
                    mov   di, offset string
                    call  StrPush

                    jmp   read_next                      ; jump back to read_next to read the next character

    end_read:       
    ; end of file reached, do something here if needed
    
    ; ds = PSP
    ; copy param
                    xor   ch,ch
                    mov   cl, ds:[80h]                   ; at offset 80h length of "args"
    write_char:     
                    test  cl, cl
                    jz    write_end
                    mov   si, 81h                        ; at offest 81h first char of "args"
                    add   si, cx
    ; print the character
                    mov   ah, 02h
                    mov   dl, ds:[si]
                    int   21h
    ; push char to subString
                    mov   al, ds:[si]
                    mov   di, offset subString
                    call  StrPush

                    dec   cl
                    jmp   write_char
    write_end:      

    ; end program
                    mov   ah, 4Ch                        ; DOS function 4Ch: terminate program
                    int   21h                            ; Call the DOS interrupt
main endp

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
                    push  di

                    call  StrLength                      ; Find length of string
                    mov   bx, cx                         ; Save length of string in bx
                    mov   [di + bx], al                  ; Push character onto end of string
                    inc   bx                             ; Increment length of string
                    mov   byte ptr [di + bx], ASCNull    ; Null-terminate string

                    pop   di                             ; Restore registers
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
                    call  StrPos                         ; Find first occurrence of substring
                    jz    @@a0                           ; Jump if substring found
                    jmp   @@b0                           ; Else exit
@@a0:
                    inc   cx                             ; Increment count
                    add   di, dx                         ; Advance di to next position
                    call  StrPos                         ; Find next occurrence of substring
                    jz    @@a0                           ; Jump if substring found
@@b0:
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

end main
