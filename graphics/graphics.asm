;*********************************************************
; graphics.asm
; Support for basic graphics routines like mode change.
;
; RZOS 2015/08/11
; Reza Nourai
;*********************************************************

;*********************************************************
; set_default_mode - change to safe, default text mode
; input: no parameters
; return: none
;*********************************************************
set_default_mode:
  mov ah, 0       ; set mode
  mov al, 3       ; 80x25 16 color
  int 10h         ; video routine
  ret

;*********************************************************
; set_graphics_mode - change to main graphics mode
; input: no parameters
; return: none
;*********************************************************
set_graphics_mode:
  mov ah, 0       ; set mode
  mov al, 13h     ; 320x200 256 color
  int 10h         ; video routine
  ret

;*********************************************************
; clear_screen - clears the screen in graphics mode
; input: byte color
; return: none
;*********************************************************
clear_screen:
  pusha
label .color at esp+18

  mov ax, 0xa000   ; start of frame buffer
  mov es, ax       ; start location of output
  mov di, 0        ; start index of output
  mov ah, byte [.color] ; clear color (upper byte)
  mov al, byte [.color] ; clear color (lower byte)
  mov cx, 0x7fff   ; count = 320x200 / 2 (writing word at a time)
  rep stosw        ; repeatedly write ax to ds:di and inc di

  popa
  ret

;*********************************************************
; draw_rect - draws a colored rectangle
; input: word x, word y, word w, word h, byte color
; return: none
;*********************************************************
draw_rect:
  pusha
label .x at esp+18
label .y at esp+20
label .w at esp+22
label .h at esp+24
label .color at esp+26

  mov ax, 0xa000   ; start of frame buffer
  mov es, ax
  mov ax, [.y]
  mov dx, 320
  mul dx
  add ax, [.x]
  mov di, ax
  mov al, byte [.color]
  mov bx, [.h]

@@:
  push di
  mov cx, [.w]
  rep stosb
  pop di
  add di, 320
  dec bx
  cmp bx, 0
  jne @b

  popa
  ret

