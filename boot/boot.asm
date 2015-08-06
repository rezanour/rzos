boot_start:
    jmp boot_start

    rb 510-($-$$)   ; fill up to the 510th byte
    dw 0xaa55       ; boot loader signature
