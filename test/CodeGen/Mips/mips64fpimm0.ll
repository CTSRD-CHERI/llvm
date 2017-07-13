; RUN: llc  < %s -march=mips64el -mcpu=mips4 -mabi=n64 | FileCheck %s
; RUN: llc  < %s -march=mips64el -mcpu=mips64 -mabi=n64 | FileCheck %s

define double @foo1() nounwind readnone {
entry:
; CHECK: dmtc1 $zero
  ret double 0.000000e+00
}
