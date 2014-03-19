; RUN: llc < %s -march=r600 -mcpu=SI | FileCheck -check-prefix=SI -check-prefix=FUNC %s
; RUN: llc < %s -march=r600 -mcpu=cypress | FileCheck -check-prefix=EG -check-prefix=FUNC %s

; FUNC-LABEL: @sext_in_reg_i1_i32
; SI: S_LOAD_DWORD [[ARG:s[0-9]+]],
; SI: V_BFE_I32 [[EXTRACT:v[0-9]+]], [[ARG]], 0, 1
; SI: BUFFER_STORE_DWORD [[EXTRACT]],

; EG: BFE_INT
define void @sext_in_reg_i1_i32(i32 addrspace(1)* %out, i32 %in) {
  %shl = shl i32 %in, 31
  %sext = ashr i32 %shl, 31
  store i32 %sext, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: @sext_in_reg_i8_to_i32
; SI: S_ADD_I32 [[VAL:s[0-9]+]],
; SI: V_BFE_I32 [[EXTRACT:v[0-9]+]], [[VAL]], 0, 8
; SI: BUFFER_STORE_DWORD [[EXTRACT]],

; EG: BFE_INT
define void @sext_in_reg_i8_to_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) nounwind {
  %c = add i32 %a, %b ; add to prevent folding into extload
  %shl = shl i32 %c, 24
  %ashr = ashr i32 %shl, 24
  store i32 %ashr, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: @sext_in_reg_i16_to_i32
; SI: S_ADD_I32 [[VAL:s[0-9]+]],
; SI: V_BFE_I32 [[EXTRACT:v[0-9]+]], [[VAL]], 0, 16
; SI: BUFFER_STORE_DWORD [[EXTRACT]],

; EG: BFE_INT
define void @sext_in_reg_i16_to_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) nounwind {
  %c = add i32 %a, %b ; add to prevent folding into extload
  %shl = shl i32 %c, 16
  %ashr = ashr i32 %shl, 16
  store i32 %ashr, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: @sext_in_reg_i8_to_v1i32
; SI: S_ADD_I32 [[VAL:s[0-9]+]],
; SI: V_BFE_I32 [[EXTRACT:v[0-9]+]], [[VAL]], 0, 8
; SI: BUFFER_STORE_DWORD [[EXTRACT]],

; EG: BFE_INT
define void @sext_in_reg_i8_to_v1i32(<1 x i32> addrspace(1)* %out, <1 x i32> %a, <1 x i32> %b) nounwind {
  %c = add <1 x i32> %a, %b ; add to prevent folding into extload
  %shl = shl <1 x i32> %c, <i32 24>
  %ashr = ashr <1 x i32> %shl, <i32 24>
  store <1 x i32> %ashr, <1 x i32> addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: @sext_in_reg_i8_to_i64
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; SI: V_ASHRREV_I32_e32 {{v[0-9]+}}, 31,
; SI: BUFFER_STORE_DWORD

; EG: BFE_INT
; EG: ASHR
define void @sext_in_reg_i8_to_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) nounwind {
  %c = add i64 %a, %b
  %shl = shl i64 %c, 56
  %ashr = ashr i64 %shl, 56
  store i64 %ashr, i64 addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: @sext_in_reg_i16_to_i64
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 16
; SI: V_ASHRREV_I32_e32 {{v[0-9]+}}, 31,
; SI: BUFFER_STORE_DWORD

; EG: BFE_INT
; EG: ASHR
define void @sext_in_reg_i16_to_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) nounwind {
  %c = add i64 %a, %b
  %shl = shl i64 %c, 48
  %ashr = ashr i64 %shl, 48
  store i64 %ashr, i64 addrspace(1)* %out, align 8
  ret void
}

; This is broken on Evergreen for some reason related to the <1 x i64> kernel arguments.
; XFUNC-LABEL: @sext_in_reg_i8_to_v1i64
; XSI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; XSI: V_ASHRREV_I32_e32 {{v[0-9]+}}, 31,
; XSI: BUFFER_STORE_DWORD
; XEG: BFE_INT
; XEG: ASHR
; define void @sext_in_reg_i8_to_v1i64(<1 x i64> addrspace(1)* %out, <1 x i64> %a, <1 x i64> %b) nounwind {
;   %c = add <1 x i64> %a, %b
;   %shl = shl <1 x i64> %c, <i64 56>
;   %ashr = ashr <1 x i64> %shl, <i64 56>
;   store <1 x i64> %ashr, <1 x i64> addrspace(1)* %out, align 8
;   ret void
; }

; FUNC-LABEL: @sext_in_reg_i1_in_i32_other_amount
; SI-NOT: BFE
; SI: S_LSHL_B32 [[REG:s[0-9]+]], {{s[0-9]+}}, 6
; SI: S_ASHR_I32 {{s[0-9]+}}, [[REG]], 7
; EG-NOT: BFE
define void @sext_in_reg_i1_in_i32_other_amount(i32 addrspace(1)* %out, i32 %a, i32 %b) nounwind {
  %c = add i32 %a, %b
  %x = shl i32 %c, 6
  %y = ashr i32 %x, 7
  store i32 %y, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: @sext_in_reg_v2i1_in_v2i32_other_amount
; SI: S_LSHL_B32 [[REG0:s[0-9]+]], {{s[0-9]}}, 6
; SI: S_ASHR_I32 {{s[0-9]+}}, [[REG0]], 7
; SI: S_LSHL_B32 [[REG1:s[0-9]+]], {{s[0-9]}}, 6
; SI: S_ASHR_I32 {{s[0-9]+}}, [[REG1]], 7
; EG-NOT: BFE
define void @sext_in_reg_v2i1_in_v2i32_other_amount(<2 x i32> addrspace(1)* %out, <2 x i32> %a, <2 x i32> %b) nounwind {
  %c = add <2 x i32> %a, %b
  %x = shl <2 x i32> %c, <i32 6, i32 6>
  %y = ashr <2 x i32> %x, <i32 7, i32 7>
  store <2 x i32> %y, <2 x i32> addrspace(1)* %out, align 2
  ret void
}


; FUNC-LABEL: @sext_in_reg_v2i1_to_v2i32
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 1
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 1
; SI: BUFFER_STORE_DWORDX2
; EG: BFE
; EG: BFE
define void @sext_in_reg_v2i1_to_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> %a, <2 x i32> %b) nounwind {
  %c = add <2 x i32> %a, %b ; add to prevent folding into extload
  %shl = shl <2 x i32> %c, <i32 31, i32 31>
  %ashr = ashr <2 x i32> %shl, <i32 31, i32 31>
  store <2 x i32> %ashr, <2 x i32> addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: @sext_in_reg_v4i1_to_v4i32
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 1
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 1
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 1
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 1
; SI: BUFFER_STORE_DWORDX4

; EG: BFE
; EG: BFE
; EG: BFE
; EG: BFE
define void @sext_in_reg_v4i1_to_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> %a, <4 x i32> %b) nounwind {
  %c = add <4 x i32> %a, %b ; add to prevent folding into extload
  %shl = shl <4 x i32> %c, <i32 31, i32 31, i32 31, i32 31>
  %ashr = ashr <4 x i32> %shl, <i32 31, i32 31, i32 31, i32 31>
  store <4 x i32> %ashr, <4 x i32> addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: @sext_in_reg_v2i8_to_v2i32
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; SI: BUFFER_STORE_DWORDX2

; EG: BFE
; EG: BFE
define void @sext_in_reg_v2i8_to_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> %a, <2 x i32> %b) nounwind {
  %c = add <2 x i32> %a, %b ; add to prevent folding into extload
  %shl = shl <2 x i32> %c, <i32 24, i32 24>
  %ashr = ashr <2 x i32> %shl, <i32 24, i32 24>
  store <2 x i32> %ashr, <2 x i32> addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: @sext_in_reg_v4i8_to_v4i32
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; SI: BUFFER_STORE_DWORDX4

; EG: BFE
; EG: BFE
; EG: BFE
; EG: BFE
define void @sext_in_reg_v4i8_to_v4i32(<4 x i32> addrspace(1)* %out, <4 x i32> %a, <4 x i32> %b) nounwind {
  %c = add <4 x i32> %a, %b ; add to prevent folding into extload
  %shl = shl <4 x i32> %c, <i32 24, i32 24, i32 24, i32 24>
  %ashr = ashr <4 x i32> %shl, <i32 24, i32 24, i32 24, i32 24>
  store <4 x i32> %ashr, <4 x i32> addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: @sext_in_reg_v2i16_to_v2i32
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; SI: V_BFE_I32 {{v[0-9]+}}, {{s[0-9]+}}, 0, 8
; SI: BUFFER_STORE_DWORDX2

; EG: BFE
; EG: BFE
define void @sext_in_reg_v2i16_to_v2i32(<2 x i32> addrspace(1)* %out, <2 x i32> %a, <2 x i32> %b) nounwind {
  %c = add <2 x i32> %a, %b ; add to prevent folding into extload
  %shl = shl <2 x i32> %c, <i32 24, i32 24>
  %ashr = ashr <2 x i32> %shl, <i32 24, i32 24>
  store <2 x i32> %ashr, <2 x i32> addrspace(1)* %out, align 8
  ret void
}

; FUNC-LABEL: @testcase
define void @testcase(i8 addrspace(1)* %out, i8 %a) nounwind {
  %and_a_1 = and i8 %a, 1
  %cmp_eq = icmp eq i8 %and_a_1, 0
  %cmp_slt = icmp slt i8 %a, 0
  %sel0 = select i1 %cmp_slt, i8 0, i8 %a
  %sel1 = select i1 %cmp_eq, i8 0, i8 %a
  %xor = xor i8 %sel0, %sel1
  store i8 %xor, i8 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: @testcase_3
define void @testcase_3(i8 addrspace(1)* %out, i8 %a) nounwind {
  %and_a_1 = and i8 %a, 1
  %cmp_eq = icmp eq i8 %and_a_1, 0
  %cmp_slt = icmp slt i8 %a, 0
  %sel0 = select i1 %cmp_slt, i8 0, i8 %a
  %sel1 = select i1 %cmp_eq, i8 0, i8 %a
  %xor = xor i8 %sel0, %sel1
  store i8 %xor, i8 addrspace(1)* %out
  ret void
}
