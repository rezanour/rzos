  mov ah, 0x0e      ; scrolling teletype BIOS routine
  mov al, 'R'
  int 0x10
  mov al, 'e'
  int 0x10
  mov al, 'z'
  int 0x10
  mov al, 'a'
  int 0x10
  
  jmp $

  rb 510-($-$$)   ; fill up to the 510th byte
  dw 0xaa55       ; boot loader signature
