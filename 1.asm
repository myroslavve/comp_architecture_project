.model small
.stack 100h

.data
    array db 10 dup(0)

.code
main proc
         int 21h    ; Call the DOS interrupt to terminate the program
main endp

end main
