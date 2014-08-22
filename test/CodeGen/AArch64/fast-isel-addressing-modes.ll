; RUN: llc -mtriple=aarch64-apple-darwin                             < %s | FileCheck %s --check-prefix=CHECK --check-prefix=SDAG
; RUN: llc -mtriple=aarch64-apple-darwin -fast-isel -fast-isel-abort < %s | FileCheck %s --check-prefix=CHECK --check-prefix=FAST

; Load / Store Base Register only
define zeroext i1 @load_breg_i1(i1* %a) {
; CHECK-LABEL: load_breg_i1
; CHECK:       ldrb {{w[0-9]+}}, [x0]
  %1 = load i1* %a
  ret i1 %1
}

define zeroext i8 @load_breg_i8(i8* %a) {
; CHECK-LABEL: load_breg_i8
; CHECK:       ldrb {{w[0-9]+}}, [x0]
  %1 = load i8* %a
  ret i8 %1
}

define zeroext i16 @load_breg_i16(i16* %a) {
; CHECK-LABEL: load_breg_i16
; CHECK:       ldrh {{w[0-9]+}}, [x0]
  %1 = load i16* %a
  ret i16 %1
}

define i32 @load_breg_i32(i32* %a) {
; CHECK-LABEL: load_breg_i32
; CHECK:       ldr {{w[0-9]+}}, [x0]
  %1 = load i32* %a
  ret i32 %1
}

define i64 @load_breg_i64(i64* %a) {
; CHECK-LABEL: load_breg_i64
; CHECK:       ldr {{x[0-9]+}}, [x0]
  %1 = load i64* %a
  ret i64 %1
}

define float @load_breg_f32(float* %a) {
; CHECK-LABEL: load_breg_f32
; CHECK:       ldr {{s[0-9]+}}, [x0]
  %1 = load float* %a
  ret float %1
}

define double @load_breg_f64(double* %a) {
; CHECK-LABEL: load_breg_f64
; CHECK:       ldr {{d[0-9]+}}, [x0]
  %1 = load double* %a
  ret double %1
}

define void @store_breg_i1(i1* %a) {
; CHECK-LABEL: store_breg_i1
; CHECK:       strb {{wzr|w[0-9]+}}, [x0]
  store i1 0, i1* %a
  ret void
}

define void @store_breg_i8(i8* %a) {
; CHECK-LABEL: store_breg_i8
; CHECK:       strb wzr, [x0]
  store i8 0, i8* %a
  ret void
}

define void @store_breg_i16(i16* %a) {
; CHECK-LABEL: store_breg_i16
; CHECK:       strh wzr, [x0]
  store i16 0, i16* %a
  ret void
}

define void @store_breg_i32(i32* %a) {
; CHECK-LABEL: store_breg_i32
; CHECK:       str wzr, [x0]
  store i32 0, i32* %a
  ret void
}

define void @store_breg_i64(i64* %a) {
; CHECK-LABEL: store_breg_i64
; CHECK:       str xzr, [x0]
  store i64 0, i64* %a
  ret void
}

define void @store_breg_f32(float* %a) {
; CHECK-LABEL: store_breg_f32
; CHECK:       str {{wzr|s[0-9]+}}, [x0]
  store float 0.0, float* %a
  ret void
}

define void @store_breg_f64(double* %a) {
; CHECK-LABEL: store_breg_f64
; CHECK:       str {{xzr|d[0-9]+}}, [x0]
  store double 0.0, double* %a
  ret void
}

; Load / Store Base Register + Immediate Offset
; Max supported negative offset
define i32 @load_breg_immoff_1(i64 %a) {
; CHECK-LABEL: load_breg_immoff_1
; CHECK:       ldur {{w[0-9]+}}, [x0, #-256]
  %1 = add i64 %a, -256
  %2 = inttoptr i64 %1 to i32*
  %3 = load i32* %2
  ret i32 %3
}

; Min not-supported negative offset
define i32 @load_breg_immoff_2(i64 %a) {
; SDAG-LABEL: load_breg_immoff_2
; SDAG:       sub [[REG:x[0-9]+]], x0, #257
; SDAG-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]]{{\]}}
; FAST-LABEL: load_breg_immoff_2
; FAST:       add [[REG:x[0-9]+]], x0, {{x[0-9]+}}
; FAST-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]]{{\]}}
  %1 = add i64 %a, -257
  %2 = inttoptr i64 %1 to i32*
  %3 = load i32* %2
  ret i32 %3
}

; Max supported unscaled offset
define i32 @load_breg_immoff_3(i64 %a) {
; CHECK-LABEL: load_breg_immoff_3
; CHECK:       ldur {{w[0-9]+}}, [x0, #255]
  %1 = add i64 %a, 255
  %2 = inttoptr i64 %1 to i32*
  %3 = load i32* %2
  ret i32 %3
}

; Min un-supported unscaled offset
define i32 @load_breg_immoff_4(i64 %a) {
; SDAG-LABEL: load_breg_immoff_4
; SDAG:       add [[REG:x[0-9]+]], x0, #257
; SDAG-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]]{{\]}}
; FAST-LABEL: load_breg_immoff_4
; FAST:       add [[REG:x[0-9]+]], x0, {{x[0-9]+}}
; FAST-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]]{{\]}}
  %1 = add i64 %a, 257
  %2 = inttoptr i64 %1 to i32*
  %3 = load i32* %2
  ret i32 %3
}

; Max supported scaled offset
define i32 @load_breg_immoff_5(i64 %a) {
; CHECK-LABEL: load_breg_immoff_5
; CHECK:       ldr {{w[0-9]+}}, [x0, #16380]
  %1 = add i64 %a, 16380
  %2 = inttoptr i64 %1 to i32*
  %3 = load i32* %2
  ret i32 %3
}

; Min un-supported scaled offset
define i32 @load_breg_immoff_6(i64 %a) {
; SDAG-LABEL: load_breg_immoff_6
; SDAG:       add [[REG:x[0-9]+]], x0, #4, lsl #12
; SDAG-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]]{{\]}}
; FAST-LABEL: load_breg_immoff_6
; FAST:       add [[REG:x[0-9]+]], x0, {{x[0-9]+}}
; FAST-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]]{{\]}}
  %1 = add i64 %a, 16384
  %2 = inttoptr i64 %1 to i32*
  %3 = load i32* %2
  ret i32 %3
}

; Max supported negative offset
define void @store_breg_immoff_1(i64 %a) {
; CHECK-LABEL: store_breg_immoff_1
; CHECK:       stur wzr, [x0, #-256]
  %1 = add i64 %a, -256
  %2 = inttoptr i64 %1 to i32*
  store i32 0, i32* %2
  ret void
}

; Min not-supported negative offset
define void @store_breg_immoff_2(i64 %a) {
; SDAG-LABEL: store_breg_immoff_2
; SDAG:       sub [[REG:x[0-9]+]], x0, #257
; SDAG-NEXT:  str wzr, {{\[}}[[REG]]{{\]}}
; FAST-LABEL: store_breg_immoff_2
; FAST:       add [[REG:x[0-9]+]], x0, {{x[0-9]+}}
; FAST-NEXT:  str wzr, {{\[}}[[REG]]{{\]}}
  %1 = add i64 %a, -257
  %2 = inttoptr i64 %1 to i32*
  store i32 0, i32* %2
  ret void
}

; Max supported unscaled offset
define void @store_breg_immoff_3(i64 %a) {
; CHECK-LABEL: store_breg_immoff_3
; CHECK:       stur wzr, [x0, #255]
  %1 = add i64 %a, 255
  %2 = inttoptr i64 %1 to i32*
  store i32 0, i32* %2
  ret void
}

; Min un-supported unscaled offset
define void @store_breg_immoff_4(i64 %a) {
; SDAG-LABEL: store_breg_immoff_4
; SDAG:       add [[REG:x[0-9]+]], x0, #257
; SDAG-NEXT:  str wzr, {{\[}}[[REG]]{{\]}}
; FAST-LABEL: store_breg_immoff_4
; FAST:       add [[REG:x[0-9]+]], x0, {{x[0-9]+}}
; FAST-NEXT:  str wzr, {{\[}}[[REG]]{{\]}}
  %1 = add i64 %a, 257
  %2 = inttoptr i64 %1 to i32*
  store i32 0, i32* %2
  ret void
}

; Max supported scaled offset
define void @store_breg_immoff_5(i64 %a) {
; CHECK-LABEL: store_breg_immoff_5
; CHECK:       str wzr, [x0, #16380]
  %1 = add i64 %a, 16380
  %2 = inttoptr i64 %1 to i32*
  store i32 0, i32* %2
  ret void
}

; Min un-supported scaled offset
define void @store_breg_immoff_6(i64 %a) {
; SDAG-LABEL: store_breg_immoff_6
; SDAG:       add [[REG:x[0-9]+]], x0, #4, lsl #12
; SDAG-NEXT:  str wzr, {{\[}}[[REG]]{{\]}}
; FAST-LABEL: store_breg_immoff_6
; FAST:       add [[REG:x[0-9]+]], x0, {{x[0-9]+}}
; FAST-NEXT:  str wzr, {{\[}}[[REG]]{{\]}}
  %1 = add i64 %a, 16384
  %2 = inttoptr i64 %1 to i32*
  store i32 0, i32* %2
  ret void
}

define i64 @load_breg_immoff_7(i64 %a) {
; CHECK-LABEL: load_breg_immoff_7
; CHECK:       ldr {{x[0-9]+}}, [x0, #48]
  %1 = add i64 %a, 48
  %2 = inttoptr i64 %1 to i64*
  %3 = load i64* %2
  ret i64 %3
}

; Flip add operands
define i64 @load_breg_immoff_8(i64 %a) {
; CHECK-LABEL: load_breg_immoff_8
; CHECK:       ldr {{x[0-9]+}}, [x0, #48]
  %1 = add i64 48, %a
  %2 = inttoptr i64 %1 to i64*
  %3 = load i64* %2
  ret i64 %3
}

; Load Base Register + Register Offset
define i64 @load_breg_offreg_1(i64 %a, i64 %b) {
; CHECK-LABEL: load_breg_offreg_1
; CHECK:       ldr {{x[0-9]+}}, [x0, x1]
  %1 = add i64 %a, %b
  %2 = inttoptr i64 %1 to i64*
  %3 = load i64* %2
  ret i64 %3
}

; Flip add operands
define i64 @load_breg_offreg_2(i64 %a, i64 %b) {
; CHECK-LABEL: load_breg_offreg_2
; CHECK:       ldr {{x[0-9]+}}, [x1, x0]
  %1 = add i64 %b, %a
  %2 = inttoptr i64 %1 to i64*
  %3 = load i64* %2
  ret i64 %3
}

; Load Base Register + Register Offset + Immediate Offset
define i64 @load_breg_offreg_immoff_1(i64 %a, i64 %b) {
; CHECK-LABEL: load_breg_offreg_immoff_1
; CHECK:       add [[REG:x[0-9]+]], x0, x1
; CHECK-NEXT:  ldr x0, {{\[}}[[REG]], #48{{\]}}
  %1 = add i64 %a, %b
  %2 = add i64 %1, 48
  %3 = inttoptr i64 %2 to i64*
  %4 = load i64* %3
  ret i64 %4
}

define i64 @load_breg_offreg_immoff_2(i64 %a, i64 %b) {
; SDAG-LABEL: load_breg_offreg_immoff_2
; SDAG:       add [[REG1:x[0-9]+]], x0, x1
; SDAG-NEXT:  add [[REG2:x[0-9]+]], [[REG1]], #15, lsl #12
; SDAG-NEXT:  ldr x0, {{\[}}[[REG2]]{{\]}}
; FAST-LABEL: load_breg_offreg_immoff_2
; FAST:       add [[REG:x[0-9]+]], x0, {{x[0-9]+}}
; FAST-NEXT:  ldr x0, {{\[}}[[REG]], x1{{\]}}
  %1 = add i64 %a, %b
  %2 = add i64 %1, 61440
  %3 = inttoptr i64 %2 to i64*
  %4 = load i64* %3
  ret i64 %4
}

; Load Base Register + Scaled Register Offset
define i32 @load_breg_shift_offreg_1(i64 %a, i64 %b) {
; CHECK-LABEL: load_breg_shift_offreg_1
; CHECK:       ldr {{w[0-9]+}}, [x1, x0, lsl #2]
  %1 = shl i64 %a, 2
  %2 = add i64 %1, %b
  %3 = inttoptr i64 %2 to i32*
  %4 = load i32* %3
  ret i32 %4
}

define i32 @load_breg_shift_offreg_2(i64 %a, i64 %b) {
; CHECK-LABEL: load_breg_shift_offreg_2
; CHECK:       ldr {{w[0-9]+}}, [x1, x0, lsl #2]
  %1 = shl i64 %a, 2
  %2 = add i64 %b, %1
  %3 = inttoptr i64 %2 to i32*
  %4 = load i32* %3
  ret i32 %4
}

define i32 @load_breg_shift_offreg_3(i64 %a, i64 %b) {
; SDAG-LABEL: load_breg_shift_offreg_3
; SDAG:       lsl [[REG:x[0-9]+]], x0, #2
; SDAG-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]], x1, lsl #2{{\]}}
; FAST-LABEL: load_breg_shift_offreg_3
; FAST:       lsl [[REG:x[0-9]+]], x1, {{x[0-9]+}}
; FAST-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]], x0, lsl #2{{\]}}
  %1 = shl i64 %a, 2
  %2 = shl i64 %b, 2
  %3 = add i64 %1, %2
  %4 = inttoptr i64 %3 to i32*
  %5 = load i32* %4
  ret i32 %5
}

define i32 @load_breg_shift_offreg_4(i64 %a, i64 %b) {
; SDAG-LABEL: load_breg_shift_offreg_4
; SDAG:       lsl [[REG:x[0-9]+]], x1, #2
; SDAG-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]], x0, lsl #2{{\]}}
; FAST-LABEL: load_breg_shift_offreg_4
; FAST:       lsl [[REG:x[0-9]+]], x0, {{x[0-9]+}}
; FAST-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]], x1, lsl #2{{\]}}
  %1 = shl i64 %a, 2
  %2 = shl i64 %b, 2
  %3 = add i64 %2, %1
  %4 = inttoptr i64 %3 to i32*
  %5 = load i32* %4
  ret i32 %5
}

define i32 @load_breg_shift_offreg_5(i64 %a, i64 %b) {
; SDAG-LABEL: load_breg_shift_offreg_5
; SDAG:       lsl [[REG:x[0-9]+]], x1, #3
; SDAG-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]], x0, lsl #2{{\]}}
; FAST-LABEL: load_breg_shift_offreg_5
; FAST:       lsl [[REG:x[0-9]+]], x1, {{x[0-9]+}}
; FAST-NEXT:  ldr {{w[0-9]+}}, {{\[}}[[REG]], x0, lsl #2{{\]}}
  %1 = shl i64 %a, 2
  %2 = shl i64 %b, 3
  %3 = add i64 %1, %2
  %4 = inttoptr i64 %3 to i32*
  %5 = load i32* %4
  ret i32 %5
}


; Load Base Register + Scaled Register Offset + Sign/Zero extension
define i32 @load_breg_zext_shift_offreg_1(i32 %a, i64 %b) {
; CHECK-LABEL: load_breg_zext_shift_offreg_1
; CHECK:       ldr {{w[0-9]+}}, [x1, w0, uxtw #2]
  %1 = zext i32 %a to i64
  %2 = shl i64 %1, 2
  %3 = add i64 %2, %b
  %4 = inttoptr i64 %3 to i32*
  %5 = load i32* %4
  ret i32 %5
}

define i32 @load_breg_zext_shift_offreg_2(i32 %a, i64 %b) {
; CHECK-LABEL: load_breg_zext_shift_offreg_2
; CHECK:       ldr {{w[0-9]+}}, [x1, w0, uxtw #2]
  %1 = zext i32 %a to i64
  %2 = shl i64 %1, 2
  %3 = add i64 %b, %2
  %4 = inttoptr i64 %3 to i32*
  %5 = load i32* %4
  ret i32 %5
}

define i32 @load_breg_sext_shift_offreg_1(i32 %a, i64 %b) {
; CHECK-LABEL: load_breg_sext_shift_offreg_1
; CHECK:       ldr {{w[0-9]+}}, [x1, w0, sxtw #2]
  %1 = sext i32 %a to i64
  %2 = shl i64 %1, 2
  %3 = add i64 %2, %b
  %4 = inttoptr i64 %3 to i32*
  %5 = load i32* %4
  ret i32 %5
}

define i32 @load_breg_sext_shift_offreg_2(i32 %a, i64 %b) {
; CHECK-LABEL: load_breg_sext_shift_offreg_2
; CHECK:       ldr {{w[0-9]+}}, [x1, w0, sxtw #2]
  %1 = sext i32 %a to i64
  %2 = shl i64 %1, 2
  %3 = add i64 %b, %2
  %4 = inttoptr i64 %3 to i32*
  %5 = load i32* %4
  ret i32 %5
}

