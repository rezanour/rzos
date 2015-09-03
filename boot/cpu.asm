;**********************************************************
; boot/cpu.asm
; RZOS boot loader cpu support
;
; RZOS 2015/09/02
; Reza Nourai
;**********************************************************

;**********************************************************
; data
;**********************************************************

FEATURES          db 'CPU features: ', 0
FPU               db 'fpu, ', 0
APIC              db 'apic, ', 0
SYSCALL_M         db 'syscall, ', 0
SSE2              db 'sse2, ', 0
X64               db 'x64, ', 0

;**********************************************************
; print_cpu_info - Print info about the CPU
; in: none
; out: none
;**********************************************************
print_cpu_info:
  push eax
  push ebx
  push ecx
  push edx

  mov bx, FEATURES
  call print_string

  mov eax, 1
  xor ecx, ecx
  xor edx, edx
  cpuid

  bt edx, 0
  jc @f
  mov bx, FPU
  call print_string
@@:
  bt edx, 9
  jc @f
  mov bx, APIC
  call print_string
@@:
  bt edx, 11
  jc @f
  mov bx, SYSCALL_M
  call print_string
@@:
  bt edx, 26
  jc @f
  mov bx, SSE2
  call print_string
@@:
  bt edx, 30
  jc @f
  mov bx, X64
  call print_string

@@:
  mov bx, NEWLINE
  call print_string

  pop edx
  pop ecx
  pop ebx
  pop eax
  ret
