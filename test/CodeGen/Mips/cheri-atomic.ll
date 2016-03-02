; RUN: llc %s -mtriple=cheri-unknown-freebsd -target-abi sandbox -o - | FileCheck %s
; ModuleID = 'atomic.c'
target datalayout = "E-m:m-pf200:256:256-i8:8:32-i16:16:32-i64:64-n32:64-S128-A200"
target triple = "cheri-unknown-freebsd"

@d = common addrspace(200) global i64 0, align 8
@w = common addrspace(200) global i32 0, align 4
@h = common addrspace(200) global i16 0, align 2
@b = common addrspace(200) global i8 0, align 1
@du = common addrspace(200) global i64 0, align 8
@wu = common addrspace(200) global i32 0, align 4
@hu = common addrspace(200) global i16 0, align 2
@bu = common addrspace(200) global i8 0, align 1
@x = common addrspace(200) global i32 addrspace(200)* null, align 32

; Function Attrs: nounwind
; CHECK-LABEL: incd:
define void @incd() #0 {
entry:
  ; CHECK: clld
  ; CHECK: cscd
  %0 = atomicrmw add i64 addrspace(200)* @d, i64 1 seq_cst
  ret void
}

; Function Attrs: nounwind
; CHECK-LABEL: incw:
define void @incw() #0 {
entry:
  ; CHECK: cllw
  ; CHECK: cscw
  %0 = atomicrmw add i32 addrspace(200)* @w, i32 1 seq_cst
  ret void
}

; Function Attrs: nounwind
; CHECK-LABEL: inch:
define void @inch() #0 {
  ; CHECK: cllh
  ; CHECK: csch
entry:
  %0 = atomicrmw add i16 addrspace(200)* @h, i16 1 seq_cst
  ret void
}

; Function Attrs: nounwind
; CHECK-LABEL: incb:
define void @incb() #0 {
entry:
  ; CHECK: cllb
  ; CHECK: cscb
  %0 = atomicrmw add i8 addrspace(200)* @b, i8 1 seq_cst
  ret void
}

; Function Attrs: nounwind
; CHECK-LABEL: incdu:
define void @incdu() #0 {
entry:
  ; CHECK: clld
  ; CHECK: cscd
  %0 = atomicrmw add i64 addrspace(200)* @du, i64 1 seq_cst
  ret void
}

; Function Attrs: nounwind
; CHECK-LABEL: incwu:
define void @incwu() #0 {
entry:
  ; CHECK: cllw
  ; CHECK: cscw
  %0 = atomicrmw add i32 addrspace(200)* @wu, i32 1 seq_cst
  ret void
}

; Function Attrs: nounwind
; CHECK-LABEL: inchu:
define void @inchu() #0 {
entry:
  %0 = atomicrmw add i16 addrspace(200)* @hu, i16 1 seq_cst
  ret void
}

; Function Attrs: nounwind
; CHECK-LABEL: incbu:
define void @incbu() #0 {
entry:
  %0 = atomicrmw add i8 addrspace(200)* @bu, i8 1 seq_cst
  ret void
}

; Function Attrs: nounwind
; CHECK-LABEL: swapd:
define i32 @swapd(i64 addrspace(200)* nocapture %e, i64 signext %n) #0 {
entry:
  ; CHECK: clld
  ; CHECK: cscd
  %0 = load i64, i64 addrspace(200)* %e, align 8
  %1 = cmpxchg i64 addrspace(200)* @d, i64 %0, i64 %n seq_cst seq_cst
  %2 = extractvalue { i64, i1 } %1, 1
  br i1 %2, label %cmpxchg.continue, label %cmpxchg.store_expected

cmpxchg.store_expected:                           ; preds = %entry
  %3 = extractvalue { i64, i1 } %1, 0
  store i64 %3, i64 addrspace(200)* %e, align 8
  br label %cmpxchg.continue

cmpxchg.continue:                                 ; preds = %cmpxchg.store_expected, %entry
  %conv = zext i1 %2 to i32
  ret i32 %conv
}

; Function Attrs: nounwind
; CHECK-LABEL: swapw:
define i32 @swapw(i32 addrspace(200)* nocapture %e, i32 signext %n) #0 {
entry:
  ; CHECK: cllw
  ; CHECK: cscw
  %0 = load i32, i32 addrspace(200)* %e, align 4
  %1 = cmpxchg i32 addrspace(200)* @w, i32 %0, i32 %n seq_cst seq_cst
  %2 = extractvalue { i32, i1 } %1, 1
  br i1 %2, label %cmpxchg.continue, label %cmpxchg.store_expected

cmpxchg.store_expected:                           ; preds = %entry
  %3 = extractvalue { i32, i1 } %1, 0
  store i32 %3, i32 addrspace(200)* %e, align 4
  br label %cmpxchg.continue

cmpxchg.continue:                                 ; preds = %cmpxchg.store_expected, %entry
  %conv = zext i1 %2 to i32
  ret i32 %conv
}

; Function Attrs: nounwind
; CHECK-LABEL: swaph:
define i32 @swaph(i16 addrspace(200)* nocapture %e, i16 signext %n) #0 {
  ; CHECK: cllh
  ; CHECK: csch
entry:
  %0 = load i16, i16 addrspace(200)* %e, align 2
  %1 = cmpxchg i16 addrspace(200)* @h, i16 %0, i16 %n seq_cst seq_cst
  %2 = extractvalue { i16, i1 } %1, 1
  br i1 %2, label %cmpxchg.continue, label %cmpxchg.store_expected

cmpxchg.store_expected:                           ; preds = %entry
  %3 = extractvalue { i16, i1 } %1, 0
  store i16 %3, i16 addrspace(200)* %e, align 2
  br label %cmpxchg.continue

cmpxchg.continue:                                 ; preds = %cmpxchg.store_expected, %entry
  %conv = zext i1 %2 to i32
  ret i32 %conv
}

; Function Attrs: nounwind
; CHECK-LABEL: swapb:
define i32 @swapb(i8 addrspace(200)* nocapture %e, i8 signext %n) #0 {
entry:
  ; CHECK: cllb
  ; CHECK: cscb
  %0 = load i8, i8 addrspace(200)* %e, align 1
  %1 = cmpxchg i8 addrspace(200)* @b, i8 %0, i8 %n seq_cst seq_cst
  %2 = extractvalue { i8, i1 } %1, 1
  br i1 %2, label %cmpxchg.continue, label %cmpxchg.store_expected

cmpxchg.store_expected:                           ; preds = %entry
  %3 = extractvalue { i8, i1 } %1, 0
  store i8 %3, i8 addrspace(200)* %e, align 1
  br label %cmpxchg.continue

cmpxchg.continue:                                 ; preds = %cmpxchg.store_expected, %entry
  %conv = zext i1 %2 to i32
  ret i32 %conv
}

; Function Attrs: nounwind
; CHECK-LABEL: fetchaddd:
define i64 @fetchaddd(i64 addrspace(200)* %f, i64 signext %x) #0 {
entry:
  ; CHECK: clld
  ; CHECK: cscd
  %0 = atomicrmw add i64 addrspace(200)* %f, i64 1 seq_cst
  ret i64 %0
}

; Function Attrs: nounwind
; CHECK-LABEL: fetchaddw:
define i32 @fetchaddw(i32 addrspace(200)* %f, i32 signext %x) #0 {
entry:
  ; CHECK: cllw
  ; CHECK: cscw
  %0 = atomicrmw add i32 addrspace(200)* %f, i32 1 seq_cst
  ret i32 %0
}

; Function Attrs: nounwind
; CHECK-LABEL: fetchaddh:
define signext i16 @fetchaddh(i16 addrspace(200)* %f, i16 signext %x) #0 {
  ; CHECK: cllh
  ; CHECK: csch
entry:
  %0 = atomicrmw add i16 addrspace(200)* %f, i16 1 seq_cst
  ret i16 %0
}

; Function Attrs: nounwind
; CHECK-LABEL: fetchaddb:
define signext i8 @fetchaddb(i8 addrspace(200)* %f, i8 signext %x) #0 {
entry:
  ; CHECK: cllb
  ; CHECK: cscb
  %0 = atomicrmw add i8 addrspace(200)* %f, i8 1 seq_cst
  ret i8 %0
}

attributes #0 = { nounwind "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-features"="+cheri" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.7.0 (ssh://dc552@vica.cl.cam.ac.uk:/home/dc552/CHERISDK/llvm/tools/clang 3da05ea3ad6db2e2d768f7fc72bcf5e6fa35ee14) (ssh://dc552@vica.cl.cam.ac.uk:/home/dc552/CHERISDK/llvm 922cf8569084e404af3b94a89d8ad4786d6d8c74)"}
