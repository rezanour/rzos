set -name repo_root -value (get-location) -scope "Global"
set-alias -name fasm -value $repo_root"\build\fasm17139\fasm.exe" -scope "Global"
set-alias -name qemu -value $repo_root"\tools\qemu\qemu-system-i386.exe" -scope "Global"
