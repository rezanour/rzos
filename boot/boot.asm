; RZOS BootLoader

  org 0x7c00     ; where BIOS loads us

  call set_graphics_mode

  mov dl, 3
  call clear_screen

  mov al, 10
  mov ah, 20
  mov bl, 100
  mov bh, 50
  mov dl, 1
  call draw_quad

  jmp $

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

  rb 510-($-$$)   ; fill up to the 510th byte
  dw 0xaa55       ; boot loader signature

