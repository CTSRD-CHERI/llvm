; RUN: llc -O0 %s -mtriple=x86_64-apple-darwin -filetype=obj -o %t
; RUN: llvm-dwarfdump %t | FileCheck %s
; RUN: llc -O0 %s -mtriple=x86_64-apple-darwin -filetype=obj -o %t -dwarf-version=3
; RUN: llvm-dwarfdump %t | FileCheck %s -check-prefix=DWARF3
; RUN: llc < %s -O0 -mtriple=x86_64-apple-macosx10.7 | FileCheck %s -check-prefix=ASM

; rdar://13067005
; CHECK: .debug_info contents:
; CHECK: DW_TAG_compile_unit
; CHECK: DW_AT_stmt_list [DW_FORM_sec_offset]   (0x00000000)
; CHECK: DW_AT_low_pc [DW_FORM_addr]            (0x0000000000000000)
; CHECK: DW_AT_high_pc [DW_FORM_data4]          (0x00000010)
; CHECK: DW_TAG_subprogram
; CHECK: DW_AT_low_pc [DW_FORM_addr]            (0x0000000000000000)
; CHECK: DW_AT_high_pc [DW_FORM_data4]          (0x00000010)

; CHECK: DW_TAG_compile_unit
; CHECK: DW_AT_stmt_list [DW_FORM_sec_offset]   (0x0000003c)
; CHECK: DW_AT_low_pc [DW_FORM_addr]            (0x0000000000000010)
; CHECK: DW_AT_high_pc [DW_FORM_data4]          (0x00000009)
; CHECK: DW_TAG_subprogram
; CHECK: DW_AT_low_pc [DW_FORM_addr]            (0x0000000000000010)
; CHECK: DW_AT_high_pc [DW_FORM_data4]          (0x00000009)


; CHECK: .debug_line contents:
; CHECK-NEXT: Line table prologue:
; CHECK-NEXT: total_length: 0x00000038
; CHECK: file_names[  1]    0 0x00000000 0x00000000 simple.c
; CHECK: Line table prologue:
; CHECK-NEXT: total_length: 0x00000039
; CHECK: file_names[  1]    0 0x00000000 0x00000000 simple2.c
; CHECK-NOT: file_names

; DWARF3: .debug_info contents:
; DWARF3: DW_TAG_compile_unit
; DWARF3: DW_AT_stmt_list [DW_FORM_data4]    (0x00000000)

; DWARF3: DW_TAG_compile_unit
; DWARF3: DW_AT_stmt_list [DW_FORM_data4]   (0x0000003c)


; DWARF3: .debug_line contents:
; DWARF3-NEXT: Line table prologue:
; DWARF3-NEXT: total_length: 0x00000038
; DWARF3: file_names[  1]    0 0x00000000 0x00000000 simple.c
; DWARF3: Line table prologue:
; DWARF3-NEXT: total_length: 0x00000039
; DWARF3: file_names[  1]    0 0x00000000 0x00000000 simple2.c
; DWARF3-NOT: file_names

; PR15408
; ASM: Lcu_begin0:
; ASM: Lset3 = Lline_table_start0-Lsection_line ## DW_AT_stmt_list
; ASM-NEXT: .long   Lset3
; ASM: Lcu_begin1:
; ASM: Lset13 = Lline_table_start0-Lsection_line ## DW_AT_stmt_list
; ASM-NEXT: .long   Lset13
define i32 @test(i32 %a) nounwind uwtable ssp {
entry:
  %a.addr = alloca i32, align 4
  store i32 %a, i32* %a.addr, align 4
  call void @llvm.dbg.declare(metadata i32* %a.addr, metadata !15, metadata !MDExpression()), !dbg !16
  %0 = load i32, i32* %a.addr, align 4, !dbg !17
  %call = call i32 @fn(i32 %0), !dbg !17
  ret i32 %call, !dbg !17
}

declare void @llvm.dbg.declare(metadata, metadata, metadata) nounwind readnone

define i32 @fn(i32 %a) nounwind uwtable ssp {
entry:
  %a.addr = alloca i32, align 4
  store i32 %a, i32* %a.addr, align 4
  call void @llvm.dbg.declare(metadata i32* %a.addr, metadata !19, metadata !MDExpression()), !dbg !20
  %0 = load i32, i32* %a.addr, align 4, !dbg !21
  ret i32 %0, !dbg !21
}

!llvm.dbg.cu = !{!0, !10}
!llvm.module.flags = !{!25}
!0 = !MDCompileUnit(language: DW_LANG_C99, producer: "clang version 3.3", isOptimized: false, emissionKind: 1, file: !23, enums: !1, retainedTypes: !1, subprograms: !3, globals: !1, imports:  !1)
!1 = !{}
!3 = !{!5}
!5 = !MDSubprogram(name: "test", line: 2, isLocal: false, isDefinition: true, virtualIndex: 6, flags: DIFlagPrototyped, isOptimized: false, scopeLine: 3, file: !23, scope: !6, type: !7, function: i32 (i32)* @test, variables: !1)
!6 = !MDFile(filename: "simple.c", directory: "/private/tmp")
!7 = !MDSubroutineType(types: !8)
!8 = !{!9, !9}
!9 = !MDBasicType(tag: DW_TAG_base_type, name: "int", size: 32, align: 32, encoding: DW_ATE_signed)
!10 = !MDCompileUnit(language: DW_LANG_C99, producer: "clang version 3.3 (trunk 172862)", isOptimized: false, emissionKind: 1, file: !24, enums: !1, retainedTypes: !1, subprograms: !11, globals: !1, imports:  !1)
!11 = !{!13}
!13 = !MDSubprogram(name: "fn", line: 1, isLocal: false, isDefinition: true, virtualIndex: 6, flags: DIFlagPrototyped, isOptimized: false, scopeLine: 1, file: !24, scope: !14, type: !7, function: i32 (i32)* @fn, variables: !1)
!14 = !MDFile(filename: "simple2.c", directory: "/private/tmp")
!15 = !MDLocalVariable(tag: DW_TAG_arg_variable, name: "a", line: 2, arg: 1, scope: !5, file: !6, type: !9)
!16 = !MDLocation(line: 2, scope: !5)
!17 = !MDLocation(line: 4, scope: !18)
!18 = distinct !MDLexicalBlock(line: 3, column: 0, file: !23, scope: !5)
!19 = !MDLocalVariable(tag: DW_TAG_arg_variable, name: "a", line: 1, arg: 1, scope: !13, file: !14, type: !9)
!20 = !MDLocation(line: 1, scope: !13)
!21 = !MDLocation(line: 2, scope: !22)
!22 = distinct !MDLexicalBlock(line: 1, column: 0, file: !24, scope: !13)
!23 = !MDFile(filename: "simple.c", directory: "/private/tmp")
!24 = !MDFile(filename: "simple2.c", directory: "/private/tmp")
!25 = !{i32 1, !"Debug Info Version", i32 3}
