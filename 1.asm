.model small
.stack 100h

.data
    oneChar db 0

.code
main proc
    read_next:
              mov ah, 3Fh
              mov bx, 0h                ; stdin handle
              mov cx, 1                 ; 1 byte to read
              mov dx, offset oneChar    ; read to ds:dx
              int 21h                   ; cx = number of bytes read

    ; check if end of file (EOF) reached
              cmp ax, 0                 ; check if EOF reached
              je  end_read              ; jump to end_read if EOF reached

    ; print the character
              mov ah, 02h               ; DOS function 2: display character
              mov dl, oneChar           ; character to print
              int 21h                   ; Call the DOS interrupt
            
              jmp read_next             ; jump back to read_next to read the next character

    end_read: 
    ; end of file reached, do something here if needed


              int 21h                   ; Call the DOS interrupt to terminate the program
main endp

end main
