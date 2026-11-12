%macro PRINT 2
    mov rax, 1
    mov rdi, 1
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

%macro INPUT 2
    mov rax, 0
    mov rdi, 0
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

%macro EXIT 0
    mov rax, 60
    xor rdi, rdi
    syscall
%endmacro

section .data
    banner db 10, "  ==========================================================", 10
           db "   ____ _____  _    ____  ____  ____  _   _  ____ _  __", 10
           db "  / ___|_   _|/ \  |  _ \/ ___|| __ )| | | |/ ___| |/ /", 10
           db "  \___ \ | | / _ \ | |_) \___ \|  _ \| | | | |   | ' / ", 10
           db "   ___) || |/ ___ \|  _ < ___) | |_) | |_| | |___| . \ ", 10
           db "  |____/ |_/_/   \_\_| \_\____/|____/ \___/ \____|_|\_\", 10
           db "  ==========================================================", 10, 0
    banner_len equ $ - banner

    menu   db 10, "  [1] Order Drink (Transaction)", 10
           db "  [2] Restock Supplies (Barista Admin)", 10
           db "  [3] Save & Close Register", 10
           db "  Select an option (1-3): "
    menu_len equ $ - menu

    prompt_id   db 10, "  Enter Drink ID (1-3): "
    prompt_id_len equ $ - prompt_id

    prompt_qty  db "  Enter Cups / Quantity (1-9): "
    prompt_qty_len equ $ - prompt_qty

    msg_receipt db 10, "  >>> ORDER COMPLETE! Total Amount: $"
    msg_rec_len equ $ - msg_receipt

    msg_restock db 10, "  >>> INVENTORY RESTOCKED SUCCESSFULLY!", 10
    msg_res_len equ $ - msg_restock

    msg_err_stk db 10, "  [!] SORRY: Out of stock for that quantity!", 10
    msg_err_stk_len equ $ - msg_err_stk

    msg_err_inp db 10, "  [!] ERROR: Invalid selection!", 10
    msg_err_inp_len equ $ - msg_err_inp

    msg_saved   db 10, "  [+] Register saved to starsbuck.dat. Have a great day!", 10
    msg_sav_len equ $ - msg_saved

    tbl_hdr     db 10, "  +----+--------------------+-------+-------+", 10
                db "  | ID | Starsbuck Drink    | Price | Stock |", 10
                db "  +----+--------------------+-------+-------+", 10
    tbl_hdr_len equ $ - tbl_hdr

    tbl_ftr     db "  +----+--------------------+-------+-------+", 10
    tbl_ftr_len equ $ - tbl_ftr

    item1_str   db "  | 1  | Caramel Macchiato  |  $6   |   "
    item1_len   equ $ - item1_str
    item2_str   db "  | 2  | Iced Matcha Latte  |  $5   |   "
    item2_len   equ $ - item2_str
    item3_str   db "  | 3  | Java Chip Frappe   |  $7   |   "
    item3_len   equ $ - item3_str

    row_end     db 10
    filename    db "starsbuck.dat", 0

    stocks      dq 10, 10, 10
    prices      dq 6, 5, 7

section .bss
    choice_buf  resb 4
    id_buf      resb 4
    qty_buf     resb 4
    num_str     resb 16
    fd          resq 1

section .text
    global _start

_start:
    call load_data
    PRINT banner, banner_len

main_loop:
    call display_inventory
    PRINT menu, menu_len
    INPUT choice_buf, 4

    mov al, [choice_buf]
    cmp al, '1'
    je opt_purchase
    cmp al, '2'
    je opt_restock
    cmp al, '3'
    je opt_exit

    PRINT msg_err_inp, msg_err_inp_len
    jmp main_loop

opt_purchase:
    PRINT prompt_id, prompt_id_len
    INPUT id_buf, 4
    movzx rbx, byte [id_buf]
    sub rbx, '1'
    cmp rbx, 2
    ja invalid_input

    PRINT prompt_qty, prompt_qty_len
    INPUT qty_buf, 4
    movzx rcx, byte [qty_buf]
    sub rcx, '0'
    cmp rcx, 1
    jl invalid_input
    cmp rcx, 9
    jg invalid_input

    mov rax, [stocks + rbx*8]
    cmp rax, rcx
    jl insufficient_stock

    sub rax, rcx
    mov [stocks + rbx*8], rax

    mov rax, [prices + rbx*8]
    mul rcx
    push rax

    PRINT msg_receipt, msg_rec_len
    pop rax
    call print_int
    PRINT row_end, 1
    jmp main_loop

opt_restock:
    PRINT prompt_id, prompt_id_len
    INPUT id_buf, 4
    movzx rbx, byte [id_buf]
    sub rbx, '1'
    cmp rbx, 2
    ja invalid_input

    PRINT prompt_qty, prompt_qty_len
    INPUT qty_buf, 4
    movzx rcx, byte [qty_buf]
    sub rcx, '0'
    cmp rcx, 1
    jl invalid_input
    cmp rcx, 9
    jg invalid_input

    add [stocks + rbx*8], rcx
    PRINT msg_restock, msg_res_len
    jmp main_loop

opt_exit:
    call save_data
    PRINT msg_saved, msg_sav_len
    EXIT

invalid_input:
    PRINT msg_err_inp, msg_err_inp_len
    jmp main_loop

insufficient_stock:
    PRINT msg_err_stk, msg_err_stk_len
    jmp main_loop

display_inventory:
    PRINT tbl_hdr, tbl_hdr_len

    PRINT item1_str, item1_len
    mov rax, [stocks]
    call print_int
    PRINT row_end, 1

    PRINT item2_str, item2_len
    mov rax, [stocks + 8]
    call print_int
    PRINT row_end, 1

    PRINT item3_str, item3_len
    mov rax, [stocks + 16]
    call print_int
    PRINT row_end, 1

    PRINT tbl_ftr, tbl_ftr_len
    ret

print_int:
    mov rcx, num_str
    add rcx, 15
    mov byte [rcx], 0
    mov rbx, 10

.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .convert_loop

    mov rdx, num_str
    add rdx, 15
    sub rdx, rcx
    mov rsi, rcx
    mov rax, 1
    mov rdi, 1
    syscall
    ret

load_data:
    mov rax, 2
    mov rdi, filename
    mov rsi, 0
    syscall
    cmp rax, 0
    jl .no_file

    mov [fd], rax
    mov rax, 0
    mov rdi, [fd]
    mov rsi, stocks
    mov rdx, 24
    syscall

    mov rax, 3
    mov rdi, [fd]
    syscall
.no_file:
    ret

save_data:
    mov rax, 2
    mov rdi, filename
    mov rsi, 577
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .save_err

    mov [fd], rax
    mov rax, 1
    mov rdi, [fd]
    mov rsi, stocks
    mov rdx, 24
    syscall

    mov rax, 3
    mov rdi, [fd]
    syscall
.save_err:
    ret
