; RUN: %cheri_llc %s -mtriple=cheri-unknown-freebsd -target-abi purecap -o - -asm-verbose -verify-regalloc -O0 | FileCheck %s
; RUN: %cheri_llc %s -mtriple=cheri-unknown-freebsd -target-abi purecap -o - -asm-verbose -verify-regalloc -O1 | FileCheck %s -check-prefix OPT
; RUN: %cheri_llc %s -mtriple=cheri-unknown-freebsd -target-abi purecap -o - -asm-verbose -verify-regalloc -O2 | FileCheck %s -check-prefix OPT
; ModuleID = '/local/scratch/alr48/cheri/llvm/tools/clang/test/CodeGenCXX/cheri-pointer-to-member-simple.cpp'
source_filename = "/local/scratch/alr48/cheri/llvm/tools/clang/test/CodeGenCXX/cheri-pointer-to-member-simple.cpp"
target datalayout = "E-m:e-pf200:256:256-i8:8:32-i16:16:32-i64:64-n32:64-S128-A200"
target triple = "cheri-unknown-freebsd"

%class.A = type <{ i32 (...) addrspace(200)* addrspace(200)*, i32, i32, [24 x i8] }>

@global_func_ptr = external local_unnamed_addr addrspace(200) global void (%class.A addrspace(200)*) addrspace(200)*, align 32

; Function Attrs: nounwind
define i32 @func_ptr_dereference(%class.A addrspace(200)* %a, i8 addrspace(200)* inreg %ptr.coerce0, i64 inreg %ptr.coerce1) local_unnamed_addr #0 {
entry:
  %memptr.adj.shifted = ashr i64 %ptr.coerce1, 1
  %this.not.adjusted = bitcast %class.A addrspace(200)* %a to i8 addrspace(200)*
  %memptr.vtable.addr = getelementptr inbounds i8, i8 addrspace(200)* %this.not.adjusted, i64 %memptr.adj.shifted
  %this.adjusted = bitcast i8 addrspace(200)* %memptr.vtable.addr to %class.A addrspace(200)*
  %0 = and i64 %ptr.coerce1, 1
  %memptr.isvirtual = icmp eq i64 %0, 0
  br i1 %memptr.isvirtual, label %memptr.nonvirtual, label %memptr.virtual

memptr.virtual:                                   ; preds = %entry
  %1 = bitcast i8 addrspace(200)* %memptr.vtable.addr to i8 addrspace(200)* addrspace(200)*
  %vtable = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %1, align 32, !tbaa !2
  %memptr.vtable.offset = ptrtoint i8 addrspace(200)* %ptr.coerce0 to i64
  %2 = getelementptr i8, i8 addrspace(200)* %vtable, i64 %memptr.vtable.offset
  %3 = bitcast i8 addrspace(200)* %2 to i32 (%class.A addrspace(200)*) addrspace(200)* addrspace(200)*
  %memptr.virtualfn = load i32 (%class.A addrspace(200)*) addrspace(200)*, i32 (%class.A addrspace(200)*) addrspace(200)* addrspace(200)* %3, align 32
  br label %memptr.end

memptr.nonvirtual:                                ; preds = %entry
  %memptr.nonvirtualfn = bitcast i8 addrspace(200)* %ptr.coerce0 to i32 (%class.A addrspace(200)*) addrspace(200)*
  br label %memptr.end

memptr.end:                                       ; preds = %memptr.nonvirtual, %memptr.virtual
  %4 = phi i32 (%class.A addrspace(200)*) addrspace(200)* [ %memptr.virtualfn, %memptr.virtual ], [ %memptr.nonvirtualfn, %memptr.nonvirtual ]
  %call = tail call i32 %4(%class.A addrspace(200)* %this.adjusted) #1
  ret i32 %call

  ; CHECK: cincoffset      $c1, $c3, $zero
  ; get adj in $2
  ; CHECK: dsra    $2, $4, 1
  ; adjust this:
  ; CHECK: cincoffset      $c3, $c3, $2
  ; store a copy in c2
  ; CHECK: cincoffset      $c2, $c3, $zero
  ; CHECK: andi    $2, $4, 1
  ; CHECK:      csc     $c2, [[STACK_VTABLE_ADDR:\$zero, ([0-9]+)\(\$c24\)]]
  ; CHECK-NEXT: csc     $c3, [[STACK_THIS_ADJ:\$zero, ([0-9]+)\(\$c24\)]]
  ; CHECK-NEXT: csc     $c1, $zero, {{[0-9]+}}($c24)
  ; CHECK-NEXT: csc     $c4, [[STACK_MEMPTR_PTR:\$zero, ([0-9]+)\(\$c24\)]]
  ; CHECK-NEXT: beqz    $2, .LBB0_3

  ; CHECK: .LBB0_2:                                # %memptr.virtual
  ; CHECK: clc     $c1, [[STACK_VTABLE_ADDR]]
  ; CHECK: clc     $c2, $zero, 0($c1)
  ; CHECK: clc     [[MEMPTR:\$c3]], [[STACK_MEMPTR_PTR]]
  ; CHECK: ctoptr $1, [[MEMPTR]], $c0
  ; CHECK: clc     $c2, $1, 0($c2)
  ; CHECK: csc     $c2, [[STACK_TARGET_FN_PTR:\$zero, ([0-9]+)\(\$c24\)]]
  ; CHECK: j       .LBB0_4
  ; CHECK: nop

  ; CHECK: .LBB0_3:                                # %memptr.nonvirtual
  ; CHECK: clc     $c1, $zero, 32($c24)      # {{16|32}}-byte Folded Reload
  ; CHECK: csc     $c1, [[STACK_TARGET_FN_PTR]]
  ; CHECK: j       .LBB0_4
  ; CHECK: nop
  ; CHECK: .LBB0_4:                                # %memptr.end
  ; CHECK: clc     $c1, [[STACK_TARGET_FN_PTR]]
  ; CHECK: clc     $c3, [[STACK_THIS_ADJ]]
  ; CHECK: cincoffset      $c12, $c1, $zero
  ; CHECK: cjalr   $c12, $c17
  ; CHECK: nop
  ; CHECK: clc     $c17, $zero, {{112|192}}($c11)    # {{16|32}}-byte Folded Reload
  ; CHECK: daddiu  $1, $zero, 224
  ; CHECK: cincoffset      $c11, $c11, $1
  ; CHECK: cjr     $c17




  ; OPT: cincoffset      [[THIS_NON_ADJ:\$c1]], $c3, $zero
  ; OPT: dsra    [[ADJ:\$2]], $4, 1
  ; OPT: andi    $1, $4, 1
  ; OPT: beqz    $1, .LBB0_2
  ; OPT: cincoffset      [[THIS_ADJ:\$c3]], [[THIS_NON_ADJ]], [[ADJ]]
  ; virtual case:
  ; OPT: clc     [[VTABLE:\$c[0-9]+]], [[ADJ]], 0([[THIS_NON_ADJ]])
  ; OPT: ctoptr  [[VTABLE_OFFSET:\$1]], $c4, $c0
  ; OPT: clc     $c4, [[VTABLE_OFFSET]], 0([[VTABLE]])
  ; OPT: .LBB0_2:                                # %memptr.end
  ; OPT: cincoffset      $c12, $c4, $zero
  ; OPT: cjalr   $c12, $c17
  ; OPT: nop
  ; OPT: clc     $c17, $zero, 0($c11)      # {{16|32}}-byte Folded Reload
  ; OPT: cjr     $c17
}

; ; Function Attrs: nounwind
; define void @call_global_func_ptr(%class.A addrspace(200)* %a) local_unnamed_addr #0 {
; entry:
;   %0 = load void (%class.A addrspace(200)*) addrspace(200)*, void (%class.A addrspace(200)*) addrspace(200)* addrspace(200)* @global_func_ptr, align 32, !tbaa !5
;   tail call void %0(%class.A addrspace(200)* %a) #1
;   ret void
; }
;
; ; Function Attrs: nounwind
; define void @call_func_ptr_param(void (%class.A addrspace(200)*) addrspace(200)* nocapture %func, %class.A addrspace(200)* %a) local_unnamed_addr #0 {
; entry:
;   tail call void %func(%class.A addrspace(200)* %a) #1
;   ret void
; }
;
; ; Function Attrs: nounwind
; define void @call_func_ptr_adjusted(void (%class.A addrspace(200)*) addrspace(200)* nocapture %func, %class.A addrspace(200)* %a, i64 signext %this_adj) local_unnamed_addr #0 {
; entry:
;   %0 = bitcast %class.A addrspace(200)* %a to i8 addrspace(200)*
;   %add.ptr = getelementptr inbounds i8, i8 addrspace(200)* %0, i64 %this_adj
;   %1 = bitcast i8 addrspace(200)* %add.ptr to %class.A addrspace(200)*
;   tail call void %func(%class.A addrspace(200)* %1) #1
;   ret void
; }
;
; ; Function Attrs: nounwind
; define void @call_func_ptr_adjusted_2(%class.A addrspace(200)* %a, void (%class.A addrspace(200)*) addrspace(200)* nocapture %func, i64 signext %this_adj) local_unnamed_addr #0 {
; entry:
;   %0 = bitcast %class.A addrspace(200)* %a to i8 addrspace(200)*
;   %add.ptr = getelementptr inbounds i8, i8 addrspace(200)* %0, i64 %this_adj
;   %1 = bitcast i8 addrspace(200)* %add.ptr to %class.A addrspace(200)*
;   tail call void %func(%class.A addrspace(200)* %1) #1
;   ret void
; }

attributes #0 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="cheri" "target-features"="+cheri" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"PIC Level", i32 2}
!1 = !{!"clang version 5.0.0 (https://github.com/llvm-mirror/clang.git e00d4a4e238136bccf5b74265fad7d00b761901a) (https://github.com/llvm-mirror/llvm.git e4edd510857c599e28c1b20cbcd24fdee0f3407f)"}
!2 = !{!3, !3, i64 0}
!3 = !{!"vtable pointer", !4, i64 0}
!4 = !{!"Simple C++ TBAA"}
!5 = !{!6, !6, i64 0}
!6 = !{!"any pointer", !7, i64 0}
!7 = !{!"omnipotent char", !4, i64 0}
