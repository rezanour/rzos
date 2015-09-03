;**********************************************************
; boot/memory.asm
; RZOS boot loader memory support
;
; RZOS 2015/08/20
; Reza Nourai
;**********************************************************

;**********************************************************
; data
;**********************************************************

; the memory map is a set of 24 byte entries describing:
;     start offset of segment (8 bytes)
;     size of segment in bytes (8 bytes)
;     type of segment (4 bytes)
;         1 = usable RAM
;         2 = Reserved (unusable)
;         3 = ACPI reclaimable
;         4 = ACPI nonreclaimable
;         5 = Identified bad memory
;     ACPI 3.0 extended attributes bitfield (4 bytes)
num_mmap_entries  dw  0
mmap_entry        db  0 dup(240)  ; each entry is 24 bytes, so reserve room for 10 entries

BASE_OFFSET       db 'start [', 0
SIZE_TEXT         db '] - size [', 0
AVAILABLE         db '] - available', 0
RESERVED          db '] - reserved', 0
OTHERMEM          db '] - other', 0

;**********************************************************
; load_mem_map - Load system memory map
; in: none
; out: none
;**********************************************************
load_mem_map:
  push eax
  push ebx
  push ecx
  push edx
  push bp
  push es
  push di

  mov ax, mmap_entry
  mov es, ax            ; set our segment pointer to point to the start of our entries
  mov di, 0
  xor ebx, ebx          ; 0 out ebx
  xor bp, bp            ; 0 out bp. It'll hold our rolling count
  mov edx, 0x0534D4150  ; "SMAP" parameter for querying system memory map
  mov eax, 0xe820       ; query system memory map function of BIOS
  mov ecx, 24           ; ask for full 24 byte entries
  mov [es:di + 20], dword 1   ; set ACPI 3.x field to 1 (query ext info if avail)
  int 15h               ; invoke BIOS function
  jc .failed            ; carry on the first call means unsupported
  mov edx, 0x0534D4150  ; apparently some BIOS's trash this register during the call so fix it
  cmp eax, edx          ; on success, eax must have been set to "SMAP"
  jne .failed
  test ebx, ebx         ; ebx must be non zero
  je .failed
  jmp .process_entry

.query_entry:
  mov eax, 0xe820       ; eax, ecx get trashed on each call so set them up again
  mov ecx, 24           ; ask for full 24 byte entries
  mov [es:di + 20], dword 1   ; set ACPI 3.x field to 1 (query ext info if avail)
  int 15h               ; invoke BIOS function
  jc .end_of_list       ; carry means "end of list"
  mov edx, 0x0534D4150  ; restore register in case BIOS trashed it

.process_entry:
  jcxz .skip            ; skip 0 length entries
  cmp cl, 20            ; we asked for 24, did we only get 20 byte entry?
  jle .noext            ; no extended data
  test byte [es:di + 20], 1   ; extended data with 1 set means 'ignore'
  je .skip

.noext:
  mov ecx, [es:di + 8]  ; get lower dword of length
  or ecx, [es:di + 12]  ; or with upper to check for 0
  jz .skip
  inc bp                ; got a good entry, so ++count
  add di, 24            ; and move our dest pointer to next entry

.skip:
  test ebx, ebx         ; if ebx is 0, list complete
  jne .query_entry

.end_of_list:
  mov [num_mmap_entries], bp  ; store off the total count
  clc                   ; clear carry flag if set
  jmp .end

.failed:
  stc                   ; set carry flag to mean error

.end:
  pop di
  pop es
  pop bp
  pop edx
  pop ecx
  pop ebx
  pop eax
  ret

;**********************************************************
; print_mem_map - Print system memory map info
; in: none
; out: none
;**********************************************************
print_mem_map:
  push ax
  push bx
  push cx
  push es
  push di

  mov cx, [num_mmap_entries]
  mov ax, mmap_entry
  mov es, ax
  mov di, 0

.next_entry:
  test cx, cx           ; any entries left?
  jz .end

  dec cx

  ; base address
  mov bx, BASE_OFFSET
  call print_string
  mov bx, word [es:di + 6]
  call print_hex
  mov bx, word [es:di + 4]
  call print_hex
  mov bx, word [es:di + 2]
  call print_hex
  mov bx, word [es:di]
  call print_hex

  ; size
  mov bx, SIZE_TEXT
  call print_string
  mov bx, word [es:di + 14]
  call print_hex
  mov bx, word [es:di + 12]
  call print_hex
  mov bx, word [es:di + 10]
  call print_hex
  mov bx, word [es:di + 8]
  call print_hex

  ; type
  mov ax, word [es:di + 16] ; get type
  cmp ax, 1             ; avail
  je .avail
  cmp ax, 2             ; reserved
  je .reserved
  jmp .other

.avail:
  mov bx, AVAILABLE
  call print_string
  call print_newline
  add di, 24
  jmp .next_entry

.reserved:
  mov bx, RESERVED
  call print_string
  call print_newline
  add di, 24
  jmp .next_entry

.other:
  mov bx, OTHERMEM
  call print_string
  call print_newline
  add di, 24
  jmp .next_entry

.end:
  pop di
  pop es
  pop cx
  pop bx
  pop ax
  ret
