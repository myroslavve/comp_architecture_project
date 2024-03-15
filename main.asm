.model small
.stack 100h

.data
    oneChar db  0
    ASCNull EQU 0    ; ASCII null character

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
            
               jmp   read_next                      ; jump back to read_next to read the next character

    end_read:  
    ; end of file reached, do something here if needed


               int   21h                            ; Call the DOS interrupt to terminate the program
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

end main
