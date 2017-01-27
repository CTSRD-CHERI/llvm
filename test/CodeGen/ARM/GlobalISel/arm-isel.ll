; RUN: llc -mtriple arm-unknown -global-isel %s -o - | FileCheck %s

define void @test_void_return() {
; CHECK-LABEL: test_void_return:
; CHECK: bx lr
entry:
  ret void
}

define zeroext i1 @test_zext_i1(i1 %x) {
; CHECK-LABEL: test_zext_i1
; CHECK: and r0, r0, #1
; CHECK: bx lr
entry:
  ret i1 %x
}

define signext i1 @test_sext_i1(i1 %x) {
; CHECK-LABEL: test_sext_i1
; CHECK: and r0, r0, #1
; CHECK: rsb r0, r0, #0
; CHECK: bx lr
entry:
  ret i1 %x
}

define zeroext i8 @test_ext_i8(i8 %x) {
; CHECK-LABEL: test_ext_i8:
; CHECK: uxtb r0, r0
; CHECK: bx lr
entry:
  ret i8 %x
}

define signext i16 @test_ext_i16(i16 %x) {
; CHECK-LABEL: test_ext_i16:
; CHECK: sxth r0, r0
; CHECK: bx lr
entry:
  ret i16 %x
}

define i8 @test_add_i8(i8 %x, i8 %y) {
; CHECK-LABEL: test_add_i8:
; CHECK: add r0, r0, r1
; CHECK: bx lr
entry:
  %sum = add i8 %x, %y
  ret i8 %sum
}

define i16 @test_add_i16(i16 %x, i16 %y) {
; CHECK-LABEL: test_add_i16:
; CHECK: add r0, r0, r1
; CHECK: bx lr
entry:
  %sum = add i16 %x, %y
  ret i16 %sum
}

define i32 @test_add_i32(i32 %x, i32 %y) {
; CHECK-LABEL: test_add_i32:
; CHECK: add r0, r0, r1
; CHECK: bx lr
entry:
  %sum = add i32 %x, %y
  ret i32 %sum
}

define i32 @test_stack_args_i32(i32 %p0, i32 %p1, i32 %p2, i32 %p3, i32 %p4, i32 %p5) {
; CHECK-LABEL: test_stack_args_i32:
; CHECK: add [[P5ADDR:r[0-9]+]], sp, #4
; CHECK: ldr [[P5:r[0-9]+]], {{.*}}[[P5ADDR]]
; CHECK: add r0, r2, [[P5]]
; CHECK: bx lr
entry:
  %sum = add i32 %p2, %p5
  ret i32 %sum
}

define i16 @test_stack_args_mixed(i32 %p0, i16 %p1, i8 %p2, i1 %p3, i8 %p4, i16 %p5) {
; CHECK-LABEL: test_stack_args_mixed:
; CHECK: add [[P5ADDR:r[0-9]+]], sp, #4
; CHECK: ldrh [[P5:r[0-9]+]], {{.*}}[[P5ADDR]]
; CHECK: add r0, r1, [[P5]]
; CHECK: bx lr
entry:
  %sum = add i16 %p1, %p5
  ret i16 %sum
}

define i16 @test_stack_args_zeroext(i32 %p0, i16 %p1, i8 %p2, i1 %p3, i16 zeroext %p4) {
; CHECK-LABEL: test_stack_args_zeroext:
; CHECK: mov [[P4ADDR:r[0-9]+]], sp
; CHECK: ldr [[P4:r[0-9]+]], {{.*}}[[P4ADDR]]
; CHECK: add r0, r1, [[P4]]
; CHECK: bx lr
entry:
  %sum = add i16 %p1, %p4
  ret i16 %sum
}

define i8 @test_stack_args_signext(i32 %p0, i16 %p1, i8 %p2, i1 %p3, i8 signext %p4) {
; CHECK-LABEL: test_stack_args_signext:
; CHECK: mov [[P4ADDR:r[0-9]+]], sp
; CHECK: ldr [[P4:r[0-9]+]], {{.*}}[[P4ADDR]]
; CHECK: add r0, r2, [[P4]]
; CHECK: bx lr
entry:
  %sum = add i8 %p2, %p4
  ret i8 %sum
}
