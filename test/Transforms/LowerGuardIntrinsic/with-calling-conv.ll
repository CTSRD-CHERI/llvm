; RUN: opt -S -lower-guard-intrinsic < %s | FileCheck %s

declare cc999 void @llvm.experimental.guard(i1, ...)

define i8 @f_basic(i1* %c_ptr) {
; CHECK-LABEL: @f_basic(
; CHECK:  br i1 %c, label %guarded, label %deopt
; CHECK: deopt:
; CHECK-NEXT:  %deoptcall = call cc999 i8 (...) @llvm.experimental.deoptimize.i8() [ "deopt"() ]
; CHECK-NEXT:  ret i8 %deoptcall

  %c = load volatile i1, i1* %c_ptr
  call cc999 void(i1, ...) @llvm.experimental.guard(i1 %c) [ "deopt"() ]
  ret i8 6
}
