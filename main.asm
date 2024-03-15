.model small
.stack 100h

.data
    oneChar db 0

.code
main proc
    read_next: 
               mov   ah, 3Fh
               mov   bx, 0h                ; stdin handle
               mov   cx, 1                 ; 1 byte to read
               mov   dx, offset oneChar    ; read to ds:dx
               int   21h                   ; cx = number of bytes read

    ; check if end of file (EOF) reached
               cmp   ax, 0                 ; check if EOF reached
               je    end_read              ; jump to end_read if EOF reached

    ; print the character
               mov   ah, 02h               ; DOS function 2: display character
               mov   dl, oneChar           ; character to print
               int   21h                   ; Call the DOS interrupt
            
               jmp   read_next             ; jump back to read_next to read the next character

    end_read:  
    ; end of file reached, do something here if needed


               int   21h                   ; Call the DOS interrupt to terminate the program
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
               push  ax                    ; Save modified registers
               push  di

               xor   al, al                ; al <- search char (null)
               mov   cx, 0ffffh            ; cx <- maximum search depth
               cld                         ; Auto-increment di
               repnz scasb                 ; Scan for al while [di]<>null & cx<>0
               not   cx                    ; Ones complement of cx
               dec   cx                    ;  minus 1 equals string length

               pop   di                    ; Restore registers
               pop   ax
               ret                         ; Return to caller
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
               push  ax                    ; Save modified registers
               push  di
               push  si
               cld                         ; Auto-increment si
@@10:
               lodsb                       ; al <- [si], si <- si + 1
               scasb                       ; Compare al and [di]; di <- di + 1
               jne   @@20                  ; Exit if non-equal chars found
               or    al, al                ; Is al=0? (i.e. at end of s1)
               jne   @@10                  ; If no jump, else exit
@@20:
               pop   si                    ; Restore registers
               pop   di
               pop   ax
               ret                         ; Return flags to caller
StrCompare endp

end main
