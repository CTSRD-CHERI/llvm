; RUN: llc %s -mtriple=cheri-unknown-freebsd -target-abi sandbox -o - | FileCheck %s

; ModuleID = 'global.c'
target datalayout = "E-m:m-pf200:256:256-i8:8:32-i16:16:32-i64:64-n32:64-S128-A200"
target triple = "cheri-unknown-freebsd"

@x = common addrspace(200) global i32 0, align 4

; Function Attrs: nounwind
define void @foo(i32 signext %y) #0 {
entry:
  ; CHECK: 	ld	$1, %got_disp(x)($1)
  store i32 %y, i32 addrspace(200)* @x, align 4
  ret void
}

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.6.0 "}
