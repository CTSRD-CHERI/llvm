; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; See tools/clang/test/CodeGen/cheri/libcxx-filesystem-crash.cpp
; RUN: %cheri_purecap_llc -disable-cheri-addressing-mode-folder=true -o - %s -debug-only=isel
; RUN: %cheri_purecap_llc -disable-cheri-addressing-mode-folder=true -o - %s | FileCheck %s
; RUN: %cheri_purecap_llc -disable-cheri-addressing-mode-folder=false -o - %s | FileCheck %s

%class.duration = type { i32 }
%class.duration.0 = type { i128 }

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.start.p200i8(i64, i8 addrspace(200)* nocapture) addrspace(200) #1

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.end.p200i8(i64, i8 addrspace(200)* nocapture) addrspace(200) #1

; Function Attrs: nounwind readonly
define i128 @test2(%class.duration.0 addrspace(200)* nocapture readonly dereferenceable(16) %e) local_unnamed_addr addrspace(200) #0 {
; CHECK-LABEL: test2:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    cincoffset $c11, $c11, -[[STACKFRAME_SIZE:16|32]]
; CHECK-NEXT:    .cfi_def_cfa_offset [[STACKFRAME_SIZE]]
; CHECK-NEXT:    clc $c1, $zero, 0($c3)
; CHECK-NEXT:    csc $c1, $zero, 0($c11)
; CHECK-NEXT:    cld $2, $zero, 0($c11)
; CHECK-NEXT:    cld $3, $zero, 8($c11)
; CHECK-NEXT:    cjr $c17
; CHECK-NEXT:    cincoffset $c11, $c11, [[STACKFRAME_SIZE]]
entry:
  %ref.tmp.sroa.0 = alloca i8 addrspace(200)*, align 16, addrspace(200)
  %tmpcast = bitcast i8 addrspace(200)* addrspace(200)* %ref.tmp.sroa.0 to i128 addrspace(200)*
  %ref.tmp.sroa.0.0..sroa_cast4 = bitcast i8 addrspace(200)* addrspace(200)* %ref.tmp.sroa.0 to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 16, i8 addrspace(200)* nonnull %ref.tmp.sroa.0.0..sroa_cast4)
  %0 = bitcast %class.duration.0 addrspace(200)* %e to i8 addrspace(200)* addrspace(200)*
  %1 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %0, align 16
  store i8 addrspace(200)* %1, i8 addrspace(200)* addrspace(200)* %ref.tmp.sroa.0, align 16
  %ref.tmp.sroa.0.0.ref.tmp.sroa.0.0. = load i128, i128 addrspace(200)* %tmpcast, align 16
  call void @llvm.lifetime.end.p200i8(i64 16, i8 addrspace(200)* nonnull %ref.tmp.sroa.0.0..sroa_cast4)
  ret i128 %ref.tmp.sroa.0.0.ref.tmp.sroa.0.0.
}
