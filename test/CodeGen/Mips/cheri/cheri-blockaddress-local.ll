; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: %cheri_purecap_llc -cheri-cap-table-abi=pcrel %s -o -
; RUN: %cheri_purecap_llc -cheri-cap-table-abi=pcrel %s -o - | FileCheck %s

; Check that we can generate a binary
; RUN: %cheri_purecap_llc -cheri-cap-table-abi=pcrel %s -o - -filetype=obj | llvm-objdump -d -t -r - | FileCheck %s -check-prefix DUMP
; RUN: %cheri_purecap_llc -cheri-cap-table-abi=pcrel %s -o - -filetype=obj | llvm-readobj -r -
; See address-of-label-crash.c in clang/test/CodeGen/cheri for the C source code

; Function Attrs: noinline nounwind optnone
define i32 @addrof_label_in_local() addrspace(200) {
entry:
  %d = alloca i8 addrspace(200)*, align 16, addrspace(200)
  store i8 addrspace(200)* blockaddress(@addrof_label_in_local, %label2), i8 addrspace(200)* addrspace(200)* %d, align 16
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %d, align 16
  br label %indirectgoto
label2:                                           ; preds = %indirectgoto
  ret i32 2
indirectgoto:                                     ; preds = %entry
  %indirect.goto.dest = phi i8 addrspace(200)* [ %0, %entry ]
  indirectbr i8 addrspace(200)* %indirect.goto.dest, [label %label2]
}

; TODO: we should just emit an offset from function start instead...
;  lui $1, %hi(.Ltmp0 - addrof_label_in_local)
;  daddiu $1, $1, %lo(.Ltmp0 - addrof_label_in_local)
;  cincoffset $c1, $c12, $1


; CHECK-LABEL: addrof_label_in_local:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    cincoffset $c11, $c11, -16
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    cincoffset $c1, $c11, 0
; CHECK-NEXT:    csetbounds $c1, $c1, 16
; Generate a pc-relative blockaddress:
; CHECK-NEXT:    cgetpcc $c2
; CHECK-NEXT:    lui $1, %pcrel_hi(.Ltmp0+4)
; CHECK-NEXT:    daddiu $1, $1, %pcrel_lo(.Ltmp0+8)
; CHECK-NEXT:    cincoffset $c2, $c2, $1
; CHECK-NEXT:    cjr $c2
; CHECK-NEXT:    csc $c2, $zero, 0($c1)
; CHECK-NEXT:  .Ltmp0: # Block address taken
; CHECK-NEXT:  .LBB0_1: # %label2
; CHECK-NEXT:    addiu $2, $zero, 2
; CHECK-NEXT:    cjr $c17
; CHECK-NEXT:    cincoffset $c11, $c11, 16

; DUMP-LABEL: addrof_label_in_local:
; DUMP-NEXT:        0:	4a 6b 5f f0 	cincoffset	$c11, $c11, -16
; DUMP-NEXT:        4:	4a 61 58 00 	cincoffset	$c1, $c11, 0
; DUMP-NEXT:        8:	4a 81 08 10 	csetbounds	$c1, $c1, 16
; DUMP-NEXT:        c:	48 02 07 ff 	cgetpcc	$c2
; DUMP-NEXT:       10:	3c 01 00 00 	lui	$1, 0
; DUMP-NEXT:       14:	64 21 00 18 	daddiu	$1, $1, [[PCREL_LOWER:24]]
; DUMP-NEXT:       18:	48 02 10 51 	cincoffset	$c2, $c2, $1
; DUMP-NEXT:       1c:	48 02 1f ff 	cjr	$c2
; DUMP-NEXT:       20:	f8 41 00 00 	csc	$c2, $zero, 0($c1)
; Check that the jump target address is correct
; DUMP-NEXT:       [[@EXPR hex(0xc + PCREL_LOWER)]]:	24 02 00 02 	addiu	$2, $zero, 2
; DUMP-NEXT:       28:	48 11 1f ff 	cjr	$c17
; DUMP-NEXT:       2c:	4a 6b 58 10 	cincoffset	$c11, $c11, 16
