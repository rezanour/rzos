; RZOS BootLoader

  org 0x7c00     ; where BIOS loads us

  ; BIOS only loads 1 sector into memory and starts execution.
  ; We have code after that, so load the remainder of our boot
  ; loader into memory now.

  mov ax, 0x7e0  ; first address after boot sector
  mov es, ax     ; setup es

  ; compute remaining size in # of 512 byte sectors.

  mov ax, end_of_boot_loader
  sub ax, end_of_boot_sector
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
  mov cl, 2      ; start sector, 1 is the one BIOS already loaded
  int 0x13       ; disk service routine
  jc boot_error

  ; change to a graphics mode
  call set_graphics_mode

  mov dl, 3
  call clear_screen

  ; draw a simple rectangle
  mov al, 60
  mov ah, 10
  mov bl, 200
  mov bh, 50
  mov dl, 1
  call draw_quad

  jmp the_end

  ; handle error during startup with a mode switch back to
  ; text and then displaying a simple 'x'

boot_error:
  mov ah, 0       ; set mode
  mov al, 3       ; 80x25 16 color
  int 10h         ; video routine

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

  ; The rest of the functionality for boot is below

set_graphics_mode:
  mov ah, 0       ; set graphics mode BIOS routine
  mov al, 0x13    ; mode 13 (320x200, 256 colors)
  int 0x10
  ret

; set dl to the clear color before call
clear_screen:
  mov ax, 0xa000   ; start of frame buffer
  mov es, ax       ; start location of output
  mov di, 0        ; start index of output
  mov ah, dl       ; clear color (upper byte)
  mov al, dl       ; clear color (lower byte)
  mov cx, 0x7fff   ; count = 320x200 / 2 (writing word at a time)
  rep stosw        ; repeatedly write ax to ds:di and inc di
  ret

; set al = x, ah = y, bl = w, bh = h, dl = color
draw_quad:
  push dx
  mov cx, 0xa000   ; start of frame buffer
  mov es, cx
  mov di, ax
  shr di, 8
  push ax
  mov ax, di
  mov cx, 320
  mul cx
  mov di, ax
  pop ax
  and ax, 0x00ff
  add di, ax
  xor ax, ax
  pop dx
  mov al, dl
draw_quad_loop:
  push di
  xor cx, cx
  mov cl, bl
  rep stosb
  pop di
  add di, 320
  dec bh
  cmp bh, 0
  jne draw_quad_loop
  ret

end_of_boot_loader:
