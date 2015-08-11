;**********************************************************
; boot.asm
; RZOS boot loader
;
; RZOS 2015/08/10
; Reza Nourai
;**********************************************************

org 0x7c00     ; where BIOS loads us

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
  mov cl, 2
  int 0x13       ; disk service routine
  ;pushw ax       ; count
  ;pushw 2        ; start sector, 1 is the one BIOS already loaded
  ;call read_sectors
  jc boot_error

  ; change to a graphics mode
  call set_graphics_mode

  pushw 3          ; background color
  call clear_screen

  ; draw a simple rectangle
  pushw 1   ; color
  pushw 50  ; height
  pushw 200 ; width
  pushw 10  ; y
  pushw 60  ; x
  call draw_rect

  jmp the_end

  ; handle error during startup with a mode switch back to
  ; text and then displaying a simple 'x'

boot_error:
  call set_default_mode

  mov ah, 0x0e    ; teletype
  mov al, 'x'
  int 10h

  jmp the_end

the_end:
  jmp $           ; hang, nothing else to do

  ; BIOS detects boot loader by looking for a signature
  ; at the end of the first 512 byte sector of the drive.
  ; fill out the rest of our first sector (with 0) and then
  ; add the magic signature
 
  rb 510-($-$$)   ; fill up to the 510th byte
  dw 0xaa55       ; boot loader signature

end_of_boot_sector:

include '..\filesystem\disk.asm'
include '..\graphics\graphics.asm'

end_of_boot_loader:
