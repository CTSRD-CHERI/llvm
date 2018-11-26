; RUN: %cheri_purecap_opt -S -cheri-fold-intrisics -o - %s | FileCheck %s

; Reduced test case for a crash in the new optimization to fold multiple setoffset calls (orignally found when compiling libunwind)

; Function Attrs: nounwind readnone
declare i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)*, i64) addrspace(200) #2

define i8 addrspace(200)* @test() addrspace(200) {
entry:
  %0 = sext i8 undef to i64
  %1 = call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 %0)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* %1, i64 10)
  ret i8 addrspace(200)* %2
}

; CHECK-LABEL: define i8 addrspace(200)* @test()
; CHECK-NEXT:   entry:
; CHECK-NEXT:    %0 = call i8 addrspace(200)* @llvm.cheri.cap.offset.increment(i8 addrspace(200)* null, i64 10)
; CHECK-NEXT:    ret i8 addrspace(200)* %0
; CHECK-NEXT: }
