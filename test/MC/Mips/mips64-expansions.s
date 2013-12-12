# RUN: llvm-mc %s -triple=mips64el-unknown-linux -show-encoding -mcpu=mips64r2 | FileCheck %s
#
# XFAIL:
# The GNU assembler implements 'dli' and 'dla' variants on 'li' and 'la'
# supporting double-word lengths.  Test that not only are they present, bu
# that they also seem to handle 64-bit values.
#
# XXXRW: Does using powers of ten make me a bad person?
#
# CHECK-DLA: lui	$12, %highest(function)  # encoding: [A,A,0x0c,0x3c]
# CHECK-DLA:   fixup A - offset: 0, value: function@HIGHEST, kind: fixup_Mips_HIGHEST
# CHECK-DLA: lui	$1, %hi(function)        # encoding: [A,A,0x01,0x3c]
# CHECK-DLA:   fixup A - offset: 0, value: function@ABS_HI, kind: fixup_Mips_HI16
# CHECK-DLA: daddiu	$12, $12, %higher(function) # encoding: [A,A,0x8c,0x65]
# CHECK-DLA:   fixup A - offset: 0, value: function@HIGHER, kind: fixup_Mips_HIGHER
# CHECK-DLA: daddiu	$1, $1, %lo(function)    # encoding: [A,A,0x21,0x64]
# CHECK-DLA:   fixup A - offset: 0, value: function@ABS_LO, kind: fixup_Mips_LO16
# CHECK-DLA: dsll32	$12, $12, 0             # encoding: [0x3c,0x60,0x0c,0x00]
# CHECK-DLA: daddu	$12, $12, $1            # encoding: [0x2d,0x60,0x81,0x01]
# CHECK-DLA: lui	$12, %highest(symbol)   # encoding: [A,A,0x0c,0x3c]
# CHECK-DLA:  fixup A - offset: 0, value: symbol@HIGHEST, kind: fixup_Mips_HIGHEST
# CHECK-DLA: daddiu	$12, $12, %higher(symbol) # encoding: [A,A,0x8c,0x65]
# CHECK-DLA:  fixup A - offset: 0, value: symbol@HIGHER, kind: fixup_Mips_HIGHER
# CHECK-DLA: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK-DLA: daddiu	$12, $12, %hi(symbol)   # encoding: [A,A,0x8c,0x65]
# CHECK-DLA:  fixup A - offset: 0, value: symbol@ABS_HI, kind: fixup_Mips_HI16
# CHECK-DLA: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK-DLA: daddiu	$12, $12, %lo(symbol)   # encoding: [A,A,0x8c,0x65]
# CHECK-DLA:  fixup A - offset: 0, value: symbol@ABS_LO, kind: fixup_Mips_LO16


# CHECK: ori	$12, $zero, 1           # encoding: [0x01,0x00,0x0c,0x34]
# CHECK: ori	$12, $zero, 10          # encoding: [0x0a,0x00,0x0c,0x34]
# CHECK: ori	$12, $zero, 100         # encoding: [0x64,0x00,0x0c,0x34]
# CHECK: ori	$12, $zero, 1000        # encoding: [0xe8,0x03,0x0c,0x34]
# CHECK: ori	$12, $zero, 10000       # encoding: [0x10,0x27,0x0c,0x34]
# CHECK: lui	$12, 1                  # encoding: [0x01,0x00,0x0c,0x3c]
# CHECK: ori	$12, $12, 34464         # encoding: [0xa0,0x86,0x8c,0x35]
# CHECK: lui	$12, 15                 # encoding: [0x0f,0x00,0x0c,0x3c]
# CHECK: ori	$12, $12, 16960         # encoding: [0x40,0x42,0x8c,0x35]
# CHECK: lui	$12, 152                # encoding: [0x98,0x00,0x0c,0x3c]
# CHECK: ori	$12, $12, 38528         # encoding: [0x80,0x96,0x8c,0x35]
# CHECK: lui	$12, 1525               # encoding: [0xf5,0x05,0x0c,0x3c]
# CHECK: ori	$12, $12, 57600         # encoding: [0x00,0xe1,0x8c,0x35]
# CHECK: lui	$12, 15258              # encoding: [0x9a,0x3b,0x0c,0x3c]
# CHECK: ori	$12, $12, 51712         # encoding: [0x00,0xca,0x8c,0x35]
# CHECK: lui	$12, 2                  # encoding: [0x02,0x00,0x0c,0x3c]
# CHECK: ori	$12, $12, 21515         # encoding: [0x0b,0x54,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 58368         # encoding: [0x00,0xe4,0x8c,0x35]
# CHECK: lui	$12, 23                 # encoding: [0x17,0x00,0x0c,0x3c]
# CHECK: ori	$12, $12, 18550         # encoding: [0x76,0x48,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 59392         # encoding: [0x00,0xe8,0x8c,0x35]
# CHECK: lui	$12, 232                # encoding: [0xe8,0x00,0x0c,0x3c]
# CHECK: ori	$12, $12, 54437         # encoding: [0xa5,0xd4,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 4096          # encoding: [0x00,0x10,0x8c,0x35]
# CHECK: lui	$12, 2328               # encoding: [0x18,0x09,0x0c,0x3c]
# CHECK: ori	$12, $12, 20082         # encoding: [0x72,0x4e,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 40960         # encoding: [0x00,0xa0,0x8c,0x35]
# CHECK: lui	$12, 23283              # encoding: [0xf3,0x5a,0x0c,0x3c]
# CHECK: ori	$12, $12, 4218          # encoding: [0x7a,0x10,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 16384         # encoding: [0x00,0x40,0x8c,0x35]
# CHECK: lui	$12, 3                  # encoding: [0x03,0x00,0x0c,0x3c]
# CHECK: ori	$12, $12, 36222         # encoding: [0x7e,0x8d,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 42182         # encoding: [0xc6,0xa4,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 32768         # encoding: [0x00,0x80,0x8c,0x35]
# CHECK: lui	$12, 35                 # encoding: [0x23,0x00,0x0c,0x3c]
# CHECK: ori	$12, $12, 34546         # encoding: [0xf2,0x86,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 28609         # encoding: [0xc1,0x6f,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 0             # encoding: [0x00,0x00,0x8c,0x35]
# CHECK: lui	$12, 355                # encoding: [0x63,0x01,0x0c,0x3c]
# CHECK: ori	$12, $12, 17784         # encoding: [0x78,0x45,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 23946         # encoding: [0x8a,0x5d,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 0             # encoding: [0x00,0x00,0x8c,0x35]
# CHECK: lui	$12, 3552               # encoding: [0xe0,0x0d,0x0c,0x3c]
# CHECK: ori	$12, $12, 46771         # encoding: [0xb3,0xb6,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 42852         # encoding: [0x64,0xa7,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 0             # encoding: [0x00,0x00,0x8c,0x35]
# CHECK: lui	$12, 35527              # encoding: [0xc7,0x8a,0x0c,0x3c]
# CHECK: ori	$12, $12, 8964          # encoding: [0x04,0x23,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 35304         # encoding: [0xe8,0x89,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 0             # encoding: [0x00,0x00,0x8c,0x35]
# CHECK: addiu	$12, $zero, -1          # encoding: [0xff,0xff,0x0c,0x24]
# CHECK: addiu	$12, $zero, -10         # encoding: [0xf6,0xff,0x0c,0x24]
# CHECK: addiu	$12, $zero, -100        # encoding: [0x9c,0xff,0x0c,0x24]
# CHECK: addiu	$12, $zero, -1000       # encoding: [0x18,0xfc,0x0c,0x24]
# CHECK: addiu	$12, $zero, -10000      # encoding: [0xf0,0xd8,0x0c,0x24]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 65535         # encoding: [0xff,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 65534         # encoding: [0xfe,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 31072         # encoding: [0x60,0x79,0x8c,0x35]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 65535         # encoding: [0xff,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 65520         # encoding: [0xf0,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 48576         # encoding: [0xc0,0xbd,0x8c,0x35]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 65535         # encoding: [0xff,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 65383         # encoding: [0x67,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 27008         # encoding: [0x80,0x69,0x8c,0x35]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 65535         # encoding: [0xff,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 64010         # encoding: [0x0a,0xfa,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 7936          # encoding: [0x00,0x1f,0x8c,0x35]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 65535         # encoding: [0xff,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 50277         # encoding: [0x65,0xc4,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 13824         # encoding: [0x00,0x36,0x8c,0x35]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 65533         # encoding: [0xfd,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 44020         # encoding: [0xf4,0xab,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 7168          # encoding: [0x00,0x1c,0x8c,0x35]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 65512         # encoding: [0xe8,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 46985         # encoding: [0x89,0xb7,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 6144          # encoding: [0x00,0x18,0x8c,0x35]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 65303         # encoding: [0x17,0xff,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 11098         # encoding: [0x5a,0x2b,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 61440         # encoding: [0x00,0xf0,0x8c,0x35]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 63207         # encoding: [0xe7,0xf6,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 45453         # encoding: [0x8d,0xb1,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 24576         # encoding: [0x00,0x60,0x8c,0x35]
# CHECK: lui	$12, 65535              # encoding: [0xff,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 42252         # encoding: [0x0c,0xa5,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 61317         # encoding: [0x85,0xef,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 49152         # encoding: [0x00,0xc0,0x8c,0x35]
# CHECK: lui	$12, 65532              # encoding: [0xfc,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 29313         # encoding: [0x81,0x72,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 23353         # encoding: [0x39,0x5b,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 32768         # encoding: [0x00,0x80,0x8c,0x35]
# CHECK: lui	$12, 65500              # encoding: [0xdc,0xff,0x0c,0x3c]
# CHECK: ori	$12, $12, 30989         # encoding: [0x0d,0x79,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 36927         # encoding: [0x3f,0x90,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 0             # encoding: [0x00,0x00,0x8c,0x35]
# CHECK: lui	$12, 65180              # encoding: [0x9c,0xfe,0x0c,0x3c]
# CHECK: ori	$12, $12, 47751         # encoding: [0x87,0xba,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 41590         # encoding: [0x76,0xa2,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 0             # encoding: [0x00,0x00,0x8c,0x35]
# CHECK: lui	$12, 61983              # encoding: [0x1f,0xf2,0x0c,0x3c]
# CHECK: ori	$12, $12, 18764         # encoding: [0x4c,0x49,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 22684         # encoding: [0x9c,0x58,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 0             # encoding: [0x00,0x00,0x8c,0x35]
# CHECK: lui	$12, 30008              # encoding: [0x38,0x75,0x0c,0x3c]
# CHECK: ori	$12, $12, 56571         # encoding: [0xfb,0xdc,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 30232         # encoding: [0x18,0x76,0x8c,0x35]
# CHECK: dsll	$12, $12, 16            # encoding: [0x38,0x64,0x0c,0x00]
# CHECK: ori	$12, $12, 0             # encoding: [0x00,0x00,0x8c,0x35]

	dla	$t0, symbol
.set noat
	dla	$t0, symbol
.set at

	dli	$t0, 1
	dli	$t0, 10
	dli	$t0, 100
	dli	$t0, 1000
	dli	$t0, 10000
	dli	$t0, 100000
	dli	$t0, 1000000
	dli	$t0, 10000000
	dli	$t0, 100000000
	dli	$t0, 1000000000
	dli	$t0, 10000000000
	dli	$t0, 100000000000
	dli	$t0, 1000000000000
	dli	$t0, 10000000000000
	dli	$t0, 100000000000000
	dli	$t0, 1000000000000000
	dli	$t0, 10000000000000000
	dli	$t0, 100000000000000000
	dli	$t0, 1000000000000000000
	dli	$t0, 10000000000000000000
	dli	$t0, -1
	dli	$t0, -10
	dli	$t0, -100
	dli	$t0, -1000
	dli	$t0, -10000
	dli	$t0, -100000
	dli	$t0, -1000000
	dli	$t0, -10000000
	dli	$t0, -100000000
	dli	$t0, -1000000000
	dli	$t0, -10000000000
	dli	$t0, -100000000000
	dli	$t0, -1000000000000
	dli	$t0, -10000000000000
	dli	$t0, -100000000000000
	dli	$t0, -1000000000000000
	dli	$t0, -10000000000000000
	dli	$t0, -100000000000000000
	dli	$t0, -1000000000000000000
	dli	$t0, -10000000000000000000
