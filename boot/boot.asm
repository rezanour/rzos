; RZOS BootLoader

  org 0x7c00       ; where BIOS loads our boot loader

  mov bx, welcome_message
  call print_message
  
  jmp $

welcome_message:
  db "Welcome to RZOS, by Reza Nourai.", 0

; print_message routine. Set bx to beginning
; of null terminated string to print before calling.

print_message:
  mov ah, 0x0e    ; scrolling teletype BIOS routine

print_loop:
  cmp byte [bx], 0
  je print_end
  mov al, [bx]
  int 0x10
  inc bx
  jmp print_loop

print_end:
  ret

  rb 510-($-$$)   ; fill up to the 510th byte
  dw 0xaa55       ; boot loader signature
