;*********************************************************
; disk.asm
; Support for basic disk functions.
;
; RZOS 2015/08/11
; Reza Nourai
;*********************************************************

;*********************************************************
; read_sectors - read n sectors from primary hdd
; input: byte start_sector, byte num_sectors, es:bx pointing to address
; return: CF set on error
;*********************************************************
read_sectors:
  pusha
label .start at ebp+18
label .count at ebp+20

  mov ah, 0x02   ; read sectors from drive
  mov dl, 0x80   ; first hdd
  mov dh, 0      ; head
  mov ch, 0      ; cylinder
  mov cl, byte [.start]
  mov al, byte [.count]
  int 0x13       ; disk service routine

  popa
  ret

