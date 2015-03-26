// RUN: llvm-mc -triple x86_64-pc-linux-gnu %s -o - | FileCheck %s
// RUN: llvm-mc -triple x86_64-pc-linux-gnu %s -filetype=obj -o - | llvm-readobj -t | FileCheck %s --check-prefix=OBJ

	.section	.text,"ax",@progbits,unique
        .globl	f
f:
        nop

	.section	.text,"ax",@progbits,unique
        .globl	g
g:
        nop

// test that f and g are in different sections.

// CHECK: .section	.text,"ax",@progbits,unique
// CHECK: f:

// CHECK: .section	.text,"ax",@progbits,unique
// CHECK: g:

// OBJ: Symbol {
// OBJ:   Name:    f
// OBJ:   Value:   0x0
// OBJ:   Size:    0
// OBJ:   Binding: Global
// OBJ:   Type:    None
// OBJ:   Other:   0
// OBJ:   Section: .text (0x4)
// OBJ: }
// OBJ: Symbol {
// OBJ:   Name:    g
// OBJ:   Value:   0x0
// OBJ:   Size:    0
// OBJ:   Binding: Global
// OBJ:   Type:    None
// OBJ:   Other:   0
// OBJ:   Section: .text (0x5)
// OBJ: }
