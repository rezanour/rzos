;**********************************************************
; boot.asm
; RZOS boot loader
;
; RZOS 2015/08/10
; Reza Nourai
;**********************************************************

org 0x7c00     ; where BIOS loads us

  mov bx, WELCOME_MSG
  call print_string

  mov bx, 25
  call print_number

  mov bx, NEWLINE_MSG
  call print_string

  ; BIOS only loads 1 sector into memory and starts execution.
  ; We have code after that, so load the remainder of our boot
  ; loader into memory now.

  mov ax, 0x7e0  ; first address after boot sector
  mov es, ax     ; setup es

  ; compute remaining size in # of 512 byte sectors.

  rest_of_boot_loader = end_of_boot_loader - end_of_boot_sector
  mov ax, rest_of_boot_loader
  mov bx, ax
  and bx, 0x00ff
  shr ax, 9      ; divide by 512
  cmp bx, 0
  je no_partial
  add al, 1      ; add 1 if there is a partial sector left
no_partial:
  ; al now has # of sectors to load

  mov bx, 0      ; 0 offset from es
  mov ah, 0x02   ; read sectors from drive
  mov dl, 0x80   ; first hdd
  mov dh, 0      ; head
  mov ch, 0      ; cylinder
  mov cl, 2      ; start sector, BIOS already read 1 into mem
  int 0x13       ; disk service routine
  jc boot_error

  jmp the_end

  ; handle error during startup with a mode switch back to
  ; text and then displaying a simple 'x'

boot_error:
  mov bx, ERROR_MSG
  call print_string
  jmp the_end

the_end:
  jmp $           ; hang, nothing else to do

;**********************************************************
; boot sector data section. All data & routines used before
; loading remainder of loader must fit in first 512 bytes.
;**********************************************************

WELCOME_MSG     db 'Welcome to RZOS, by Reza Nourai.', 0x0d, 0x0a, 0
ERROR_MSG       db 'Error occurred loading remainder of boot loader into memory.', 0
NEWLINE_MSG     db 0x0d, 0x0a, 0

;**********************************************************
; print_string - Prints null-terminated string at offset BX
; in: BX = offset of string
; out: none
;**********************************************************
print_string:
  push ax
  push bx
  mov ah, 0x0e        ; teletype routine
@@:
  mov al, byte ptr bx ; read character from string
  cmp al, 0           ; if 0..
  je @f               ;    .. done
  int 10h             ; invoke BIOS video service
  inc bx              ; advance pointer
  jmp @b
@@:
  pop bx
  pop ax
  ret

;**********************************************************
; print_number - Prints number stored in BX
; in: BX = an integer
; out: none
;**********************************************************
print_number:
  push ax
  push bx
  push cx
  push dx
  push 0xffff
  mov cl, 10
pn_1:
  mov ax, bx
  div cl
  push ax
  cmp al, 0
  je pn_2
  movsx bx, al
  jmp pn_1
pn_2:
  pop ax
  cmp ax, 0xffff      ; if 0..
  je pn_3             ;    .. done
  mov al, ah
  add al, '0'
  mov ah, 0x0e        ; teletype routine
  int 10h             ; invoke BIOS video service
  jmp pn_2
pn_3:
  pop dx
  pop cx
  pop bx
  pop ax
  ret

;**********************************************************
; BIOS detects boot loader by looking for a signature
; at the end of the first 512 byte sector of the drive.
; fill out the rest of our first sector (with 0) and then
; add the magic signature
;**********************************************************
 
  rb 510-($-$$)   ; fill up to the 510th byte
  dw 0xaa55       ; boot loader signature

end_of_boot_sector:

;**********************************************************
; Load remaining boot loader code in sectors after.
; These will all get fetched into mem when we complete the 
; multi-sector read above.
;**********************************************************
;include '../graphics/graphics.asm'

end_of_boot_loader:
