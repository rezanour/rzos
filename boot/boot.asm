;**********************************************************
; boot.asm
; RZOS boot loader
;
; RZOS 2015/08/10
; Reza Nourai
;**********************************************************

org 0x7c00      ; where BIOS loads us
format binary   ; flat machine instructions output raw to file
use16           ; use 16-bit real mode (what CPU starts in on boot)

  jmp start

;**********************************************************
; boot sector data
;**********************************************************

WELCOME_MSG     db 'Welcome to RZOS, by Reza Nourai.', 0
LOAD_ERROR_MSG  db 'Error loading remainder of boot loader into memory.', 0
MEM_ERROR_MSG   db 'Error querying system memory information.', 0
END_MSG         db 'The End.', 0
NEWLINE         db 0x0d, 0x0a, 0

;**********************************************************
; NOTE:
; The BIOS loads a single 512 byte boot sector into memory
; and begins execution there. Our boot sector code must fit
; into 512 bytes, but we can load additional code & data
; into memory ourselves to access after that.
;**********************************************************

;**********************************************************
; boot sector code
;**********************************************************

start:
  mov bx, WELCOME_MSG
  call print_string
  call print_newline
  call print_newline

  ; compute remaining size in # of 512 byte sectors.
  rest_of_boot_loader = end_of_boot_loader - end_of_boot_sector
  mov ax, rest_of_boot_loader
  mov bx, ax
  shr ax, 9       ; divide by 512
  or bl, 0        ; if low byte of size is 0, no need to add partial sector
  jz .no_partial
  add al, 1       ; add 1 if there is a partial sector left
.no_partial:
  ; al now has # of sectors to load

  mov bx, 0x7e0   ; first address after boot sector
  mov es, bx
  xor bx, bx      ; 0 offset from es
  mov ah, 0x02    ; read_sectors BIOS function
  mov dl, 0x80    ; select first hdd
  mov dh, 0       ; head 0
  mov ch, 0       ; cylinder 0
  mov cl, 2       ; start sector, BIOS already read 1 into mem
  int 0x13        ; invoke disk service routine
  jc .boot_error

  ; print some CPU info
  call print_cpu_info
  call print_newline

  ; load up the memory map
  call load_mem_map
  jc .mem_error

  ; print memory summary
  call print_mem_map

  jmp .the_end

.boot_error:
  mov dx, LOAD_ERROR_MSG
  jmp .error

.mem_error:
  mov dx, MEM_ERROR_MSG
  jmp .error

.error:
  call print_string
  call print_newline
  jmp .the_end

.the_end:
  mov bx, END_MSG
  call print_string
  jmp $           ; hang, nothing else to do

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
  cmp al, 0
  je @f               ; if 0, reached end of string
  int 10h             ; invoke BIOS video service
  inc bx              ; advance pointer
  jmp @b
@@:
  pop bx
  pop ax
  ret

;**********************************************************
; print_newline - Prints newline
; in: none
; out: none
;**********************************************************
print_newline:
  push bx
  mov  bx, NEWLINE
  call print_string
  pop bx
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
  push 0xffff     ; insert token to mark end of digits in stack
  mov cx, 10
  mov ax, bx
@@:
  xor dx, dx      ; dx (upper word of dividend) to 0
  div cx          ; divide by 10 to extract digit
  push dx         ; store remainder as our digit
  cmp ax, 0       ; if quotient is 0, no more digits, we're done
  je @f
  jmp @b
@@:
  mov ah, 0x0e    ; select teletype routine
@@:
  pop bx          ; pull out a digit (in high byte)
  cmp bx, 0xffff  ; first, check for our end marker
  je @f
  mov al, bl      ; move quotient to al so we can use it for call
  add al, '0'     ; add ascii offset for digit
  int 10h         ; invoke BIOS video service
  jmp @b
@@:
  pop dx
  pop cx
  pop bx
  pop ax
  ret

;**********************************************************
; print_hex - Prints number stored in BX as hex with leading 0s
; in: BX = an integer
; out: none
;**********************************************************
print_hex:
  push ax
  push bx
  push cx
  push dx
  push 0xffff     ; insert token to mark end of digits in stack
  mov cx, 16
  mov ax, bx
  mov bx, 4       ; num iterations (so we force 0s)
@@:
  xor dx, dx      ; dx (upper word of dividend) to 0
  div cx          ; divide by 10 to extract digit
  push dx         ; store remainder as our digit
  dec bx
  cmp bx, 0       ; if count = 0, we're done
  je @f
  jmp @b
@@:
  mov ah, 0x0e    ; select teletype routine
@@:
  pop bx          ; pull out a digit (in high byte)
  cmp bx, 0xffff  ; first, check for our end marker
  je @f
  mov al, bl      ; move quotient to al so we can use it for call
  cmp al, 10
  jge .letter
  add al, '0'     ; add ascii offset for digit
  int 10h         ; invoke BIOS video service
  jmp @b
.letter:
  sub al, 10
  add al, 'A'     ; add ascii offset for digit
  int 10h         ; invoke BIOS video service
  jmp @b
@@:
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
include 'cpu.asm'
include 'memory.asm'

end_of_boot_loader:
