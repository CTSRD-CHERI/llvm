; MIPS is inefficient and generates a mul instruction....
; RUN: %cheri_llc %s -O2 -mxgot -target-abi n64 -relocation-model=pic -cheri-cap-table -o -
; RUN: %cheri_purecap_llc %s -O2 -cheri-cap-table -o - -mxcaptable=true | %cheri_FileCheck %s
; RUN: %cheri_purecap_llc %s -O2 -cheri-cap-table -o - -mxcaptable=false | %cheri_FileCheck %s -check-prefix SMALLTABLE
; RUN: %cheri_purecap_llc %s -O0 -cheri-cap-table -o - | %cheri_FileCheck %s -check-prefixes NO-OPT
; ModuleID = '/Users/alex/cheri/build/llvm-256-build/cap-table-jump-table-reduce.ll-reduced-simplified.bc'
source_filename = "cap-table-jump-table-reduce.ll-output-7f90547.bc"
target datalayout = "E-m:e-pf200:256:256-i8:8:32-i16:16:32-i64:64-n32:64-S128-A200"
target triple = "cheri-unknown-freebsd"

; XXXAR: if I use i32 for the switch here the MIPS backend does a stupid mask to 32 bits on the arg
; because it uses the SLTiu nstead of STLiu64 instruction to check the range of the instrs

; XXXAR: also it uses a MUL instead of shift in the MIPS case, I should just make it do a shift
; in the expandMUL() if the other value is a known constant

; Function Attrs: noreturn nounwind
define i64 @c(i64 %arg) local_unnamed_addr #0 {
entry:
  switch i64 %arg, label %default [
    i64 0, label %sw.bb
    i64 3, label %sw.bb
    i64 5, label %sw.bb
    i64 10, label %sw.bb1
  ]

default:
  ret i64 1234

sw.bb:
  ret i64 1

sw.bb1:
  ret i64 0
}

; BIGTABLE:      lui     $1, %captab_hi(.LJTI0_0)
; BIGTABLE-NEXT: daddiu  $1, $1, %captab_lo(.LJTI0_0)
; BIGTABLE-NEXT: clc     $c1, $1, 0($c26)
; SMALLTABLE:    clc     $c1, $zero, %captab(.LJTI0_0)($c26)



; CHECK-LABEL:# BB#0:                                 # %entry
; CHECK-NEXT:	sltiu	$1, $4, 11
; CHECK-NEXT:	beqz	$1, .LBB0_3
; CHECK-NEXT:	nop

; CHECK-LABEL: .LBB0_1:                                # %entry
; CHECK-NEXT:	lui	$1, %captab_hi(.LJTI0_0)
; CHECK-NEXT:	daddiu	$1, $1, %captab_lo(.LJTI0_0)
; CHECK-NEXT:	clc	$c1, $1, 0($c26)
; CHECK-NEXT:	dsll	$1, $4, 2
; CHECK-NEXT:	clw	$1, $1, 0($c1)
; CHECK-NEXT:	cincoffset	$c1, $c1, $1
; TODO: this is not ideal but we need to derive an executable capability
; CHECK-NEXT:	cgetpcc	$c2
; CHECK-NEXT:	csub	$1, $c1, $c2
; CHECK-NEXT:	cincoffset	$c1, $c2, $1
; CHECK-NEXT:	cjr	$c1
; CHECK-NEXT:	nop

; CHECK-LABEL: .LBB0_2:                                # %sw.bb
; CHECK-NEXT: 	cjr	$c17
; CHECK-NEXT: 	daddiu	$2, $zero, 1
; CHECK-LABEL: .LBB0_3:                                # %default
; CHECK-NEXT: 	cjr	$c17
; CHECK-NEXT: 	daddiu	$2, $zero, 1234
; CHECK-LABEL: .LBB0_4:                                # %sw.bb1
; CHECK-NEXT: 	cjr	$c17
; CHECK-NEXT: 	daddiu	$2, $zero, 0
; CHECK-NEXT: 	.set	at
; CHECK: 	.end	c
; CHECK-LABEL: .Lfunc_end0:
; CHECK-NEXT: 	.size	c, .Lfunc_end0-c
; CHECK-NEXT: 	.section	.rodata,"a",@progbits
; CHECK-NEXT: 	.p2align	2
; CHECK-LABEL: .LJTI0_0:
; CHECK-NEXT: 	.4byte	.LBB0_2-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_3-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_3-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_2-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_3-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_2-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_3-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_3-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_3-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_3-.LJTI0_0
; CHECK-NEXT: 	.4byte	.LBB0_4-.LJTI0_0


; NO-OPT-LABEL: # BB#0:                                 # %entry
; NO-OPT-NEXT:	cincoffset	$c11, $c11, -[[@EXPR 3 * $CAP_SIZE]]
; NO-OPT-NEXT:	cmove	$c1,  $c26
; NO-OPT-NEXT:	move	 $1, $4
; NO-OPT-NEXT:	sltiu	$2, $4, 11
; NO-OPT-NEXT:	csd	$1, $zero, [[@EXPR (3 * $CAP_SIZE) - 8]]($c11)     # 8-byte Folded Spill
; NO-OPT-NEXT:	csc	$c1, $zero, [[$CAP_SIZE]]($c11)    # [[$CAP_SIZE]]-byte Folded Spill
; NO-OPT-NEXT:	csd	$4, $zero, [[@EXPR $CAP_SIZE - 8]]($c11)     # 8-byte Folded Spill
; NO-OPT-NEXT:	beqz	$2, .LBB0_2
; NO-OPT-NEXT:	nop
; NO-OPT-LABEL: .LBB0_1:                                # %entry
; NO-OPT-NEXT:	cld	$1, $zero, [[@EXPR $CAP_SIZE - 8]]($c11)     # 8-byte Folded Reload
; NO-OPT-NEXT:	dsll	$2, $1, 2
; NO-OPT-NEXT:	lui	$3, %captab_hi(.LJTI0_0)
; NO-OPT-NEXT:	daddiu	$3, $3, %captab_lo(.LJTI0_0)
; NO-OPT-NEXT:	clc	$c1, $zero, [[$CAP_SIZE]]($c11)    # [[$CAP_SIZE]]-byte Folded Reload
; NO-OPT-NEXT:	clc	$c2, $3, 0($c1)
; NO-OPT-NEXT:	clw	$2, $2, 0($c2)
; NO-OPT-NEXT:	cincoffset	$c2, $c2, $2
; NO-OPT-NEXT:	cgetpcc	$c3
; NO-OPT-NEXT:	csub	$2, $c2, $c3
; NO-OPT-NEXT:	cincoffset	$c2, $c3, $2
; NO-OPT-NEXT:	cjr	$c2
; NO-OPT-NEXT:	nop

attributes #0 = { noreturn nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-features"="+cheri" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 6.0.0 (https://github.com/llvm-mirror/clang.git 41c2892ed18fcb87c7a4c0dc1fb1e62d38ea3119) (https://github.com/llvm-mirror/llvm.git 9fca120cea84d71524a8b1e7738e9788666571e2)"}
