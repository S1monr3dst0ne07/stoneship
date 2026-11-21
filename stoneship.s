
#   ---=== stoneship ===---
#  like a ship made from stone
#     this shall surely sink

# instructions used in this implementation are chosen to have simple encodings. 
# complex addressing modes, as well as the upper 8 registers are not used.

#              --- elf header ---
7f 45 4c 46             # EI_MAG          -> '\x7fELF'
02                      # EI_CLASS        -> 64-bit
01                      # EI_DATA         -> little endian
01                      # EI_VERSION      -> just 1
00                      # EI_OSABI        -> just 0
00                      # EI_OSABIVERSION -> just 0
00 00 00 00 00 00 00    # EI_PAD          -> padding
02 00                   # e_type          -> ET_EXEC
3e 00                   # e_machine       -> AMD64
01 00 00 00             # e_version       -> just 1
78 00 00 00 00 00 00 00 # e_entry         = 64 + 56 = 120
40 00 00 00 00 00 00 00 # e_phoff         = 64
00 00 00 00 00 00 00 00 # e_shoff         -> no sections
00 00 00 00             # e_flags         = 0
40 00                   # e_ehsize        = 64
38 00                   # e_phentsize     =      56
01 00                   # e_phnum         = 1
00 00                   # e_shentsize     = 0  (no sections)
00 00                   # e_shnum         = 0  (no sections)
00 00                   # e_shstrndx      = 0  (no section names)

# --- program header ---
01 00 00 00             # p_type          -> PT_LOAD
07 00 00 00             # p_flags         -> RWX
00 00 00 00 00 00 00 00 # p_offset        = 0
00 00 00 00 00 00 00 00 # p_vaddr         = 0
00 00 00 00 00 00 00 00 # p_paddr         -> not used on amd64
28 01 00 00 00 00 00 00 # p_filesz        = 296
00 00 30 00 00 00 00 00 # p_memsz         = 0x300000
00 10 00 00 00 00 00 00 # p_align         = 0x1000


# --- start of program ---

# the source buffer is at 0x100000
# the output buffer is at 0x200000
# both are 0x100000 bytes long and
# hence the program is 0x300000 bytes in memory.

    # make shadow stack frame
    48 8b ec                # mov rbp, rsp
    
    # open source file
    48 8b cd                # mov rcx, rbp
    48 31 c0                # xor rax, rax
    b0 02                   # mov al, 2         (sys_open)
    48 8b 79 10             # mov rdi, [rcx+16] (argc[1])
    48 31 f6                # xor rsi, rsi      (O_RDONLY)
    48 31 d2                # xor rdx, rdx      (no flags)
    0f 05                   # syscall
    
    # read source file into buffer
    48 8b f8                # mov rdi, rax      (save fd)
    48 31 c0                # xor rax, rax      (sys_read)
    48 c7 c6 00 00 10 00    # mov rsi, 0x100000 (source base pointer)
    48 c7 c2 00 00 10 00    # mov rdx, 0x100000 (source max length)
    0f 05                   # syscall
    
    # set up source / output pointers, and counter
    48 c7 c6 00 00 10 00    # mov rsi, 0x100000
    48 c7 c7 00 00 20 00    # mov rdi, 0x200000
    48 31 c9                # xor rcx, rcx

# -- start of main loop --
# register summary:
#  al -> input character
#  bx -> temporary
# rcx -> output nybble counter
#  dl -> byte accumulator
# rsi -> source pointer 
# rdi -> output pointer

# 0x3e again:
    # read new character from source buffer
    # and check for null terminator
    ac                      # lodsb
    a8 ff                   # test al, 0xff
    74 31                   # jz done
    
    # skip space and newlines
    3c 20                   # cmp al, ' '
    74 f7                   # je again
    3c 0a                   # cmp al, '\n'
    74 f3                   # je again

    # comment entry
    3c 23                   # cmp al, '#'
    74 1e                   # je comment
    
    # convert character to digit value
    2c 30                   # sub al, '0'
    88 c3                   # mov bl, al
    80 eb 27                # sub bl, '9'+1-'a'
    3c 09                   # cmp al, 9
    0f 47 c3                # cmova ax, bx
    
    # shift digit nybble into data accumulator
    c0 e2 04                # shl dl, 4
    08 c2                   # or  dl, al
    
    # only emit every other time
    # because two nybbles make a byte
    48 ff c1                # inc rcx
    f6 c1 01                # test cl, 1
    75 d6                   # jnz again
    
    # every other time, a byte is formed
    88 d0                   # mov al, dl
    aa                      # stosb
    eb d1                   # jmp again
    
# 0x6d comment:
    # drop characters until newline is hit
    ac                      # lodsb
    3c 0a                   # cmp al, '\n'
    75 fb                   # jne comment
    eb ce                   # jmp again

# 0x74 done:
    # save output byte count
    48 D1 e9                # shr rcx, 1
    51                      # push rcx

    # open output file
    48 8b cd                # mov rcx, rbp
    48 31 c0                # xor rax, rax
    b0 02                   # mov al, 2         (sys_open)
    48 8b 79 18             # mov rdi, [rcx+24] (argc[2])
    48 c7 c6 41 02 00 00    # mov rsi, 0x241    (O_WDONLY | O_CREAT | O_TRUNC)      
    48 c7 c2 6d 01 00 00    # mov rdx, 0o555    ( a+rx )
    0f 05                   # syscall

    # write bytes to output 
    48 8b f8                # mov rdi, rax      (save fd)
    48 31 c0                # xor rax, rax
    b0 01                   # mov al, 1         (sys_write)
    48 c7 c6 00 00 20 00    # mov rsi, 0x200000
    5a                      # pop rdx
    0f 05                   # syscall

    # exit with status zero
    48 31 c0                # xor rax, rax
    b0 3c                   # mov al, 60        (sys_exit)
    48 31 ff                # xor rdi, rdi
    0f 05                   # syscall


